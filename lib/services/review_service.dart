import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/review_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// نتيجة عملية المراجعة
// ─────────────────────────────────────────────────────────────────────────────
enum ReviewResultStatus { success, profanityDetected, notCompleted, alreadyReviewed, error }

class ReviewResult {
  final ReviewResultStatus status;
  final String? message;
  final ReviewModel? review;

  const ReviewResult._({required this.status, this.message, this.review});

  factory ReviewResult.success(ReviewModel review) =>
      ReviewResult._(status: ReviewResultStatus.success, review: review);

  factory ReviewResult.profanity() => const ReviewResult._(
        status: ReviewResultStatus.profanityDetected,
        message: 'تحتوي مراجعتك على كلمات غير لائقة. يرجى مراجعة المحتوى وإعادة الكتابة.',
      );

  factory ReviewResult.notCompleted() => const ReviewResult._(
        status: ReviewResultStatus.notCompleted,
        message: 'يجب إكمال الكورس أولاً لكتابة مراجعة.',
      );

  factory ReviewResult.alreadyReviewed() => const ReviewResult._(
        status: ReviewResultStatus.alreadyReviewed,
        message: 'لقد كتبت مراجعة لهذا الكورس مسبقاً.',
      );

  factory ReviewResult.error(String msg) =>
      ReviewResult._(status: ReviewResultStatus.error, message: msg);

  bool get isSuccess => status == ReviewResultStatus.success;
  bool get isProfanity => status == ReviewResultStatus.profanityDetected;
}

// ─────────────────────────────────────────────────────────────────────────────
// ReviewService
// ─────────────────────────────────────────────────────────────────────────────
class ReviewService {
  static final ReviewService _instance = ReviewService._internal();
  factory ReviewService() => _instance;
  ReviewService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // مسار: reviews/{courseId}/reviews/{userId}
  CollectionReference<Map<String, dynamic>> _reviewsRef(String courseId) =>
      _firestore.collection('reviews').doc(courseId).collection('reviews');

  // ─── Profanity Filter ────────────────────────────────────────────────────
  static const List<String> _profanityList = [
    // عربي
    'احمق', 'أحمق', 'غبي', 'حمار', 'كلب', 'خنزير', 'عاهرة', 'شرموط',
    'قحبة', 'زبالة', 'منيوك', 'يلعن', 'عرص', 'طز', 'نيك', 'كس',
    'زب', 'طيز', 'خول', 'بعرص', 'ابن الشرموطة', 'ابن الكلب',
    // إنجليزي
    'fuck', 'shit', 'bitch', 'asshole', 'bastard', 'cunt',
    'dick', 'pussy', 'whore', 'slut', 'nigger', 'faggot', 'retard',
  ];

  // ── بناء الـ patterns مرة واحدة عند تحميل الكلاس ──────────────────────
  static final List<RegExp> _profanityPatterns = _profanityList
      .map(
        (word) => RegExp(
          r'(^|[\s،,\.!؟?])' + RegExp.escape(word) + r'($|[\s،,\.!؟?])',
          caseSensitive: false,
          unicode: true,
        ),
      )
      .toList();

  bool containsProfanity(String text) {
    final padded = ' ${text.toLowerCase()} ';
    return _profanityPatterns.any((pattern) => pattern.hasMatch(padded));
  }

  // ─── CRUD ────────────────────────────────────────────────────────────────

  Future<ReviewResult> addReview({
    required String courseId,
    required double rating,
    required String comment,
    required bool isCourseCompleted,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return ReviewResult.error('يجب تسجيل الدخول أولاً');
      if (!isCourseCompleted) return ReviewResult.notCompleted();
      if (containsProfanity(comment)) return ReviewResult.profanity();

      final existing = await _reviewsRef(courseId).doc(user.uid).get();
      if (existing.exists) return ReviewResult.alreadyReviewed();

      final userName = await _getUserName(user);
      final now = DateTime.now();

      final review = ReviewModel(
        id: user.uid,
        courseId: courseId,
        userId: user.uid,
        userName: userName,
        rating: rating,
        comment: comment.trim(),
        createdAt: now,
        updatedAt: now,
      );

      // ── كتابة المراجعة وتحديث الإحصائيات في batch واحد ─────────────────
      final batch = _firestore.batch();

      // Write 1: المراجعة نفسها
      batch.set(_reviewsRef(courseId).doc(user.uid), review.toMap());

      // Write 2: تحديث reviewCount في document الكورس
      // المسار: course_stats/{courseId}
      final statsRef = _firestore.collection('course_stats').doc(courseId);
      batch.set(
        statsRef,
        {
          'reviewCount': FieldValue.increment(1),
          'ratingSum': FieldValue.increment(rating),
          'lastUpdated': Timestamp.fromDate(now),
        },
        SetOptions(merge: true),
      );

      await batch.commit();
      debugPrint('✅ Review added: $courseId by ${user.uid}');
      return ReviewResult.success(review);
    } catch (e) {
      debugPrint('❌ addReview error: $e');
      return ReviewResult.error('حدث خطأ أثناء نشر المراجعة');
    }
  }

