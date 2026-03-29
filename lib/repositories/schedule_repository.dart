import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/subject_performance_model.dart';
import '../models/subject_schedule_entry_model.dart';
import '../models/semester_achievement_record_model.dart';



// ─── Cache Key Suffixes ───────────────────────────────────────────────────────

const String _kScheduleData      = 'schedule_data';
const String _kScheduleTs        = 'schedule_ts';
const String _kPerfPrefix        = 'perf_';
const String _kPerfTsPrefix      = 'perf_ts_';
const String _kSemesterRecords   = 'semester_records';
const String _kSemesterRecordsTs = 'semester_records_ts';
const Duration _kCacheTtl        = Duration(hours: 24);

// ─── ScheduleRepository ──────────────────────────────────────────────────────

class ScheduleRepository {
  ScheduleRepository({
    required FirebaseFirestore firestore,
    required SharedPreferences prefs,
    required String Function() getUserId,
  })  : _firestore = firestore,
        _prefs = prefs,
        _getUserId = getUserId;

  final FirebaseFirestore _firestore;
  final SharedPreferences _prefs;
  final String Function() _getUserId;

  // ── userId resolution ───────────────────────────────────────────────────────

  String get _userId {
    final id = _getUserId();
    if (id.isEmpty) {
      throw StateError(
          '[ScheduleRepository] userId is empty — user is not signed in.');
    }
    return id;
  }

  // ── Per-user cache key helpers ──────────────────────────────────────────────

  String _cacheScheduleData(String uid)  => '${uid}_$_kScheduleData';
  String _cacheScheduleTs(String uid)    => '${uid}_$_kScheduleTs';
  String _cachePerfKey(String uid, String subjectId) =>
      '${uid}_$_kPerfPrefix$subjectId';
  String _cachePerfTsKey(String uid, String subjectId) =>
      '${uid}_$_kPerfTsPrefix$subjectId';
  String _cacheSemesterRecords(String uid)   => '${uid}_$_kSemesterRecords';
  String _cacheSemesterRecordsTs(String uid) => '${uid}_$_kSemesterRecordsTs';

  // ── Firestore refs ──────────────────────────────────────────────────────────

  DocumentReference<Map<String, dynamic>> get _scheduleDoc =>
      _firestore.doc('users/$_userId/schedule/current');

  CollectionReference<Map<String, dynamic>> get _perfCollection =>
      _firestore.collection('users/$_userId/subject_performance');

  CollectionReference<Map<String, dynamic>> get _semesterRecordsCollection =>
      _firestore.collection('users/$_userId/semester_records');

  // ══════════════════════════════════════════════════════════════════════════
  //  Schedule Grid
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> saveSchedule(List<SubjectScheduleEntry> entries) async {
    final uid = _userId;
    final encoded = jsonEncode(entries.map((e) => e.toJson()).toList());
    await _prefs.setString(_cacheScheduleData(uid), encoded);
    await _prefs.setInt(
        _cacheScheduleTs(uid), DateTime.now().millisecondsSinceEpoch);

    try {
      await _scheduleDoc
          .set({'entries': entries.map((e) => e.toJson()).toList()});
    } catch (e) {
      debugPrint('[ScheduleRepository] saveSchedule Firestore error: $e');
      rethrow;
    }
  }

  Future<void> clearSchedule() async {
    final uid = _userId;
    await _prefs.remove(_cacheScheduleData(uid));
    await _prefs.remove(_cacheScheduleTs(uid));

    try {
      await _scheduleDoc.set({'entries': []});
    } catch (e) {
      debugPrint('[ScheduleRepository] clearSchedule Firestore error: $e');
      rethrow;
    }
  }

