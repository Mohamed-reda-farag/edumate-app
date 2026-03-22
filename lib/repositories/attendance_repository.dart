import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/attendance_record_model.dart';
import '../models/gamification_model.dart';
import '../models/study_session_model.dart';

// ─── Cache Key Suffixes ───────────────────────────────────────────────────────

const String _kAttPrefix         = 'att_';
const String _kAttTsPrefix       = 'att_ts_';
const String _kSessionsToday     = 'sessions_today';
const String _kSessionsTodayTs   = 'sessions_today_ts';
const String _kSessionsTodayDate = 'sessions_today_date';
const String _kGamification      = 'gamification';
const Duration _kCacheTtl        = Duration(hours: 24);

// ─── AttendanceRepository ─────────────────────────────────────────────────────

class AttendanceRepository {
  AttendanceRepository({
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
          '[AttendanceRepository] userId is empty — user is not signed in.');
    }
    return id;
  }

  // ── Per-user cache key helpers ──────────────────────────────────────────────

  String _cacheAttKey(String uid, String subjectId)    => '${uid}_$_kAttPrefix$subjectId';
  String _cacheAttTsKey(String uid, String subjectId)  => '${uid}_$_kAttTsPrefix$subjectId';
  String _cacheSessionsToday(String uid)               => '${uid}_$_kSessionsToday';
  String _cacheSessionsTodayTs(String uid)             => '${uid}_$_kSessionsTodayTs';
  String _cacheSessionsTodayDate(String uid)           => '${uid}_$_kSessionsTodayDate';
  String _cacheGamification(String uid)                => '${uid}_$_kGamification';

  // ── Firestore refs ──────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _attCollection =>
      _firestore.collection('users/$_userId/attendance');

  CollectionReference<Map<String, dynamic>> get _sessionsCollection =>
      _firestore.collection('users/$_userId/study_sessions');

  DocumentReference<Map<String, dynamic>> get _gamificationDoc =>
      _firestore.doc('users/$_userId/gamification/data');

  // ── Week calculation helper ─────────────────────────────────────────────────
  //
  // تعريف الأسبوع: السبت (6) → الجمعة (5)
  //   السبت (6)  → 0 أيام للخلف
  //   الأحد (7)  → 1 يوم للخلف
  //   الاثنين(1) → 2 أيام للخلف
  //   الثلاثاء(2)→ 3 أيام للخلف
  //   الأربعاء(3)→ 4 أيام للخلف
  //   الخميس (4) → 5 أيام للخلف
  //   الجمعة (5) → 6 أيام للخلف
  static DateTime _currentWeekStart() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysSinceSaturday = switch (today.weekday) {
      6 => 0,
      7 => 1,
      _ => today.weekday + 1,
    };
    return today.subtract(Duration(days: daysSinceSaturday));
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  AttendanceRecord CRUD
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> addRecord(AttendanceRecord record) async {
    final uid = _userId;
    try {
      await _upsertRecordInCache(record, uid);
      await _attCollection.doc(record.id).set(record.toJson());
    } catch (e) {
      debugPrint('[AttendanceRepository] addRecord error: $e');
      rethrow;
    }
  }

  Future<void> updateRecord(AttendanceRecord record) async {
    final uid = _userId;
    try {
      await _upsertRecordInCache(record, uid);
      await _attCollection.doc(record.id).update(record.toJson());
    } catch (e) {
      debugPrint('[AttendanceRepository] updateRecord error: $e');
      rethrow;
    }
  }

  Future<void> deleteRecord(String id) async {
    final uid = _userId;
    try {
      await _attCollection.doc(id).delete();
      await _removeRecordFromCache(id, uid);
    } catch (e) {
      debugPrint('[AttendanceRepository] deleteRecord error: $e');
      rethrow;
    }
  }

  Future<List<AttendanceRecord>> getRecordsBySubject(String subjectId) async {
    final uid = _userId;
    try {
      final snap = await _attCollection
          .where('subjectId', isEqualTo: subjectId)
          .orderBy('date', descending: true)
          .get();

      final records = _parseAttendanceSnap(snap.docs);
      await _writeRecordsToCache(subjectId, records, uid);
      return records;
    } catch (e) {
      debugPrint('[AttendanceRepository] getRecordsBySubject error: $e');
      return _loadRecordsFromCache(subjectId, uid);
    }
  }
  Stream<List<AttendanceRecord>> watchRecordsBySubject(String subjectId) {
    final uid = _userId;

    late StreamSubscription<QuerySnapshot<Map<String, dynamic>>> firestoreSub;
    final controller = StreamController<List<AttendanceRecord>>(
      onCancel: () => firestoreSub.cancel(),
    );

    // إرسال cache كـ snapshot أولي فوري (تجربة المستخدم أسرع)
    Future<void>(() {
      try {
        final cached = _loadRecordsFromCache(subjectId, uid);
        if (!controller.isClosed) controller.add(cached);
      } catch (_) {
        if (!controller.isClosed) controller.add([]);
      }
    });

    firestoreSub = _attCollection
        .where('subjectId', isEqualTo: subjectId)
        .orderBy('date', descending: true)
        .snapshots()
        .listen(
      (snap) {
        final records = _parseAttendanceSnap(snap.docs);
        _writeRecordsToCache(subjectId, records, uid);
        if (!controller.isClosed) controller.add(records);
      },
      onError: (Object e) {
        debugPrint('[AttendanceRepository] watchRecordsBySubject error: $e');
      },
    );

    return controller.stream;
  }

  // ── Attendance cache helpers ────────────────────────────────────────────────

  Future<void> _writeRecordsToCache(
      String subjectId, List<AttendanceRecord> records, String uid) async {
    await _prefs.setString(
        _cacheAttKey(uid, subjectId),
        jsonEncode(records.map((r) => r.toJson()).toList()));
    await _prefs.setInt(
        _cacheAttTsKey(uid, subjectId),
        DateTime.now().millisecondsSinceEpoch);
  }

  List<AttendanceRecord> _loadRecordsFromCache(String subjectId, String uid) {
    final raw = _prefs.getString(_cacheAttKey(uid, subjectId));
    if (raw == null) return [];
    final tsMs = _prefs.getInt(_cacheAttTsKey(uid, subjectId)) ?? 0;
    if (_isCacheExpired(tsMs)) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => _decodeAttendanceRecord(e as Map))
          .whereType<AttendanceRecord>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _upsertRecordInCache(AttendanceRecord record, String uid) async {
    final existing = _loadRecordsFromCache(record.subjectId, uid);
    final updated  = [record, ...existing.where((r) => r.id != record.id)];
    await _writeRecordsToCache(record.subjectId, updated, uid);
  }

  Future<void> _removeRecordFromCache(String recordId, String uid) async {
    final attPrefix   = '${uid}_$_kAttPrefix';
    final attTsPrefix = '${uid}_$_kAttTsPrefix';

    for (final key in _prefs.getKeys()) {
      if (!key.startsWith(attPrefix) || key.startsWith(attTsPrefix)) continue;
      final subjectId = key.substring(attPrefix.length);
      final records   = _loadRecordsFromCache(subjectId, uid);
      final filtered  = records.where((r) => r.id != recordId).toList();
      if (filtered.length != records.length) {
        await _writeRecordsToCache(subjectId, filtered, uid);
      }
    }
  }

  List<AttendanceRecord> _parseAttendanceSnap(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    return docs
        .map((d) => _decodeAttendanceRecord(d.data()))
        .whereType<AttendanceRecord>()
        .toList();
  }

  AttendanceRecord? _decodeAttendanceRecord(Map<dynamic, dynamic> raw) {
    try {
      return AttendanceRecord.fromJson(Map<String, dynamic>.from(raw));
    } catch (e) {
      debugPrint('[AttendanceRepository] decode AttendanceRecord error: $e');
      return null;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  StudySession CRUD
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> clearWeekSessions() async {
    final weekStart = _currentWeekStart();
    final weekEnd = weekStart.add(const Duration(days: 7));

    try {
      final snap = await _sessionsCollection
          .where('scheduledDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
          .where('scheduledDate', isLessThan: Timestamp.fromDate(weekEnd))
          .get();

      const int batchLimit = 499;
      final docs = snap.docs;

      // جمع كل الـ batches وتنفيذها معاً
      final futures = <Future<void>>[];
      for (var i = 0; i < docs.length; i += batchLimit) {
        final batch = _firestore.batch();
        for (final doc in docs.skip(i).take(batchLimit)) {
          batch.delete(doc.reference);
        }
        futures.add(batch.commit());
      }
      // مسح الـ cache فقط بعد نجاح كل الـ batches
      await Future.wait(futures);

      final uid = _userId;
      await _prefs.remove(_cacheSessionsToday(uid));
      await _prefs.remove(_cacheSessionsTodayTs(uid));
      await _prefs.remove(_cacheSessionsTodayDate(uid));
    } catch (e) {
      debugPrint('[AttendanceRepository] clearWeekSessions error: $e');
      rethrow;
    }
  }

  Future<void> saveSessions(List<StudySession> sessions) async {
    final uid = _userId;
    if (sessions.isEmpty) return;

    try {
      final todaySessions = sessions
          .where((s) => _isSameDay(s.scheduledDate, DateTime.now()))
          .toList();
      if (todaySessions.isNotEmpty) {
        await _writeTodaySessionsToCache(todaySessions, uid);
      }

      const int batchLimit = 499;
      for (var i = 0; i < sessions.length; i += batchLimit) {
        final chunk = sessions.skip(i).take(batchLimit).toList();
        final batch = _firestore.batch();
        for (final session in chunk) {
          batch.set(_sessionsCollection.doc(session.id), session.toJson());
        }
        await batch.commit();
      }
    } catch (e) {
      debugPrint('[AttendanceRepository] saveSessions error: $e');
      rethrow;
    }
  }

  Future<List<StudySession>> getSessionsByDate(DateTime date) async {
    final uid = _userId;

    if (_isSameDay(date, DateTime.now())) {
      final cached = _loadTodaySessionsFromCache(uid);
      if (cached != null) return cached;
    }

    try {
      final start = DateTime(date.year, date.month, date.day);
      final end   = start.add(const Duration(days: 1));

      final snap = await _sessionsCollection
          .where('scheduledDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('scheduledDate', isLessThan: Timestamp.fromDate(end))
          .get();

      final sessions = _parseSessionsSnap(snap.docs);

      if (_isSameDay(date, DateTime.now())) {
        await _writeTodaySessionsToCache(sessions, uid);
      }

      return sessions;
    } catch (e) {
      debugPrint('[AttendanceRepository] getSessionsByDate error: $e');
      if (_isSameDay(date, DateTime.now())) {
        return _loadTodaySessionsFromCache(uid) ?? [];
      }
      return [];
    }
  }

  Future<List<StudySession>> getWeekSessions() async {
    final weekStart = _currentWeekStart();
    final weekEnd = weekStart.add(const Duration(days: 7));

    try {
      final snap = await _sessionsCollection
          .where('scheduledDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
          .where('scheduledDate', isLessThan: Timestamp.fromDate(weekEnd))
          .get();

      return _parseSessionsSnap(snap.docs)
        ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
    } catch (e) {
      debugPrint('[AttendanceRepository] getWeekSessions error: $e');
      return [];
    }
  }

  Future<void> updateSessionStatus(
    String id,
    SessionStatus status, {
    double? completionRate,
    String? notes,
  }) async {
    final uid = _userId;
    try {
      final updates = <String, dynamic>{
        'status': status.name,
        if (completionRate != null) 'completionRate': completionRate,
        if (notes != null) 'notes': notes,
      };

      await _sessionsCollection.doc(id).update(updates);

      final cached = _loadTodaySessionsFromCache(uid);
      if (cached != null) {
        final patched = cached.map((s) {
          if (s.id != id) return s;
          return s.copyWith(
            status: status,
            completionRate: completionRate ?? s.completionRate,
            notes: notes ?? s.notes,
          );
        }).toList();
        await _writeTodaySessionsToCache(patched, uid);
      }
    } catch (e) {
      debugPrint('[AttendanceRepository] updateSessionStatus error: $e');
      rethrow;
    }
  }

  Future<void> deleteSessionsBySubject(String subjectId) async {
    try {
      final snap = await _sessionsCollection
          .where('subjectId', isEqualTo: subjectId)
          .get();

      if (snap.docs.isEmpty) return;

      const int batchLimit = 499;
      final docs = snap.docs;
      for (var i = 0; i < docs.length; i += batchLimit) {
        final batch = _firestore.batch();
        for (final doc in docs.skip(i).take(batchLimit)) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }

      // تحديث الـ cache: مسح جلسات اليوم التي تخص هذه المادة
      final uid = _userId;
      final cached = _loadTodaySessionsFromCache(uid);
      if (cached != null) {
        final filtered = cached
            .where((s) => s.subjectId != subjectId)
            .toList();
        await _writeTodaySessionsToCache(filtered, uid);
      }
    } catch (e) {
      debugPrint('[AttendanceRepository] deleteSessionsBySubject error: $e');
      rethrow;
    }
  }

  Stream<List<StudySession>> watchTodaySessions() {
    final uid        = _userId;
    final now        = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrow   = todayStart.add(const Duration(days: 1));

    late StreamSubscription firestoreSub;
    final controller = StreamController<List<StudySession>>(
      onCancel: () => firestoreSub.cancel(),
    );

    Future<void>(() {
      if (!controller.isClosed) {
        controller.add(_loadTodaySessionsFromCache(uid) ?? []);
      }
    });

    firestoreSub = _sessionsCollection
        .where('scheduledDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
        .where('scheduledDate', isLessThan: Timestamp.fromDate(tomorrow))
        .snapshots()
        .listen(
      (snap) {
        final today = DateTime.now();
        final sessions = _parseSessionsSnap(snap.docs)
            .where((s) => _isSameDay(s.scheduledDate, today))
            .toList();
        _writeTodaySessionsToCache(sessions, uid);
        if (!controller.isClosed) controller.add(sessions);
      },
      onError: (Object e) {
        debugPrint('[AttendanceRepository] watchTodaySessions error: $e');
      },
    );

    return controller.stream;
  }

  Stream<List<StudySession>> watchWeekSessions() {
    final uid = _userId;
    final weekStart = _currentWeekStart();
    final weekEnd = weekStart.add(const Duration(days: 7));

    late StreamSubscription firestoreSub;
    final controller = StreamController<List<StudySession>>(
      onCancel: () => firestoreSub.cancel(),
    );

    firestoreSub = _firestore
        .collection('users/$uid/study_sessions')
        .where('scheduledDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
        .where('scheduledDate', isLessThan: Timestamp.fromDate(weekEnd))
        .snapshots()
        .listen(
      (snap) {
        final sessions = snap.docs
            .map((d) {
              try {
                return StudySession.fromJson(d.data());
              } catch (_) {
                return null;
              }
            })
            .whereType<StudySession>()
            .toList()
          ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
        if (!controller.isClosed) {
          controller.add(sessions);
        }
      },
      onError: (Object e) {
        debugPrint('[AttendanceRepository] watchWeekSessions error: $e');
      },
    );

    return controller.stream;
  }

  // ── Sessions cache helpers ──────────────────────────────────────────────────

  Future<void> _writeTodaySessionsToCache(
      List<StudySession> sessions, String uid) async {
    final now = DateTime.now();
    await _prefs.setString(
        _cacheSessionsToday(uid),
        jsonEncode(sessions.map((s) => s.toJsonForCache()).toList())); // ← toJsonForCache
    await _prefs.setInt(_cacheSessionsTodayTs(uid), now.millisecondsSinceEpoch);
    await _prefs.setString(_cacheSessionsTodayDate(uid), _dateKey(now));
  }

  List<StudySession>? _loadTodaySessionsFromCache(String uid) {
    final cachedDate = _prefs.getString(_cacheSessionsTodayDate(uid));
    if (cachedDate != _dateKey(DateTime.now())) return null;

    final tsMs = _prefs.getInt(_cacheSessionsTodayTs(uid)) ?? 0;
    if (_isCacheExpired(tsMs)) return null;

    final raw = _prefs.getString(_cacheSessionsToday(uid));
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => _decodeStudySession(e as Map))
          .whereType<StudySession>()
          .toList();
    } catch (_) {
      return null;
    }
  }

  List<StudySession> _parseSessionsSnap(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    return docs
        .map((d) => _decodeStudySession(d.data()))
        .whereType<StudySession>()
        .toList();
  }

  StudySession? _decodeStudySession(Map<dynamic, dynamic> raw) {
    try {
      return StudySession.fromJson(Map<String, dynamic>.from(raw));
    } catch (e) {
      debugPrint('[AttendanceRepository] decode StudySession error: $e');
      return null;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  GamificationData CRUD
  // ══════════════════════════════════════════════════════════════════════════

  Future<GamificationData?> getGamification() async {
    final uid = _userId;
    try {
      final snap = await _gamificationDoc.get();
      if (snap.exists && snap.data() != null) {
        final data = GamificationData.fromJson(snap.data()!);
        await _writeGamificationToCache(data, uid);
        return data;
      }
      return null;
    } catch (e) {
      debugPrint('[AttendanceRepository] getGamification error: $e');
      return _loadGamificationFromCache(uid);
    }
  }

  Future<void> updateGamification(GamificationData data) async {
    final uid = _userId;
    await _writeGamificationToCache(data, uid);
    try {
      await _gamificationDoc.set(data.toJson());
    } catch (e) {
      debugPrint('[AttendanceRepository] updateGamification Firestore error: $e');
      rethrow;
    }
  }

  Stream<GamificationData?> watchGamification() {
    final uid = _userId;

    late StreamSubscription firestoreSub;
    final controller = StreamController<GamificationData?>(
      onCancel: () => firestoreSub.cancel(),
    );

    Future<void>(() {
      if (!controller.isClosed) {
        controller.add(_loadGamificationFromCache(uid));
      }
    });

    firestoreSub = _gamificationDoc.snapshots().listen(
      (snap) {
        if (snap.exists && snap.data() != null) {
          try {
            final data = GamificationData.fromJson(snap.data()!);
            _writeGamificationToCache(data, uid);
            if (!controller.isClosed) controller.add(data);
          } catch (e) {
            debugPrint('[AttendanceRepository] watchGamification parse error: $e');
          }
        } else {
          if (!controller.isClosed) controller.add(null);
        }
      },
      onError: (Object e) {
        debugPrint('[AttendanceRepository] watchGamification error: $e');
      },
    );

    return controller.stream;
  }

  Future<GamificationData?> checkAndResetWeeklyPoints() async {
    final data = await getGamification();
    if (data == null) return null;

    final lastReset = DateTime(
      data.weeklyPointsResetDate.year,
      data.weeklyPointsResetDate.month,
      data.weeklyPointsResetDate.day,
    );

    final currentSaturday = _currentWeekStart();

    if (lastReset.isBefore(currentSaturday)) {
      final reset = data.copyWith(
          weeklyPoints: 0, weeklyPointsResetDate: currentSaturday);
      await updateGamification(reset);
      return reset;
    }
    return data;
  }

  // ── Gamification cache helpers ──────────────────────────────────────────────

  Future<void> _writeGamificationToCache(
      GamificationData data, String uid) async {
    await _prefs.setString(
        _cacheGamification(uid), jsonEncode(data.toJson()));
  }

  GamificationData? _loadGamificationFromCache(String uid) {
    final raw = _prefs.getString(_cacheGamification(uid));
    if (raw == null) return null;
    try {
      return GamificationData.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (e) {
      debugPrint('[AttendanceRepository] loadGamificationFromCache error: $e');
      return null;
    }
  }

  // ── Shared utilities ────────────────────────────────────────────────────────

  bool _isCacheExpired(int timestampMs) {
    if (timestampMs == 0) return true;
    final age = DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(timestampMs));
    return age > _kCacheTtl;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _dateKey(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';
}