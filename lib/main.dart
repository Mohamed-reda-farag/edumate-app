import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'firebase_options.dart';

import 'controllers/auth_controller.dart';
import 'controllers/global_learning_state.dart';
import 'controllers/schedule_controller.dart';
import 'controllers/attendance_controller.dart';
import 'controllers/gamification_controller.dart';
import 'controllers/task_controller.dart';
import 'controllers/semester_controller.dart';
import 'controllers/notification_controller.dart';

import 'repositories/schedule_repository.dart';
import 'repositories/attendance_repository.dart';
import 'repositories/task_repository.dart';
import 'repositories/semester_repository.dart';
import 'repositories/notification_repository.dart';

import 'services/study_plan_service.dart';
import 'services/gamification_service.dart';
import 'services/task_sync_service.dart';
import 'services/fcm_service.dart';
import 'services/notification_service.dart';
import 'services/notification_scheduler_service.dart';
import 'services/notification_background_bridge.dart';

import 'models/notification_history_model.dart';

import 'router.dart';

// ══════════════════════════════════════════════════════════════════════════════
// Workmanager callbackDispatcher — يجب أن يبقى top-level function
// ══════════════════════════════════════════════════════════════════════════════

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    // ─ Daily Task Sync ────────────────────────────────────────────────────────
    if (taskName == kDailyTaskSyncTask) {
      try {
        debugPrint('[Workmanager] Running daily task sync...');
        await TaskSyncService.runBackgroundSync();
        debugPrint('[Workmanager] Daily task sync completed');
        return true;
      } catch (e) {
        debugPrint('[Workmanager] Daily task sync error: $e');
        return false;
      }
    }

    // ─ Notification Sync ─────────────────────────────────────────────────────
    if (taskName == kNotificationDailySyncTask) {
      try {
        debugPrint('[Workmanager] Running notification daily sync...');
        await NotificationSchedulerService.runBackgroundSync();
        debugPrint('[Workmanager] Notification daily sync completed');
        return true;
      } catch (e) {
        debugPrint('[Workmanager] Notification daily sync error: $e');
        return false;
      }
    }

    return false;
  });
}

