// ============================================================
// cv_firestore_service.dart
// Firebase Firestore — حفظ وجلب بيانات السيرة الذاتية
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cv_model.dart';

class CVFirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Path: users/{userId}/cv_data/main_cv
  DocumentReference _cvDoc(String userId) =>
      _db.collection('users').doc(userId).collection('cv_data').doc('main_cv');

  // ── Fetch ──────────────────────────────────────────────────
  Future<CVModel?> fetchCV(String userId) async {
    final snap = await _cvDoc(userId).get();
    if (!snap.exists || snap.data() == null) return null;
    return CVModel.fromMap(snap.data() as Map<String, dynamic>);
  }

  // ── Save (Create or Update) ────────────────────────────────
  Future<void> saveCV(CVModel cv) async {
    await _cvDoc(cv.userId).set(cv.toMap(), SetOptions(merge: true));
  }

  // ── Delete ────────────────────────────────────────────────
  Future<void> deleteCV(String userId) async {
    await _cvDoc(userId).delete();
  }

  // ── Stream (for real-time listening if needed) ─────────────
  Stream<CVModel?> cvStream(String userId) {
    return _cvDoc(userId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return CVModel.fromMap(snap.data() as Map<String, dynamic>);
    });
  }
}