  Future<ReviewResult> updateReview({
    required String courseId,
    required double rating,
    required String comment,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return ReviewResult.error('يجب تسجيل الدخول أولاً');
      if (containsProfanity(comment)) return ReviewResult.profanity();

      final docRef = _reviewsRef(courseId).doc(user.uid);
      final existing = await docRef.get();
      if (!existing.exists) return ReviewResult.error('لا توجد مراجعة لتعديلها');

      final oldReview = ReviewModel.fromFirestore(existing);
      final updatedAt = DateTime.now();
      final updatedReview = oldReview.copyWith(
        rating: rating,
        comment: comment.trim(),
        updatedAt: updatedAt,
      );

      final batch = _firestore.batch();

      // Write 1: تحديث المراجعة
      batch.update(docRef, {
        'rating': rating,
        'comment': comment.trim(),
        'updatedAt': Timestamp.fromDate(updatedAt),
      });

      // Write 2: تحديث الـ ratingSum (نطرح القديم ونضيف الجديد)
      final statsRef = _firestore.collection('course_stats').doc(courseId);
      batch.set(
        statsRef,
        {
          'ratingSum': FieldValue.increment(rating - oldReview.rating),
          'lastUpdated': Timestamp.fromDate(updatedAt),
        },
        SetOptions(merge: true),
      );

      await batch.commit();
      debugPrint('✅ Review updated: $courseId');
      return ReviewResult.success(updatedReview);
    } catch (e) {
      debugPrint('❌ updateReview error: $e');
      return ReviewResult.error('حدث خطأ أثناء تعديل المراجعة');
    }
  }

  Future<ReviewResult> deleteReview({required String courseId}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return ReviewResult.error('يجب تسجيل الدخول أولاً');

      // جلب المراجعة أولاً لمعرفة التقييم قبل الحذف
      final docRef = _reviewsRef(courseId).doc(user.uid);
      final existing = await docRef.get();
      if (!existing.exists) {
        return ReviewResult.error('لا توجد مراجعة لحذفها');
      }

      final oldRating =
          (existing.data()?['rating'] as num?)?.toDouble() ?? 0.0;

      final batch = _firestore.batch();

      // Write 1: حذف المراجعة
      batch.delete(docRef);

      // Write 2: تحديث الإحصائيات
      final statsRef = _firestore.collection('course_stats').doc(courseId);
      batch.set(
        statsRef,
        {
          'reviewCount': FieldValue.increment(-1),
          'ratingSum': FieldValue.increment(-oldRating),
          'lastUpdated': Timestamp.now(),
        },
        SetOptions(merge: true),
      );

      await batch.commit();
      debugPrint('✅ Review deleted: $courseId');
      return const ReviewResult._(status: ReviewResultStatus.success);
    } catch (e) {
      debugPrint('❌ deleteReview error: $e');
      return ReviewResult.error('حدث خطأ أثناء حذف المراجعة');
    }
  }

  Future<ReviewModel?> getUserReview(String courseId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      final doc = await _reviewsRef(courseId).doc(user.uid).get();
      if (!doc.exists) return null;
      return ReviewModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('❌ getUserReview error: $e');
      return null;
    }
  }

  /// Stream لجميع مراجعات الكورس (بدون المُبلَّغ عنها)
  Stream<List<ReviewModel>> watchCourseReviews(String courseId) {
    return _reviewsRef(courseId)
        .where('isFlagged', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ReviewModel.fromFirestore(d)).toList());
  }

  Future<double> getCourseAverageRating(String courseId) async {
    try {
      // قراءة من document الإحصائيات بدلاً من جلب كل المراجعات
      final statsDoc = await _firestore
          .collection('course_stats')
          .doc(courseId)
          .get();

      if (!statsDoc.exists) return 0.0;

      final data = statsDoc.data()!;
      final count = (data['reviewCount'] as num?)?.toInt() ?? 0;
      final sum = (data['ratingSum'] as num?)?.toDouble() ?? 0.0;

      if (count == 0) return 0.0;
      return sum / count;
    } catch (_) {
      return 0.0;
    }
  }

  String? get currentUserId => _auth.currentUser?.uid;

  Future<String> _getUserName(User user) async {
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final name = doc.data()?['name']?.toString();
        if (name != null && name.trim().isNotEmpty) return name.trim();
      }
      return user.displayName?.isNotEmpty == true
          ? user.displayName!.trim()
          : 'مستخدم';
    } catch (_) {
      return user.displayName ?? 'مستخدم';
    }
  }
}