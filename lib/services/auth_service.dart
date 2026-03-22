import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

/// AuthService
/// ─────────────────────────────────────────────────────────────────
/// Singleton — المصدر الوحيد لعمليات Firebase Auth و Firestore
/// المتعلقة بالمستخدم. لا يحتوي على منطق UI.
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // مفاتيح SharedPreferences الخاصة بالمستخدم فقط
  static const _prefKeys = ['survey_completed', 'last_sync', 'user_theme'];

  // ─── Streams & Getters ────────────────────────────────────────────
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentFirebaseUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;
  String? get currentUserEmail => _auth.currentUser?.email;
  bool get isAuthenticated => _auth.currentUser != null;
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // ─── Get Current User ─────────────────────────────────────────────
  Future<UserModel?> getCurrentUser() async {
    final user = currentFirebaseUser;
    if (user == null) return null;
    return _getUserFromFirestore(user.uid);
  }

  // ─── Sign In ──────────────────────────────────────────────────────
  Future<ApiResponse<UserModel>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;

      await _db.collection('users').doc(uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      }).catchError((_) {});

      final userModel = await _getUserFromFirestore(uid);
      if (userModel == null) {
        return ApiResponse.error(error: 'فشل في تحميل بيانات المستخدم');
      }

      return ApiResponse.success(
        data: userModel,
        message: 'تم تسجيل الدخول بنجاح',
      );
    } on FirebaseAuthException catch (e) {
      return ApiResponse.error(error: _mapAuthError(e.code));
    } catch (e) {
      debugPrint('signInWithEmailAndPassword error: $e');
      return ApiResponse.error(error: 'حدث خطأ غير متوقع');
    }
  }

  // ─── Sign Up ──────────────────────────────────────────────────────
  Future<ApiResponse<UserModel>> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user!;
      await user.updateDisplayName(name);

      UserModel? userModel = await createUserDocument(
        uid: user.uid,
        email: email,
        name: name,
        photoUrl: user.photoURL,
      );

      // retry مرة واحدة إن فشل الأول
      if (userModel == null) {
        await Future.delayed(const Duration(milliseconds: 800));
        userModel = await createUserDocument(
          uid: user.uid,
          email: email,
          name: name,
          photoUrl: user.photoURL,
        );
      }

      if (userModel == null) {
        debugPrint('⚠️ Auth created but Firestore doc failed — partial success');
        return ApiResponse.error(
          error: 'تم إنشاء الحساب لكن فشل حفظ البيانات. سيتم المحاولة تلقائياً',
        );
      }

      // إرسال بريد التحقق فور إنشاء الحساب بنجاح
      try {
        await user.sendEmailVerification();
        debugPrint('✅ Verification email sent to $email');
      } catch (e) {
        debugPrint('⚠️ sendEmailVerification error: $e');
      }

      return ApiResponse.success(
        data: userModel,
        message: 'تم إنشاء الحساب بنجاح',
      );
    } on FirebaseAuthException catch (e) {
      return ApiResponse.error(error: _mapAuthError(e.code));
    } catch (e) {
      debugPrint('createUserWithEmailAndPassword error: $e');
      return ApiResponse.error(error: 'حدث خطأ أثناء إنشاء الحساب');
    }
  }

  // ─── Create User Document ─────────────────────────────────────────
  Future<UserModel?> createUserDocument({
    required String uid,
    required String email,
    required String name,
    String? photoUrl,
  }) async {
    try {
      final userModel = UserModel(
        uid: uid,
        email: email,
        name: name,
        photoUrl: photoUrl,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        isEmailVerified: false,
      );
      await _db.collection('users').doc(uid).set(userModel.toMap());
      return userModel;
    } catch (e) {
      debugPrint('createUserDocument error: $e');
      return null;
    }
  }

  // ─── Sign Out ─────────────────────────────────────────────────────
  Future<ApiResponse<bool>> signOut() async {
    try {
      await _auth.signOut();
      await _clearLocalData();
      return ApiResponse.success(data: true, message: 'تم تسجيل الخروج بنجاح');
    } catch (e) {
      debugPrint('signOut error: $e');
      return ApiResponse.error(error: 'حدث خطأ أثناء تسجيل الخروج');
    }
  }

  // ─── Password Reset ───────────────────────────────────────────────
  Future<ApiResponse<bool>> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return ApiResponse.success(
        data: true,
        message: 'تم إرسال رابط إعادة تعيين كلمة المرور',
      );
    } on FirebaseAuthException catch (e) {
      return ApiResponse.error(error: _mapAuthError(e.code));
    } catch (e) {
      debugPrint('sendPasswordResetEmail error: $e');
      return ApiResponse.error(error: 'حدث خطأ أثناء إرسال الرابط');
    }
  }

  // ─── Email Verification ───────────────────────────────────────────
  Future<ApiResponse<bool>> sendEmailVerification() async {
    try {
      final user = currentFirebaseUser;
      if (user == null) return ApiResponse.error(error: 'يجب تسجيل الدخول أولاً');
      if (user.emailVerified) {
        return ApiResponse.success(data: true, message: 'البريد محقق بالفعل');
      }
      await user.sendEmailVerification();
      return ApiResponse.success(
        data: true,
        message: 'تم إرسال رابط التحقق إلى بريدك الإلكتروني',
      );
    } on FirebaseAuthException catch (e) {
      return ApiResponse.error(error: _mapAuthError(e.code));
    } catch (e) {
      debugPrint('sendEmailVerification error: $e');
      return ApiResponse.error(error: 'حدث خطأ أثناء إرسال رابط التحقق');
    }
  }

  Future<ApiResponse<bool>> reloadUser() async {
    try {
      final user = currentFirebaseUser;
      if (user == null) return ApiResponse.error(error: 'لا يوجد مستخدم مسجل دخول');
      await user.reload();
      return ApiResponse.success(
        data: _auth.currentUser?.emailVerified ?? false,
      );
    } catch (e) {
      debugPrint('reloadUser error: $e');
      return ApiResponse.error(error: 'فشل في تحديث حالة المستخدم');
    }
  }

  // ─── Update Profile ───────────────────────────────────────────────
  Future<ApiResponse<UserModel>> updateUserProfile({
    String? name,
    String? photoUrl,
    Map<String, dynamic>? profileData,
  }) async {
    try {
      final user = currentFirebaseUser;
      if (user == null) return ApiResponse.error(error: 'يجب تسجيل الدخول أولاً');

      final updates = <String, dynamic>{};

      if (name != null && name.trim().isNotEmpty) {
        await user.updateDisplayName(name.trim());
        updates['name'] = name.trim();
      }

      if (photoUrl != null) {
        await user.updatePhotoURL(photoUrl);
        updates['photoUrl'] = photoUrl;
      }

      if (profileData != null) updates.addAll(profileData);

      if (updates.isNotEmpty) {
        updates['updatedAt'] = FieldValue.serverTimestamp();
        await _db.collection('users').doc(user.uid).update(updates);
      }

      final updatedUser = await _getUserFromFirestore(user.uid);
      if (updatedUser == null) {
        return ApiResponse.error(error: 'فشل في تحميل البيانات المحدثة');
      }

      return ApiResponse.success(
        data: updatedUser,
        message: 'تم تحديث الملف الشخصي بنجاح',
      );
    } on FirebaseAuthException catch (e) {
      return ApiResponse.error(error: _mapAuthError(e.code));
    } catch (e) {
      debugPrint('updateUserProfile error: $e');
      return ApiResponse.error(error: 'حدث خطأ أثناء تحديث الملف الشخصي');
    }
  }

  // ─── Update Bio ───────────────────────────────────────────────────
  /// ✅ FIX #1: bio يُحفظ داخل profile map وليس في root الـ document
  Future<ApiResponse<UserModel>> updateBio(String bio) async {
    try {
      final user = currentFirebaseUser;
      if (user == null) return ApiResponse.error(error: 'يجب تسجيل الدخول أولاً');

      // استخدام dot notation لتحديث حقل داخل map دون الكتابة فوق بقية الـ map
      await _db.collection('users').doc(user.uid).update({
        'profile.bio': bio.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final updatedUser = await _getUserFromFirestore(user.uid);
      if (updatedUser == null) {
        return ApiResponse.error(error: 'فشل في تحميل البيانات المحدثة');
      }

      return ApiResponse.success(
        data: updatedUser,
        message: 'تم تحديث النبذة الشخصية بنجاح',
      );
    } catch (e) {
      debugPrint('updateBio error: $e');
      return ApiResponse.error(error: 'حدث خطأ أثناء تحديث النبذة');
    }
  }

  // ─── Delete Account ───────────────────────────────────────────────
  Future<ApiResponse<bool>> deleteAccount({required String password}) async {
    try {
      final user = currentFirebaseUser;
      if (user == null) return ApiResponse.error(error: 'يجب تسجيل الدخول أولاً');
      if (user.email == null) return ApiResponse.error(error: 'لا يوجد بريد إلكتروني مرتبط بالحساب');

      // 1. إعادة المصادقة
      try {
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          return ApiResponse.error(error: 'كلمة المرور غير صحيحة');
        }
        return ApiResponse.error(error: _mapAuthError(e.code));
      }

      // 2. حذف كل subcollections داخل users/{uid}
      final subcollections = [
        'schedule', 'study_sessions', 'attendance', 'gamification',
        'semesters', 'daily_tasks', 'course_tasks', 'custom_tasks',
        'task_meta', 'notification_meta', 'cv_data',
        'subject_performance', 'semester_records',
      ];

      for (final sub in subcollections) {
        await _deleteSubcollection(user.uid, sub);
      }

      // 3. حذف documents الرئيسية
      await _db.collection('users').doc(user.uid).delete().catchError((_) {});
      await _db.collection('user_profiles').doc(user.uid).delete().catchError((_) {});
      await _db.collection('user_statistics').doc(user.uid).delete().catchError((_) {});

      // 4. حذف Firebase Auth أخيراً
      await user.delete();
      await _clearLocalData();

      return ApiResponse.success(data: true, message: 'تم حذف الحساب بنجاح');
    } on FirebaseAuthException catch (e) {
      return ApiResponse.error(error: _mapAuthError(e.code));
    } catch (e) {
      debugPrint('deleteAccount error: $e');
      return ApiResponse.error(error: 'حدث خطأ أثناء حذف الحساب');
    }
  }

  // helper لحذف كل documents داخل subcollection
  Future<void> _deleteSubcollection(String uid, String subcollection) async {
    try {
      final snapshot = await _db
          .collection('users')
          .doc(uid)
          .collection(subcollection)
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint('_deleteSubcollection $subcollection error: $e');
    }
  }

  // ─── Private Helpers ─────────────────────────────────────────────
  Future<UserModel?> _getUserFromFirestore(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('_getUserFromFirestore error: $e');
      return null;
    }
  }

  // ✅ FIX #9: يمسح فقط المفاتيح المتعلقة بالمستخدم وليس كل شيء
  Future<void> _clearLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key in _prefKeys) {
        await prefs.remove(key);
      }
    } catch (e) {
      debugPrint('_clearLocalData error: $e');
    }
  }

  String _mapAuthError(String code) {
    const map = {
      'user-not-found': 'لم يتم العثور على المستخدم',
      'wrong-password': 'كلمة المرور غير صحيحة',
      'invalid-credential': 'بيانات الاعتماد غير صحيحة',
      'email-already-in-use': 'البريد الإلكتروني مستخدم بالفعل',
      'weak-password': 'كلمة المرور لا تلبي متطلبات الأمان',
      'invalid-email': 'البريد الإلكتروني غير صحيح',
      'user-disabled': 'تم تعطيل هذا الحساب',
      'too-many-requests': 'تم تجاوز عدد المحاولات. حاول لاحقاً',
      'operation-not-allowed': 'هذه العملية غير مسموحة',
      'requires-recent-login': 'يجب إعادة تسجيل الدخول لتنفيذ هذه العملية',
      'network-request-failed': 'فشل الاتصال بالشبكة',
      // ✅ FIX: رسائل خاصة بسياسة كلمة المرور من Firebase
      'password-does-not-meet-requirements': 'كلمة المرور لا تلبي متطلبات الأمان:\nيجب أن تحتوي على أحرف كبيرة وصغيرة وأرقام ورمز خاص',
    };
    return map[code] ?? 'حدث خطأ غير متوقع';
  }
}