  Future<List<SubjectScheduleEntry>> loadSchedule() async {
    final uid = _userId;
    try {
      final snap = await _scheduleDoc.get();
      if (snap.exists && snap.data() != null) {
        final entries = _parseScheduleEntries(snap.data()!);
        await _prefs.setString(
            _cacheScheduleData(uid),
            jsonEncode(entries.map((e) => e.toJson()).toList()));
        await _prefs.setInt(
            _cacheScheduleTs(uid), DateTime.now().millisecondsSinceEpoch);
        return entries;
      }
    } catch (e) {
      debugPrint('[ScheduleRepository] loadSchedule Firebase error: $e');
    }
    return _loadScheduleFromCache(uid);
  }

  Stream<List<SubjectScheduleEntry>> watchSchedule() {
    final uid = _userId;
    late StreamSubscription<DocumentSnapshot<Map<String, dynamic>>> firestoreSub;
    final controller = StreamController<List<SubjectScheduleEntry>>(
      onCancel: () => firestoreSub.cancel(),
    );

    // إرسال cache كـ snapshot أولي مع حماية من الاستثناءات
    Future<void>(() {
      try {
        final cached = _loadScheduleFromCache(uid);
        if (!controller.isClosed) controller.add(cached);
      } catch (_) {
        if (!controller.isClosed) controller.add([]);
      }
    });

    firestoreSub = _scheduleDoc.snapshots().listen(
      (snap) {
        if (snap.exists && snap.data() != null) {
          final entries = _parseScheduleEntries(snap.data()!);
          _prefs.setString(
              _cacheScheduleData(uid),
              jsonEncode(entries.map((e) => e.toJson()).toList()));
          _prefs.setInt(
              _cacheScheduleTs(uid), DateTime.now().millisecondsSinceEpoch);
          if (!controller.isClosed) controller.add(entries);
        }
      },
      onError: (Object e) {
        debugPrint('[ScheduleRepository] watchSchedule error: $e');
      },
    );

    return controller.stream;
  }

