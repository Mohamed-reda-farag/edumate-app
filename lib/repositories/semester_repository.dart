import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/academic_semester_model.dart';

const String _kActiveSemester   = 'active_semester';
const String _kActiveSemesterTs = 'active_semester_ts';
const Duration _kCacheTtl       = Duration(hours: 24);

class SemesterRepository {
  SemesterRepository({
    required FirebaseFirestore firestore,
    required SharedPreferences prefs,
    required String Function() getUserId,
  })  : _firestore = firestore,
        _prefs = prefs,
        _getUserId = getUserId;

  final FirebaseFirestore _firestore;
  final SharedPreferences _prefs;
  final String Function() _getUserId;

  String get _userId {
    final id = _getUserId();
    if (id.isEmpty) throw StateError('[SemesterRepository] user not signed in');
    return id;
  }

  String _cacheKey(String uid)   => '${uid}_$_kActiveSemester';
  String _cacheTsKey(String uid) => '${uid}_$_kActiveSemesterTs';

  CollectionReference<Map<String, dynamic>> get _semestersCol =>
      _firestore.collection('users/$_userId/semesters');

  // ── Public API ───────────────────────────────────────────────────────────────

  Future<AcademicSemester?> getActiveSemester() async {
    final uid = _userId;
    debugPrint('[DEBUG-REPO] getActiveSemester called, uid=$uid');
    try {
      final snap = await _semestersCol
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      debugPrint('[DEBUG-REPO] Firestore docs count: ${snap.docs.length}');

      if (snap.docs.isEmpty) {
        final cached = _loadFromCache(uid, strict: true);
        debugPrint('[DEBUG-REPO] cache result: ${cached?.id}');
        return cached;
      }

      final semester = AcademicSemester.fromJson(snap.docs.first.data());
      debugPrint('[DEBUG-REPO] found semester: ${semester.id}, isActive: ${semester.isActive}');
      await _writeToCache(semester, uid);
      return semester;
    } catch (e) {
      debugPrint('[DEBUG-REPO] error: $e');
      return _loadFromCache(uid);
    }
  }

  Future<void> saveSemester(AcademicSemester semester) async {
    final uid = _userId;
    await _writeToCache(semester, uid);
    debugPrint('[DEBUG-SAVE] cache written for ${semester.id}');
    try {
      await _semestersCol.doc(semester.id).set(semester.toJson());
      debugPrint('[DEBUG-SAVE] Firestore write SUCCESS for ${semester.id}');
    } catch (e) {
      debugPrint('[DEBUG-SAVE] Firestore write FAILED: $e');
      rethrow;
    }
  }

  Future<void> deactivateSemester(String semesterId) async {
    final uid = _userId;
    try {
      await _semestersCol.doc(semesterId).update({'isActive': false});
      await _prefs.remove(_cacheKey(uid));
      await _prefs.remove(_cacheTsKey(uid));
    } catch (e) {
      debugPrint('[SemesterRepository] deactivateSemester error: $e');
      rethrow;
    }
  }

  Stream<AcademicSemester?> watchActiveSemester() {
    final uid = _userId;
    late StreamSubscription firestoreSub;
    final controller = StreamController<AcademicSemester?>(
      onCancel: () => firestoreSub.cancel(),
    );

    Future<void>(() {
      try {
        final cached = _loadFromCache(uid);
        if (!controller.isClosed) controller.add(cached);
      } catch (_) {
        if (!controller.isClosed) controller.add(null);
      }
    });

    firestoreSub = _semestersCol
        .where('isActive', isEqualTo: true)
        .limit(1)
        .snapshots()
        .listen(
      (snap) {
        if (snap.docs.isEmpty) {
          if (!controller.isClosed) controller.add(null);
          return;
        }
        try {
          final semester = AcademicSemester.fromJson(snap.docs.first.data());
          _writeToCache(semester, uid);
          if (!controller.isClosed) controller.add(semester);
        } catch (e) {
          debugPrint('[SemesterRepository] watchActiveSemester parse error: $e');
        }
      },
      onError: (Object e) {
        debugPrint('[SemesterRepository] watchActiveSemester error: $e');
      },
    );

    return controller.stream;
  }

  // ── Cache helpers ────────────────────────────────────────────────────────────

  Future<void> _writeToCache(AcademicSemester s, String uid) async {
    await _prefs.setString(_cacheKey(uid), jsonEncode(s.toJsonForCache())); // ← toJsonForCache
    await _prefs.setInt(_cacheTsKey(uid), DateTime.now().millisecondsSinceEpoch);
  }

  AcademicSemester? _loadFromCache(String uid, {bool strict = false}) {
    final raw = _prefs.getString(_cacheKey(uid));
    if (raw == null) return null;
    try {
      final semester = AcademicSemester.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map));
      final tsMs = _prefs.getInt(_cacheTsKey(uid)) ?? 0;
      if (strict && _isCacheExpired(tsMs)) return null;
      return semester;
    } catch (_) {
      return null;
    }
  }

  bool _isCacheExpired(int tsMs) {
    if (tsMs == 0) return true;
    return DateTime.now()
            .difference(DateTime.fromMillisecondsSinceEpoch(tsMs)) >
        _kCacheTtl;
  }
}