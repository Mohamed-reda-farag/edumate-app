import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/task_model.dart';

// ══════════════════════════════════════════════════════════════════════════════
// TaskRepository
// ══════════════════════════════════════════════════════════════════════════════

class TaskRepository {
  TaskRepository({
    required FirebaseFirestore firestore,
    required String Function() getUserId,
  })  : _firestore = firestore,
        _getUserId = getUserId;

  final FirebaseFirestore _firestore;
  final String Function() _getUserId;

  // ── userId ──────────────────────────────────────────────────────────────────

  String get _userId {
    final id = _getUserId();
    if (id.isEmpty) {
      throw StateError('[TaskRepository] userId is empty — user not signed in.');
    }
    return id;
  }

  // ── Firestore refs ──────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _dailyTasksCol =>
      _firestore.collection('users/$_userId/daily_tasks');

  CollectionReference<Map<String, dynamic>> get _courseTasksCol =>
      _firestore.collection('users/$_userId/course_tasks');

  CollectionReference<Map<String, dynamic>> get _customTasksCol =>
      _firestore.collection('users/$_userId/custom_tasks');

  // ══════════════════════════════════════════════════════════════════════════
  //  Daily Tasks (محاضرات + جلسات مذاكرة)
  // ══════════════════════════════════════════════════════════════════════════

  /// مزامنة كاملة لمهام اليوم — تحذف القديمة وتكتب الجديدة.
  Future<void> syncDailyTasks(List<TaskModel> todayTasks) async {
    final batch = _firestore.batch();

    // 1. اقرأ الحالات المهمة الحالية قبل الحذف
    final existing = await _dailyTasksCol.get();
    final savedStatuses = <String, Map<String, dynamic>>{};

    for (final doc in existing.docs) {
      final data = doc.data();
      final status = data['status'] as String?;
      final shouldPreserve =
          status == TaskStatus.completed.name ||
          status == TaskStatus.ongoing.name; // ongoing = started في الـ UI

      if (shouldPreserve) {
        savedStatuses[doc.id] = {
          'status': data['status'],
          if (data['attendanceStatus'] != null)
            'attendanceStatus': data['attendanceStatus'],
          if (data['studySessionStatus'] != null)
            'studySessionStatus': data['studySessionStatus'],
          'updatedAt': data['updatedAt'],
        };
      }
      batch.delete(doc.reference);
    }

    // 2. اكتب مهام اليوم الجديدة مع استعادة الحالات المحفوظة
    for (final task in todayTasks) {
      final json = task.toJson();

      final saved = savedStatuses[task.id];
      if (saved != null) {
        json['status'] = saved['status'];
        if (saved['attendanceStatus'] != null) {
          json['attendanceStatus'] = saved['attendanceStatus'];
        }
        if (saved['studySessionStatus'] != null) {
          json['studySessionStatus'] = saved['studySessionStatus'];
        }
        // نحافظ على updatedAt الأصلي لمنع تغيير الـ timestamp
        json['updatedAt'] = saved['updatedAt'];
      }

      batch.set(_dailyTasksCol.doc(task.id), json);
    }

    await batch.commit();
    debugPrint(
      '[TaskRepository] syncDailyTasks: ${todayTasks.length} tasks'
      ' (${savedStatuses.length} statuses preserved'
      ' — completed+started)',
    );
  }

  /// جلب مهام اليوم (مرة واحدة)
  Future<List<TaskModel>> getDailyTasks() async {
    try {
      final snap = await _dailyTasksCol.get();
      return snap.docs.map((d) => TaskModel.fromJson(d.data())).toList();
    } catch (e) {
      debugPrint('[TaskRepository] getDailyTasks error: $e');
      return [];
    }
  }

  /// Stream مباشر لمهام اليوم
  Stream<List<TaskModel>> watchDailyTasks() {
    return _dailyTasksCol.snapshots().map((snap) {
      final tasks = <TaskModel>[];
      for (final doc in snap.docs) {
        try {
          tasks.add(TaskModel.fromJson(doc.data()));
        } catch (e) {
          debugPrint('[TaskRepository] watchDailyTasks parse error doc ${doc.id}: $e');
        }
      }
      return tasks;
    });
  }