  List<SubjectScheduleEntry> _parseScheduleEntries(
      Map<String, dynamic> data) {
    final raw = data['entries'] as List<dynamic>? ?? [];
    return raw
        .map((e) => SubjectScheduleEntry.fromJson(
            Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  List<SubjectScheduleEntry> _loadScheduleFromCache(String uid) {
    final raw = _prefs.getString(_cacheScheduleData(uid));
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => SubjectScheduleEntry.fromJson(
              Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  SubjectPerformance CRUD
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> savePerformance(SubjectPerformance perf) async {
    final uid = _userId;
    await _writePerfToCache(perf, uid);

    try {
      await _perfCollection.doc(perf.subjectId).set(perf.toJson());
    } catch (e) {
      debugPrint('[ScheduleRepository] savePerformance Firestore error: $e');
      rethrow;
    }
  }

  Future<SubjectPerformance?> getPerformance(String subjectId) async {
    final uid = _userId;
    try {
      final snap = await _perfCollection.doc(subjectId).get();
      if (snap.exists && snap.data() != null) {
        final perf = SubjectPerformance.fromJson(snap.data()!);
        await _writePerfToCache(perf, uid);
        return perf;
      }
    } catch (e) {
      debugPrint('[ScheduleRepository] getPerformance Firebase error: $e');
    }
    return _loadPerfFromCache(subjectId, uid);
  }

  Future<List<SubjectPerformance>> getAllPerformances() async {
    final uid = _userId;
    try {
      final snap = await _perfCollection.get();
      final perfs = snap.docs
          .where((d) => d.data().isNotEmpty)
          .map((d) {
            try {
              return SubjectPerformance.fromJson(d.data());
            } catch (_) {
              return null;
            }
          })
          .whereType<SubjectPerformance>()
          .toList();

      // parallel بدل sequential — 8 مواد = 8 عمليات في وقت واحد بدل الواحدة تلو الأخرى
      await Future.wait(perfs.map((p) => _writePerfToCache(p, uid)));
      return perfs;
    } catch (e) {
      debugPrint('[ScheduleRepository] getAllPerformances error: $e');
      return _loadAllPerfsFromCache(uid);
    }
  }

  Stream<List<SubjectPerformance>> watchAllPerformances() {
    final uid = _userId;
    late StreamSubscription<QuerySnapshot<Map<String, dynamic>>> firestoreSub;
    final controller = StreamController<List<SubjectPerformance>>(
      onCancel: () => firestoreSub.cancel(),
    );

    Future<void>(() {
      try {
        final cached = _loadAllPerfsFromCache(uid);
        if (!controller.isClosed) controller.add(cached);
      } catch (_) {
        if (!controller.isClosed) controller.add([]);
      }
    });

    firestoreSub = _perfCollection.snapshots().listen(
      (snap) {
        final perfs = snap.docs
            .where((d) => d.data().isNotEmpty)
            .map((d) {
              try {
                return SubjectPerformance.fromJson(d.data());
              } catch (_) {
                return null;
              }
            })
            .whereType<SubjectPerformance>()
            .toList();

        for (final p in perfs) {
          _writePerfToCache(p, uid);
        }
        if (!controller.isClosed) controller.add(perfs);
      },
      onError: (Object e) {
        debugPrint('[ScheduleRepository] watchAllPerformances error: $e');
      },
    );

    return controller.stream;
  }

  Future<void> deletePerformance(String subjectId) async {
    final uid = _userId;

    // مسح الـ cache أولاً
    await _prefs.remove(_cachePerfKey(uid, subjectId));
    await _prefs.remove(_cachePerfTsKey(uid, subjectId));

    try {
      await _perfCollection.doc(subjectId).delete();
    } catch (e) {
      debugPrint('[ScheduleRepository] deletePerformance error: $e');
      rethrow;
    }
  }

  Future<void> clearAllPerformances() async {
    final uid = _userId;

    final prefix   = '${uid}_$_kPerfPrefix';
    final tsPrefix = '${uid}_$_kPerfTsPrefix';
    final keysToRemove = _prefs
        .getKeys()
        .where((k) => k.startsWith(prefix) || k.startsWith(tsPrefix))
        .toList();
    for (final key in keysToRemove) {
      await _prefs.remove(key);
    }

    try {
      final snap = await _perfCollection.get();
      const batchLimit = 499;
      final docs = snap.docs;

      final futures = <Future<void>>[];
      for (var i = 0; i < docs.length; i += batchLimit) {
        final batch = _firestore.batch();
        for (final doc in docs.skip(i).take(batchLimit)) {
          batch.delete(doc.reference);
        }
        futures.add(batch.commit());
      }
      await Future.wait(futures, eagerError: false);
    } catch (e) {
      debugPrint('[ScheduleRepository] clearAllPerformances error: $e');
      rethrow;
    }
  }

  // ── Performance cache helpers ───────────────────────────────────────────────

  Future<void> _writePerfToCache(SubjectPerformance perf, String uid) async {
    await _prefs.setString(
        _cachePerfKey(uid, perf.subjectId),
        jsonEncode(perf.toJsonForCache()));
    await _prefs.setInt(
        _cachePerfTsKey(uid, perf.subjectId),
        DateTime.now().millisecondsSinceEpoch);
  }

  SubjectPerformance? _loadPerfFromCache(String subjectId, String uid) {
    final raw = _prefs.getString(_cachePerfKey(uid, subjectId));
    if (raw == null) return null;

    final tsMs = _prefs.getInt(_cachePerfTsKey(uid, subjectId)) ?? 0;
    if (_isCacheExpired(tsMs)) return null;

    try {
      return SubjectPerformance.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (_) {
      return null;
    }
  }

  List<SubjectPerformance> _loadAllPerfsFromCache(String uid) {
    final prefix   = '${uid}_$_kPerfPrefix';
    final tsPrefix = '${uid}_$_kPerfTsPrefix';
    final perfs    = <SubjectPerformance>[];

    for (final key in _prefs.getKeys()) {
      if (!key.startsWith(prefix) || key.startsWith(tsPrefix)) continue;
      final subjectId = key.substring(prefix.length);
      final perf = _loadPerfFromCache(subjectId, uid);
      if (perf != null) perfs.add(perf);
    }
    return perfs;
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  SemesterAchievementRecord — أرشيف الفصول المنتهية
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> saveSemesterRecord(SemesterAchievementRecord record) async {
    final uid = _userId;

    final existingCached = _loadSemesterRecordsFromCache(uid);
    final updated = [
      ...existingCached.where((r) => r.id != record.id),
      record,
    ]..sort((a, b) => b.archivedAt.compareTo(a.archivedAt));

    await _prefs.setString(
        _cacheSemesterRecords(uid),
        jsonEncode(updated.map((r) => r.toJson()).toList()));
    await _prefs.setInt(
        _cacheSemesterRecordsTs(uid), DateTime.now().millisecondsSinceEpoch);

    try {
      await _semesterRecordsCollection
          .doc(record.id)
          .set(record.toJson());
    } catch (e) {
      debugPrint('[ScheduleRepository] saveSemesterRecord Firestore error: $e');
      rethrow;
    }
  }

  Future<List<SemesterAchievementRecord>> getAllSemesterRecords() async {
    final uid = _userId;

    try {
      final snap = await _semesterRecordsCollection
          .orderBy('archivedAt', descending: true)
          .get();

      if (snap.docs.isNotEmpty) {
        final records = snap.docs
            .map((d) {
              try {
                return SemesterAchievementRecord.fromJson(d.data());
              } catch (_) {
                return null;
              }
            })
            .whereType<SemesterAchievementRecord>()
            .toList();

        await _prefs.setString(
            _cacheSemesterRecords(uid),
            jsonEncode(records.map((r) => r.toJson()).toList()));
        await _prefs.setInt(
            _cacheSemesterRecordsTs(uid),
            DateTime.now().millisecondsSinceEpoch);

        return records;
      }
    } catch (e) {
      debugPrint('[ScheduleRepository] getAllSemesterRecords Firebase error: $e');
    }

    return _loadSemesterRecordsFromCache(uid);
  }

  Stream<List<SemesterAchievementRecord>> watchSemesterRecords() {
    final uid = _userId;
    late StreamSubscription firestoreSub;
    final controller = StreamController<List<SemesterAchievementRecord>>(
      onCancel: () => firestoreSub.cancel(),
    );

    Future<void>(() {
      try {
        final cached = _loadSemesterRecordsFromCache(uid);
        if (!controller.isClosed) controller.add(cached);
      } catch (_) {
        if (!controller.isClosed) controller.add([]);
      }
    });

    firestoreSub = _semesterRecordsCollection
        .orderBy('archivedAt', descending: true)
        .snapshots()
        .listen(
      (snap) {
        final records = snap.docs
            .map((d) {
              try {
                return SemesterAchievementRecord.fromJson(d.data());
              } catch (_) {
                return null;
              }
            })
            .whereType<SemesterAchievementRecord>()
            .toList();

        _prefs.setString(
            _cacheSemesterRecords(uid),
            jsonEncode(records.map((r) => r.toJson()).toList()));
        _prefs.setInt(
            _cacheSemesterRecordsTs(uid),
            DateTime.now().millisecondsSinceEpoch);

        if (!controller.isClosed) controller.add(records);
      },
      onError: (Object e) {
        debugPrint('[ScheduleRepository] watchSemesterRecords error: $e');
      },
    );

    return controller.stream;
  }

  List<SemesterAchievementRecord> _loadSemesterRecordsFromCache(String uid) {
    final raw = _prefs.getString(_cacheSemesterRecords(uid));
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => SemesterAchievementRecord.fromJson(
              Map<String, dynamic>.from(e as Map)))
          .whereType<SemesterAchievementRecord>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Shared helpers ──────────────────────────────────────────────────────────

  bool _isCacheExpired(int timestampMs) {
    if (timestampMs == 0) return true;
    final age = DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(timestampMs));
    return age > _kCacheTtl;
  }
}