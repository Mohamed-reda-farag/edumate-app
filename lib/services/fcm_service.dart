import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart' hide NotificationSettings;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'notification_service.dart';
import '../models/notification_history_model.dart';
import '../models/notification_settings_model.dart';

// ══════════════════════════════════════════════════════════════════════════════
// Background FCM Handler — top-level function (مطلوب لـ Firebase)
// ══════════════════════════════════════════════════════════════════════════════

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Background message: ${message.messageId}');
  // يمكن هنا عرض إشعار محلي إذا أراد الـ server إرسال data-only message
}

// ══════════════════════════════════════════════════════════════════════════════
// FcmService
// ══════════════════════════════════════════════════════════════════════════════

class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _initialized = false;
  // [FIX #1] تتبع userId الحالي لاكتشاف تبديل الحسابات
  String? _currentUserId;

  StreamSubscription<String>?       _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedAppSub;
  StreamSubscription<NotificationSettings>? _settingsSub;

  // [FIX #4] Callback لتسجيل الإشعارات الواردة في الـ history
  // يُضبط من NotificationController عند initialize()
  Future<void> Function({
    required String title,
    required String body,
    required NotificationCategory category,
    String? payload,
  })? onMessageReceivedForHistory;

  // ── Initialization ─────────────────────────────────────────────────────────

  /// يُستدعى مرة واحدة في main.dart قبل runApp
  static Future<void> registerBackgroundHandler() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  /// يُستدعى عند login لتهيئة FCM وحفظ token.
  ///
  /// [FIX #1] إذا استُدعي لمستخدم مختلف (تبديل حسابات)، يُعيد التهيئة
  /// بدلاً من التوقف عند الـ guard — يضمن صحة الـ subscriptions
  /// والـ token في جميع الأحوال.
  Future<void> initialize({required String userId}) async {
    // [FIX #1] Guard الصحيح: نفس المستخدم فقط يتخطى التهيئة
    if (_initialized && _currentUserId == userId) return;

    // [FIX #1] إذا كان مستخدم مختلف، ننظف القديم أولاً
    if (_initialized && _currentUserId != null && _currentUserId != userId) {
      debugPrint('[FCM] Different user detected — resetting before re-init');
      await reset(userId: _currentUserId!);
    }

    // طلب الإذن (iOS)
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // جلب الـ token وحفظه
    final token = await _messaging.getToken();
    if (token != null && userId.isNotEmpty) {
      await _saveTokenToFirestore(userId, token);
    }

    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = _messaging.onTokenRefresh.listen((newToken) {
      if (userId.isNotEmpty) {
        _saveTokenToFirestore(userId, newToken);
      }
    });

    await _onMessageSub?.cancel();
    _onMessageSub = FirebaseMessaging.onMessage.listen((message) {
      _handleForegroundMessage(message);
    });

    await _onMessageOpenedAppSub?.cancel();
    _onMessageOpenedAppSub =
        FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('[FCM] Opened from background: ${message.data}');
      // يمكن إضافة navigation هنا
    });

    await _settingsSub?.cancel();

    // التحقق من إشعار أُرسل بينما كان التطبيق مغلقاً
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('[FCM] App opened from terminated: ${initialMessage.data}');
    }

    // [FIX #1] نحفظ userId بعد نجاح التهيئة
    _currentUserId = userId;
    _initialized = true;
    debugPrint('[FCM] Initialized for user: $userId');
  }

  // ── Reset (logout) ─────────────────────────────────────────────────────────

  Future<void> reset({required String userId}) async {
    // إلغاء كل الـ subscriptions أولاً قبل أي عملية أخرى
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;

    await _onMessageSub?.cancel();
    _onMessageSub = null;

    await _onMessageOpenedAppSub?.cancel();
    _onMessageOpenedAppSub = null;

    await _settingsSub?.cancel();
    _settingsSub = null;

    _initialized = false;
    _currentUserId = null;

    onMessageReceivedForHistory = null;

    try {
      // حذف الـ token من Firestore عند الخروج
      if (userId.isNotEmpty) {
        await _firestore.collection('users').doc(userId).update({
          'deviceToken': FieldValue.delete(),
        });
      }
      await _messaging.deleteToken();
    } catch (e) {
      debugPrint('[FCM] reset error: $e');
    }
  }

  // ── Private Helpers ───────────────────────────────────────────────────────

  Future<void> _saveTokenToFirestore(String userId, String token) async {
    try {
      await _firestore.collection('users').doc(userId).set(
        {
          'deviceToken': token,
          'tokenUpdatedAt': Timestamp.fromDate(DateTime.now()),
        },
        SetOptions(merge: true),
      );
      debugPrint('[FCM] Token saved for $userId');
    } catch (e) {
      debugPrint('[FCM] _saveTokenToFirestore error: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[FCM] Foreground message: ${message.notification?.title}');

    final notification = message.notification;
    final data = message.data;

    final title = notification?.title ?? data['title'] ?? 'إشعار جديد';
    final body  = notification?.body  ?? data['body']  ?? '';
    final categoryStr = data['category'] ?? 'tasks';

    final category = NotificationCategory.values.firstWhere(
      (c) => c.name == categoryStr,
      orElse: () => NotificationCategory.tasks,
    );

    onMessageReceivedForHistory?.call(
      title: title,
      body: body,
      category: category,
      payload: data['payload'],
    );

    // عرض إشعار محلي فقط لـ data-only messages
    // (notification messages يعرضها النظام تلقائياً)
    if (notification == null && data.isNotEmpty) {
      final msgId = message.messageId ??
          DateTime.now().millisecondsSinceEpoch.toString();
      final id = NotificationIdHelper.toInt(msgId);

      NotificationService.instance.showNow(
        id: id,
        title: title,
        body: body,
        category: category,
        payload: data['payload'],
      );
    }
  }

  // ── Topic Subscription ────────────────────────────────────────────────────

  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('[FCM] Subscribed to: $topic');
    } catch (e) {
      debugPrint('[FCM] subscribeToTopic error: $e');
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('[FCM] Unsubscribed from: $topic');
    } catch (e) {
      debugPrint('[FCM] unsubscribeFromTopic error: $e');
    }
  }
}