  /// تحديث حالة مهمة يومية (تسجيل حضور / إكمال جلسة)
  Future<void> updateDailyTask(TaskModel task) async {
    try {
      await _dailyTasksCol.doc(task.id).set(
        task.toJson(),
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('[TaskRepository] updateDailyTask error: $e');
      rethrow;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  Course Tasks (مهام الكورسات)
  // ══════════════════════════════════════════════════════════════════════════

  /// جلب مهام الكورسات
  Future<List<TaskModel>> getCourseTasks() async {
    try {
      final snap = await _courseTasksCol.get();
      return snap.docs.map((d) => TaskModel.fromJson(d.data())).toList();
    } catch (e) {
      debugPrint('[TaskRepository] getCourseTasks error: $e');
      return [];
    }
  }

  /// Stream مباشر لمهام الكورسات
  Stream<List<TaskModel>> watchCourseTasks() {
    return _courseTasksCol.snapshots().map((snap) {
      final tasks = <TaskModel>[];
      for (final doc in snap.docs) {
        try {
          tasks.add(TaskModel.fromJson(doc.data()));
        } catch (e) {
          debugPrint('[TaskRepository] watchCourseTasks parse error doc ${doc.id}: $e');
        }
      }
      return tasks;
    });
  }

  /// حفظ/تحديث مهمة كورس واحدة
  Future<void> saveCourseTask(TaskModel task) async {
    try {
      await _courseTasksCol.doc(task.id).set(task.toJson());
    } catch (e) {
      debugPrint('[TaskRepository] saveCourseTask error: $e');
      rethrow;
    }
  }

  /// حذف مهمة كورس (عند إكمال الكورس)
  Future<void> deleteCourseTask(String taskId) async {
    try {
      await _courseTasksCol.doc(taskId).delete();
    } catch (e) {
      debugPrint('[TaskRepository] deleteCourseTask error: $e');
      rethrow;
    }
  }

  Future<void> syncCourseTasks(List<TaskModel> tasks) async {
    final batch = _firestore.batch();

    final existing = await _courseTasksCol.get();
    final existingIds = existing.docs.map((d) => d.id).toSet();
    final newIds = tasks.map((t) => t.id).toSet();

    // حذف الكورسات التي لم تعد في القائمة النشطة
    for (final doc in existing.docs) {
      if (!newIds.contains(doc.id)) {
        batch.delete(doc.reference);
        debugPrint('[TaskRepository] Removing stale course task: ${doc.id}');
      }
    }

    // إضافة/تحديث مهام الكورسات
    for (final task in tasks) {
      final isNew = !existingIds.contains(task.id);
      batch.set(_courseTasksCol.doc(task.id), task.toJson());
      if (isNew) {
        debugPrint('[TaskRepository] Adding new course task: ${task.id}');
      }
    }

    await batch.commit();
    debugPrint(
      '[TaskRepository] syncCourseTasks: ${tasks.length} tasks'
      ' (removed: ${existingIds.difference(newIds).length})',
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  Custom Tasks (المهام المخصصة)
  // ══════════════════════════════════════════════════════════════════════════

  /// جلب المهام المخصصة مرتبةً من الأحدث للأقدم.
  Future<List<TaskModel>> getCustomTasks() async {
    try {
      final snap = await _customTasksCol
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs.map((d) => TaskModel.fromJson(d.data())).toList();
    } catch (e) {
      debugPrint('[TaskRepository] getCustomTasks error: $e');
      return [];
    }
  }

  /// Stream مباشر للمهام المخصصة مرتبةً من الأحدث للأقدم.
  Stream<List<TaskModel>> watchCustomTasks() {
    return _customTasksCol
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
      final tasks = <TaskModel>[];
      for (final doc in snap.docs) {
        try {
          tasks.add(TaskModel.fromJson(doc.data()));
        } catch (e) {
          debugPrint('[TaskRepository] watchCustomTasks parse error doc ${doc.id}: $e');
        }
      }
      return tasks;
    });
  }

  /// إضافة مهمة مخصصة جديدة
  Future<void> addCustomTask(TaskModel task) async {
    try {
      await _customTasksCol.doc(task.id).set(task.toJson());
      debugPrint('[TaskRepository] addCustomTask: ${task.id}');
    } catch (e) {
      debugPrint('[TaskRepository] addCustomTask error: $e');
      rethrow;
    }
  }

  /// تحديث مهمة مخصصة كاملة.
  Future<void> updateCustomTask(TaskModel task) async {
    try {
      await _customTasksCol.doc(task.id).set(
        task.toJson(),
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('[TaskRepository] updateCustomTask error: $e');
      rethrow;
    }
  }

  /// حذف مهمة مخصصة
  Future<void> deleteCustomTask(String taskId) async {
    try {
      await _customTasksCol.doc(taskId).delete();
    } catch (e) {
      debugPrint('[TaskRepository] deleteCustomTask error: $e');
      rethrow;
    }
  }

  /// تحديث حالة مهمة مخصصة فقط (إكمال / إلغاء إكمال)
  Future<void> updateCustomTaskStatus(
      String taskId, TaskStatus status) async {
    try {
      await _customTasksCol.doc(taskId).set(
        {
          'status': status.name,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('[TaskRepository] updateCustomTaskStatus error: $e');
      rethrow;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  Sync Metadata — تتبع آخر مزامنة يومية
  // ══════════════════════════════════════════════════════════════════════════

  DocumentReference<Map<String, dynamic>> get _syncMetaDoc =>
      _firestore.doc('users/$_userId/task_meta/sync');

  /// حفظ تاريخ آخر مزامنة يومية
  Future<void> saveLastSyncDate(DateTime date) async {
    try {
      await _syncMetaDoc.set({
        'lastSyncDate': Timestamp.fromDate(date),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint('[TaskRepository] saveLastSyncDate error: $e');
    }
  }

  /// جلب تاريخ آخر مزامنة يومية
  Future<DateTime?> getLastSyncDate() async {
    try {
      final snap = await _syncMetaDoc.get();
      if (snap.exists && snap.data() != null) {
        final ts = snap.data()!['lastSyncDate'];
        if (ts is Timestamp) return ts.toDate();
      }
      return null;
    } catch (e) {
      debugPrint('[TaskRepository] getLastSyncDate error: $e');
      return null;
    }
  }
}