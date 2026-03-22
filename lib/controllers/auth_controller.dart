import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

/// AuthController
/// ─────────────────────────────────────────────────────────────────
/// مسؤول عن حالة المصادقة داخل الـ UI فقط.
/// جميع عمليات Firebase الفعلية تُفوَّض إلى AuthService.
class AuthController with ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  bool _isLoading = false;

  String? _errorMessage;
  String? _successMessage;
  bool _isSuccess = false;

  /// true بعد إنشاء حساب جديد ناجح — يُستخدم للتوجيه لشاشة تأكيد الإيميل
  bool _justRegistered = false;

  /// true أثناء reloadUser — يمنع _onAuthStateChanged من إطلاق onLogin مرة ثانية
  bool _isReloadingUser = false;

  // Rate limiting (محلي - UI فقط)
  DateTime? _lastLoginAttempt;
  int _failedAttempts = 0;
  static const Duration _rateLimitDelay = Duration(seconds: 30);
  static const int _maxFailedAttempts = 5;

  // ─── Callbacks ───────────────────────────────────────────────────
  VoidCallback? onLogin;
  VoidCallback? onLogout;

  // ─── Getters ────────────────────────────────────────────────────
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isSuccess => _isSuccess;
  bool get isLoggedIn => _authService.currentFirebaseUser != null;
  bool get justRegistered => _justRegistered;
  String? get currentUserId => _authService.currentUserId;
  bool get isEmailVerified => _authService.isEmailVerified;

  String? get errorMessage => _isSuccess ? null : _errorMessage;

  // getter جديد للرسائل بشكل عام (يُستخدم في الشاشات)
  String? get statusMessage => _isSuccess ? _successMessage : _errorMessage;

  bool get isRateLimited =>
      _failedAttempts >= _maxFailedAttempts &&
      _lastLoginAttempt != null &&
      DateTime.now().difference(_lastLoginAttempt!) < _rateLimitDelay;

  // ─── Constructor ────────────────────────────────────────────────
  AuthController() {
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  // ─── Auth State Listener ─────────────────────────────────────────
  Future<void> _onAuthStateChanged(User? user) async {
    if (user != null) {
      // إذا كنا في منتصف signUp أو reloadUser، لا نُطلق onLogin
      if (!_justRegistered && !_isReloadingUser) {
        await _loadCurrentUser(user.uid);
        _resetRateLimit();
        onLogin?.call();
      }
    } else {
      _currentUser = null;
      _justRegistered = false;
      _clearMessages();
      onLogout?.call();
    }
    notifyListeners();
  }

  Future<void> _loadCurrentUser(String uid) async {
    try {
      final userModel = await _authService.getCurrentUser();
      if (userModel != null) {
        _currentUser = userModel;
      } else {
        final firebaseUser = _authService.currentFirebaseUser!;
        final name = firebaseUser.displayName?.trim();
        final created = await _authService.createUserDocument(
          uid: uid,
          email: firebaseUser.email ?? '',
          name: (name != null && name.isNotEmpty)
              ? name
              : (firebaseUser.email?.split('@').first ?? 'مستخدم'),
          photoUrl: firebaseUser.photoURL,
        );
        _currentUser = created;
      }
    } catch (e) {
      debugPrint('AuthController._loadCurrentUser error: $e');
    }
  }

  // ─── Login ────────────────────────────────────────────────────────
  Future<void> login(String email, String password) async {
    if (!_checkRateLimit()) return;

    _setLoading(true);
    _clearMessages();
    _lastLoginAttempt = DateTime.now();

    final result = await _authService.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    if (result.isSuccessful) {
      _currentUser = result.data;
      _resetRateLimit();
      _setSuccess('تم تسجيل الدخول بنجاح');
    } else {
      _incrementFailed();
      _setError(result.error ?? 'حدث خطأ غير متوقع');
    }

    _setLoading(false);
  }

  // ─── Sign Up ──────────────────────────────────────────────────────
  Future<void> signUp(String email, String password, String name) async {
    if (!_checkRateLimit()) return;

    _setLoading(true);
    _clearMessages();

    // نمنع _onAuthStateChanged من إطلاق onLogin أثناء التسجيل
    _justRegistered = true;

    final result = await _authService.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
      name: name.trim(),
    );

    if (result.isSuccessful) {
      _currentUser = result.data;
      _resetRateLimit();
      _setSuccess('تم إنشاء الحساب بنجاح');
      // بريد التحقق أُرسل داخل AuthService
    } else {
      _justRegistered = false;
      _incrementFailed();
      _setError(result.error ?? 'حدث خطأ أثناء إنشاء الحساب');
    }

    _setLoading(false);
  }

  // ─── Logout ───────────────────────────────────────────────────────
  Future<void> logout() async {
    _setLoading(true);
    _clearMessages();
    _justRegistered = false;

    final result = await _authService.signOut();
    if (!result.isSuccessful) {
      _setError(result.error ?? 'حدث خطأ أثناء تسجيل الخروج');
    } else {
      _currentUser = null;
      _resetRateLimit();
    }

    _setLoading(false);
  }

  // ─── Password Reset ───────────────────────────────────────────────
  Future<void> resetPassword(String email) async {
    _setLoading(true);
    _clearMessages();

    final result = await _authService.sendPasswordResetEmail(email.trim());

    if (result.isSuccessful) {
      _setSuccess('تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني');
    } else {
      _setError(result.error ?? 'حدث خطأ أثناء إرسال الرابط');
    }

    _setLoading(false);
  }

  // ─── Email Verification ───────────────────────────────────────────
  Future<void> sendEmailVerification() async {
    _setLoading(true);
    _clearMessages();

    final result = await _authService.sendEmailVerification();

    if (result.isSuccessful) {
      _setSuccess('تم إرسال رابط التحقق إلى بريدك الإلكتروني');
    } else {
      _setError(result.error ?? 'حدث خطأ أثناء إرسال رابط التحقق');
    }

    _setLoading(false);
  }

  /// يُستدعى من شاشة انتظار التحقق — يُعيد تحميل حالة الإيميل
  /// يُرجع true إذا تأكد الإيميل
  Future<bool> reloadUser() async {
    final result = await _authService.reloadUser();
    final verified = result.data ?? false;

    if (verified && _currentUser != null) {
      // ✅ نرفع الـ flag قبل أي عملية لمنع _onAuthStateChanged من إطلاق onLogin مرة ثانية
      _isReloadingUser = true;
      try {
        _currentUser = _currentUser!.copyWith(isEmailVerified: true);
        _justRegistered = false;
        await _loadCurrentUser(_currentUser!.uid);
        // ✅ notifyListeners قبل onLogin لضمان أن الـ UI يرى الـ state الجديد أولاً
        notifyListeners();
        onLogin?.call();  // onLogin يُطلق مرة واحدة فقط من هنا
      } finally {
        _isReloadingUser = false;
      }
    }
    return verified;
  }

  /// يُستدعى بعد انتهاء شاشة انتظار التحقق (skip أو تأكيد)
  void completeRegistration() {
    _justRegistered = false;
    final uid = _authService.currentUserId;
    if (uid != null) {
      _loadCurrentUser(uid).then((_) {
        notifyListeners();
        onLogin?.call();
      });
    }
  }

  // ─── Update Display Name ──────────────────────────────────────────
  Future<bool> updateDisplayName({
    required String newName,
    required String currentPassword,
  }) async {
    _setLoading(true);
    _clearMessages();

    final user = _authService.currentFirebaseUser;
    if (user == null || user.email == null) {
      _setError('يجب تسجيل الدخول أولاً');
      _setLoading(false);
      return false;
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      _setError(e.code == 'wrong-password' || e.code == 'invalid-credential'
          ? 'كلمة المرور غير صحيحة'
          : 'فشل التحقق: ${e.message}');
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('حدث خطأ أثناء التحقق');
      _setLoading(false);
      return false;
    }

    final result = await _authService.updateUserProfile(name: newName.trim());

    if (result.isSuccessful) {
      _currentUser = result.data;
      _setSuccess('تم تحديث الاسم بنجاح');
      _setLoading(false);
      return true;
    } else {
      _setError(result.error ?? 'حدث خطأ أثناء تحديث الاسم');
      _setLoading(false);
      return false;
    }
  }

  // ─── Update Profile ───────────────────────────────────────────────
  Future<void> updateProfile({
    String? name,
    String? photoUrl,
    Map<String, dynamic>? profileData,
  }) async {
    _setLoading(true);
    _clearMessages();

    final result = await _authService.updateUserProfile(
      name: name,
      photoUrl: photoUrl,
      profileData: profileData,
    );

    if (result.isSuccessful) {
      _currentUser = result.data;
      _setSuccess('تم تحديث الملف الشخصي بنجاح');
    } else {
      _setError(result.error ?? 'حدث خطأ أثناء تحديث الملف الشخصي');
    }

    _setLoading(false);
  }

  // ─── Update Bio ───────────────────────────────────────────────────
  Future<void> updateBio(String bio) async {
    _setLoading(true);
    _clearMessages();

    final result = await _authService.updateBio(bio);

    if (result.isSuccessful) {
      _currentUser = result.data;
      _setSuccess('تم تحديث النبذة الشخصية بنجاح');
    } else {
      _setError(result.error ?? 'حدث خطأ أثناء تحديث النبذة');
    }

    _setLoading(false);
  }

  // ─── Load current user ────────────────────────────────────────────
  Future<void> loadCurrentUser({bool forceRefresh = false}) async {
    if ((_currentUser != null && !forceRefresh) || _isLoading) return;
    final uid = _authService.currentUserId;
    if (uid == null) return;
    await _loadCurrentUser(uid);
    notifyListeners();
  }

  // ─── Rate Limiting Helpers ────────────────────────────────────────
  bool _checkRateLimit() {
    if (isRateLimited) {
      _setError('تم تجاوز عدد المحاولات. انتظر ${_rateLimitDelay.inSeconds} ثانية');
      return false;
    }
    return true;
  }

  void _resetRateLimit() => _failedAttempts = 0;
  void _incrementFailed() => _failedAttempts++;

  // ─── State Helpers ────────────────────────────────────────────────
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _successMessage = null;
    _isSuccess = false;
    notifyListeners();
  }

  void _setSuccess(String message) {
    _successMessage = message;
    _errorMessage = null;
    _isSuccess = true;
    notifyListeners();
  }

  void _clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    _isSuccess = false;
  }

  void clearError() {
    _clearMessages();
    notifyListeners();
  }
}