// ══════════════════════════════════════════════════════════════════════════════
// main
// ══════════════════════════════════════════════════════════════════════════════

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    debugPrint('✅ Initializing App...');

    // 1. Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized');

    // 1b. FCM Background Handler
    await FcmService.registerBackgroundHandler();

    // 2. Hive
    final appDocumentDir = await getApplicationDocumentsDirectory();
    Hive.init(appDocumentDir.path);
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(NotificationHistoryItemAdapter());
    }

    // 2b. Workmanager
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
    debugPrint('✅ Workmanager initialized');

    // 3. SharedPreferences
    final prefs = await SharedPreferences.getInstance();

    // 4. Auth controller
    final authController = AuthController();

    // 5. Repositories
    final firestore = FirebaseFirestore.instance;

    final scheduleRepo = ScheduleRepository(
      firestore: firestore,
      prefs: prefs,
      getUserId: () => authController.currentUserId ?? '',
    );
    final attendanceRepo = AttendanceRepository(
      firestore: firestore,
      prefs: prefs,
      getUserId: () => authController.currentUserId ?? '',
    );
    final taskRepository = TaskRepository(
      firestore: firestore,
      getUserId: () => authController.currentUserId ?? '',
    );
    final semesterRepo = SemesterRepository(
      firestore: firestore,
      prefs: prefs,
      getUserId: () => authController.currentUserId ?? '',
    );

    // 6. Services
    const planService         = StudyPlanService();
    const gamificationService = GamificationService();

    // 7. Feature controllers
    final gamificationController = GamificationController(
      attendanceRepo: attendanceRepo,
    );

    // 8. GlobalLearningState
    final globalLearningState = GlobalLearningState();
    await globalLearningState.ensureInitialized();

    // 9. NotificationRepository + NotificationController
    // [NOTIF] يُنشأ قبل SemesterController و TaskController لأنهما يحتاجانه
    final notificationRepository = NotificationRepository(
      firestore: firestore,
      getUserId: () => authController.currentUserId ?? '',
    );

    final notificationController = NotificationController(
      notificationRepository: notificationRepository,
      learningState: globalLearningState,
      getUserId: () => authController.currentUserId ?? '',
    );

    // ربط callback إشعار "غياب عن الكورس" بعد إنشاء notificationController
    globalLearningState.onCourseAccessedCallback = ({
      required String courseId,
      required String courseTitle,
      required String skillName,
    }) => notificationController.onCourseAccessed(
      courseId: courseId,
      courseTitle: courseTitle,
      skillName: skillName,
    );

    // 10. SemesterController
    final semesterController = SemesterController(
      semesterRepo: semesterRepo,
      scheduleRepo: scheduleRepo,
      attendanceRepo: attendanceRepo,
      notificationController: notificationController,
    );

    final scheduleController = ScheduleController(
      scheduleRepo: scheduleRepo,
      attendanceRepo: attendanceRepo,
      planService: planService,
      semesterController: semesterController,
      getUserId: () => authController.currentUserId ?? '',
    );

    final attendanceController = AttendanceController(
      attendanceRepo: attendanceRepo,
      scheduleRepo: scheduleRepo,
      gamificationService: gamificationService,
      semesterController: semesterController,
    );

    // 11. TaskSyncService
    final taskSyncService = TaskSyncService(
      getUserId: () => authController.currentUserId ?? '',
      taskRepository: taskRepository,
      scheduleController: scheduleController,
      learningState: globalLearningState,
    );

    // 12. TaskController
    final taskController = TaskController(
      getUserId: () => authController.currentUserId ?? '',
      taskRepository: taskRepository,
      syncService: taskSyncService,
      attendanceController: attendanceController,
      learningState: globalLearningState,
      notificationController: notificationController,
    );

    globalLearningState.onCourseProgressChangedCallback = () => 
        taskController.syncAllCourseTasks();

    scheduleController.onScheduleChanged = () async {
      // 1. مزامنة المهام الدراسية (محاضرات + جلسات)
      await taskController.forceDailySync();
      await taskController.syncAllCourseTasks();
    };

    scheduleController.onStudyPlanMissing = () =>
        notificationController.onStudyPlanMissing();

    // ══════════════════════════════════════════════════════════════════════════
    // 13. Login / Logout callbacks
    // ══════════════════════════════════════════════════════════════════════════

    VoidCallback? achievementListener;
    VoidCallback? levelUpListener;
    int lastKnownLevel = 0;

    VoidCallback? notifyLoginComplete;

    // ── دوال مساعدة لتقسيم منطق onLogin ─────────────────────────────────────

    Future<void> initControllers() async {
      await semesterController.init();
      await scheduleController.init();
      await attendanceController.init();
      await gamificationController.init();
    }

    Future<void> syncUserProfile(String uid) async {
      await globalLearningState.loadUserProfile(uid);

      try {
        if (globalLearningState.hasUserProfile) {
          await prefs.setBool('survey_completed', true);
          debugPrint('✅ survey_completed synced from loaded profile');
        }
      } catch (e) {
        debugPrint('⚠️ Could not sync survey status: $e');
      }
    }

    Future<void> initTaskController() async {
      await taskController.init();
    }

    Future<void> initNotifications(String uid) async {
      await FcmService.instance.initialize(userId: uid);
      await notificationController.initialize();
      await prefs.setString('bg_sync_user_id', uid);
      await TaskSyncService.registerDailySync();

      final activeCourses = globalLearningState.hasUserProfile
          ? globalLearningState.getActiveCourses()
          : <CourseProgress>[];

      await NotificationBackgroundBridge.saveUserData(
        userId: uid,
        settings: notificationController.settings,
        activeCourseIds: activeCourses.map((c) => c.courseId).toList(),
        courseLastAccess: {
          for (final c in activeCourses) c.courseId: c.lastAccessedAt,
        },
        currentStreak: gamificationController.data?.currentStreak ?? 0,
        preferredTimes: notificationController.settings.toPreferredTimesMap(),
      );

      if (!globalLearningState.hasUserProfile) {
        debugPrint(
          '[main] onLogin: profile not loaded yet — '
          'bridge saved without course data',
        );
      }

      await NotificationSchedulerService.registerDailySync();
    }

    void setupListeners() {
      // تحديث streak الأولي
      lastKnownLevel = gamificationController.data?.level ?? 0;
      notificationController.updateStreak(
        gamificationController.data?.currentStreak ?? 0,
      );

      // listener للإنجازات
      achievementListener = () {
        for (final achievement in gamificationController.newlyUnlocked) {
          notificationController.onAchievementUnlocked(achievement);
        }
        if (gamificationController.newlyUnlocked.isNotEmpty) {
          gamificationController.clearNewlyUnlocked();
        }
      };
      gamificationController.removeListener(achievementListener!);
      gamificationController.addListener(achievementListener!);

      // listener للمستوى والـ streak
      levelUpListener = () {
        final newLevel = gamificationController.data?.level ?? 0;
        if (newLevel > lastKnownLevel && lastKnownLevel > 0) {
          notificationController.onLevelUp(newLevel);
        }
        if (newLevel > 0) lastKnownLevel = newLevel;

        final streak = gamificationController.data?.currentStreak ?? 0;
        notificationController.updateStreak(streak);
      };
      gamificationController.removeListener(levelUpListener!);
      gamificationController.addListener(levelUpListener!);

      NotificationService.instance.onNotificationTapped =
          AppNavigation.handleNotificationTap;
    }

    // ── onLogin callback ──────────────────────────────────────────────────────
    authController.onLogin = () async {
      try {
        // 1. تهيئة controllers الأساسية (بدون TaskController)
        await initControllers();

        final uid = authController.currentUserId ?? '';
        if (uid.isNotEmpty) {
          // 2. تحميل بروفايل المستخدم أولاً — يملأ allFields في GlobalLearningState
          await syncUserProfile(uid);

          // 3. الآن نُهيئ TaskController — syncCourseTasks ستجد allFields جاهزة
          await initTaskController();

          // 4. الإشعارات
          await initNotifications(uid);
        } else {
          // uid فارغ — نُهيئ TaskController على أي حال بدون course sync
          await initTaskController();
        }

        setupListeners();
        notifyLoginComplete?.call();
      } catch (e) {
        debugPrint('❌ onLogin error: $e');
        notifyLoginComplete?.call();
      }
    };

    authController.onLogout = () async {
      final logoutUid = authController.currentUserId ?? '';

      // ── إزالة Achievement و LevelUp listeners ──────────────────────────
      if (achievementListener != null) {
        gamificationController.removeListener(achievementListener!);
        achievementListener = null;
      }
      if (levelUpListener != null) {
        gamificationController.removeListener(levelUpListener!);
        levelUpListener = null;
      }
      lastKnownLevel = 0;

      await taskController.reset();
      await scheduleController.reset();
      await attendanceController.reset();
      await gamificationController.reset();
      await semesterController.reset();
      // [FIX] الدالة الصحيحة هي signOut() وليس reset() — كانت compile error
      await globalLearningState.signOut();

      await TaskSyncService.cancelDailySync();
      await prefs.remove('bg_sync_user_id');
      await prefs.remove('bg_sync_requested_at');
      await prefs.remove('survey_completed');
      debugPrint('🗑️ survey_completed cleared on logout');

      await FcmService.instance.reset(userId: logoutUid);
      await NotificationSchedulerService.cancelDailySync();
      await NotificationBackgroundBridge.clear();
      await notificationController.reset();
    };

    debugPrint('✅ All services initialized');

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<GlobalLearningState>.value(
              value: globalLearningState),
          ChangeNotifierProvider.value(value: authController),
          ChangeNotifierProvider<ScheduleController>.value(
              value: scheduleController),
          ChangeNotifierProvider<AttendanceController>.value(
              value: attendanceController),
          ChangeNotifierProvider<GamificationController>.value(
              value: gamificationController),
          ChangeNotifierProvider<SemesterController>.value(
              value: semesterController),
          ChangeNotifierProvider<TaskController>.value(value: taskController),
          ChangeNotifierProvider<NotificationController>.value(
              value: notificationController),
        ],
        child: MyApp(
          prefs: prefs,
          onRegisterLoginComplete: (cb) => notifyLoginComplete = cb,
        ),
      ),
    );

    debugPrint('✅ App Launched');
  } catch (e, stack) {
    debugPrint('❌ Startup Error: $e');
    debugPrint('Stack trace: $stack');

    runApp(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: const Text('خطأ في التهيئة'),
            backgroundColor: Colors.red,
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'تعذّر تشغيل التطبيق',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'الخطأ: ${e.toString()}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: main,
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// MyApp
// ══════════════════════════════════════════════════════════════════════════════

class MyApp extends StatefulWidget {
  final SharedPreferences prefs;
  /// callback يُستدعى من main عند اكتمال onLogin
  final void Function(VoidCallback notifyComplete) onRegisterLoginComplete;

  const MyApp({
    super.key,
    required this.prefs,
    required this.onRegisterLoginComplete,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  GoRouter?             _router;
  GoRouterAuthNotifier? _goRouterNotifier;
  AuthController?       _lastAuthController;
  SemesterController?   _lastSemesterController;

  @override
  void initState() {
    super.initState();
    widget.onRegisterLoginComplete(() {
      _goRouterNotifier?.onLoginComplete();
    });
  }

  @override
  void dispose() {
    _goRouterNotifier?.dispose();
    super.dispose();
  }

  GoRouter _buildRouter(
    AuthController authController,
    SemesterController semesterController,
  ) {
    if (_router != null &&
        _lastAuthController == authController &&
        _lastSemesterController == semesterController) {
      return _router!;
    }
    _goRouterNotifier?.dispose();

    final globalLearningState = context.read<GlobalLearningState>();

    _goRouterNotifier = GoRouterAuthNotifier(
      authController,
      semesterController,
      widget.prefs,
      globalLearningState,
    );
    _lastAuthController = authController;
    _lastSemesterController = semesterController;
    _router = createAppRouter(_goRouterNotifier!);
    return _router!;
  }

  @override
  Widget build(BuildContext context) {
    final authController     = context.watch<AuthController>();
    final semesterController = context.watch<SemesterController>();
    final router = _buildRouter(authController, semesterController);

    return MaterialApp.router(
      title: 'مسار التعلم',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Cairo',
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Cairo',
      ),

      routerConfig: router,

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      locale: const Locale('ar', 'EG'),
      supportedLocales: const [
        Locale('ar', 'EG'),
        Locale('en', 'US'),
      ],

      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox(),
        );
      },
    );
  }
}