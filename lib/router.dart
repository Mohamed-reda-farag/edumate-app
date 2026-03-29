// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:convert';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'controllers/auth_controller.dart';
import 'controllers/semester_controller.dart';
import 'controllers/cv_controller.dart';
import 'controllers/global_learning_state.dart';

// ── authentication ──────────────────────────────────────────────────────────
import 'views/auth/login_screen.dart';
import 'views/auth/signup_screen.dart';
import 'views/auth/email_verification_screen.dart';

// ── dashboard ────────────────────────────────────────────────────────
import 'views/dashboard/splash_screen.dart';
import 'views/dashboard/main_scaffold.dart';
import 'views/dashboard/home_screen.dart';

// ── Profile ────────────────────────────────────────────────────────
import 'views/profile/profile_screen.dart';

// ── Tasks ──────────────────────────────────────────────────────────
import 'views/tasks/tasks_screen.dart';
import 'views/tasks/custom_task_details_screen.dart';
import 'views/tasks/add_custom_task_screen.dart';

// ── Skills ─────────────────────────────────────────────────────────
import 'views/skills/fields_hub_screen.dart';
import 'views/skills/active_skills_screen.dart';
import 'views/skills/learned_skills_screen.dart';
import 'views/skills/active_courses_screen.dart';
import 'views/skills/completed_courses_screen.dart';
import 'views/skills/field_details_screen.dart';
import 'views/skills/roadmap_screen.dart';
import 'views/skills/skill_details_screen.dart';
import 'views/skills/course_details_screen.dart';

// ── Survey ──────────────────────────────────────────────────────────
import 'views/skills/survey/welcome_screen.dart';
import 'views/skills/survey/survey_screen.dart';
import 'views/skills/survey/processing_screen.dart';

// ── Schedule ───────────────────────────────────────────────────────
import 'views/schedule/schedule_screen.dart';
import 'views/schedule/edit_schedule_screen.dart';
import 'views/schedule/subject_detail_screen.dart';
import 'views/schedule/smart_plan_screen.dart';
import 'views/schedule/analytics_screen.dart';
import 'views/schedule/achievements_screen.dart';
import 'views/schedule/semester_setup_screen.dart';
import 'views/schedule/subjects_setup_screen.dart';
import 'views/schedule/time_slots_editor_screen.dart';
import 'views/schedule/gpa_screen.dart';
import 'views/schedule/subject_management_screen.dart';

// ── Notifications ──────────────────────────────────────────────────
import 'views/notifications/notification_settings_screen.dart';
import 'views/notifications/notification_history_screen.dart';

// ── CV Builder ─────────────────────────────────────────────────────
import 'views/cv/cv_builder_screen.dart';

import 'models/subject_model.dart';
import 'models/task_model.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// ============================================
// Auth Notifier
// ============================================
class GoRouterAuthNotifier extends ChangeNotifier {
  final AuthController authController;
  final SemesterController semesterController;
  final GlobalLearningState globalLearningState;
  final SharedPreferences prefs;

  /// true أثناء فترة تسجيل الدخول وتحميل البروفايل —
  /// يمنع الـ Router من إصدار redirect قبل اكتمال التحميل
  bool _isAuthTransitioning = false;
  bool get isAuthTransitioning => _isAuthTransitioning;

  GoRouterAuthNotifier(
    this.authController,
    this.semesterController,
    this.prefs,
    this.globalLearningState,
  ) {
    authController.addListener(_onAuthChanged);
    semesterController.addListener(_onSemesterChanged);
    globalLearningState.addListener(_onProfileChanged);
  }

  void _onAuthChanged() {
    final loggedIn = FirebaseAuth.instance.currentUser != null;
    if (loggedIn) {
      // بدأ تسجيل الدخول — أدخل وضع الانتقال لمنع redirect مبكر
      if (!_isAuthTransitioning) {
        _isAuthTransitioning = true;
        debugPrint('🔄 Auth transitioning: login started');
      }
    } else {
      // تسجيل خروج — أنهِ وضع الانتقال فوراً
      _isAuthTransitioning = false;
    }
    notifyListeners();
  }

  bool _lastNeedsSetup = false;
  bool _lastIsLoading  = true;

  void _onSemesterChanged() {
    final ns = semesterController.needsSetup;
    final il = semesterController.isLoading;
    if (ns != _lastNeedsSetup || il != _lastIsLoading) {
      _lastNeedsSetup = ns;
      _lastIsLoading  = il;
      notifyListeners();
    }
  }

  /// يُطلق عند كل تغيير في GlobalLearningState
  /// أثناء الانتقال: لا نُطلق notifyListeners حتى لا يُقيّم الـ Router قبل حفظ prefs
  void _onProfileChanged() {
    if (!_isAuthTransitioning) {
      notifyListeners();
    }
  }

  /// يُستدعى من main.dart في نهاية onLogin callback
  void onLoginComplete() {
    if (_isAuthTransitioning) {
      _isAuthTransitioning = false;
      debugPrint('✅ Auth transition complete: onLogin callback done');
      notifyListeners();
    }
  }

  @override
  void dispose() {
    authController.removeListener(_onAuthChanged);
    semesterController.removeListener(_onSemesterChanged);
    globalLearningState.removeListener(_onProfileChanged);
    super.dispose();
  }

  bool get isLoggedIn {
    try {
      return FirebaseAuth.instance.currentUser != null;
    } catch (e) {
      debugPrint('Auth state check error: $e');
      return false;
    }
  }

  bool get needsSemesterSetup =>
      isLoggedIn &&
      semesterController.needsSetup &&
      !semesterController.isLoading;

  /// الاستبيان مكتمل إذا:
  /// 1. SharedPreferences يقول كذلك
  /// 2. أو GlobalLearningState لديه بروفايل محمّل
  bool get isSurveyCompleted {
    if (prefs.getBool('survey_completed') ?? false) return true;
    if (globalLearningState.hasUserProfile) {
      prefs.setBool('survey_completed', true);
      return true;
    }
    return false;
  }
}

// ============================================
// Error Page Widget
// ============================================
class ErrorPage extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorPage({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('خطأ'), backgroundColor: Colors.red),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: onRetry,
                  child: const Text('إعادة المحاولة'),
                ),
              ],
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.go('/home'),
                child: const Text('العودة للرئيسية'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================
// Router Configuration
// ============================================
GoRouter createAppRouter(GoRouterAuthNotifier goRouterNotifier) {
  return GoRouter(
    initialLocation: '/splash',
    navigatorKey: navigatorKey,
    debugLogDiagnostics: kDebugMode,
    refreshListenable: goRouterNotifier,

    errorBuilder: (context, state) {
      return ErrorPage(
        message: 'الصفحة المطلوبة غير موجودة\n${state.error?.toString() ?? ''}',
        onRetry: () => context.go('/home'),
      );
    },

  
    redirect: (context, state) {
      final loggedIn = goRouterNotifier.isLoggedIn;
      final location = state.uri.path;

      debugPrint('Router redirect: location=$location, loggedIn=$loggedIn, transitioning=${goRouterNotifier.isAuthTransitioning}');

      // [FIX] splash تتحكم في نفسها — لا redirect منها أبداً
      if (location == '/splash') return null;

      // ── Public routes ────────────────────────────────────────────
      const publicRoutes = ['/login', '/signup', '/forgot-password'];
      if (publicRoutes.any((route) => location.startsWith(route))) {
        if (loggedIn && !goRouterNotifier.isAuthTransitioning) {
          return goRouterNotifier.isSurveyCompleted ? '/home' : '/welcome';
        }
        return null;
      }

      // ── غير مسجّل — اذهب للـ splash ────────────────────────────
      if (!loggedIn) return '/splash';

      // ── أثناء تسجيل الدخول وتحميل البروفايل — انتظر ────────────
      if (goRouterNotifier.isAuthTransitioning) {
        debugPrint('⏳ Auth transitioning, holding redirect...');
        const onboardingDuringTransition = ['/welcome', '/survey', '/processing'];
        if (onboardingDuringTransition.contains(location)) {
          debugPrint('⏳ Transitioning on onboarding route, holding on /login');
          return '/login';
        }
        return null;
      }

      // ── Survey check ─────────────────────────────────────────────
      const onboardingRoutes = ['/welcome', '/survey', '/processing'];
      final isOnOnboarding = onboardingRoutes.contains(location);

      if (!isOnOnboarding && !goRouterNotifier.isSurveyCompleted) {
        debugPrint('⚠️ Survey not completed, redirecting to /welcome');
        return '/welcome';
      }

      if (isOnOnboarding && goRouterNotifier.isSurveyCompleted) {
        debugPrint('✅ Survey completed, redirecting from onboarding to /home');
        return '/home';
      }

      if (location.startsWith('/login') ||
          location.startsWith('/signup')) {
        return '/home';
      }

      return null;
    },

    routes: [
      // ════════════════════════════════════════════════════════
      // Public Routes
      // ════════════════════════════════════════════════════════
      GoRoute(
        path: '/splash',
        pageBuilder:
            (context, state) =>
                MaterialPage(key: state.pageKey, child: const SplashScreen()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder:
            (context, state) =>
                MaterialPage(key: state.pageKey, child: const LoginScreen()),
      ),

      GoRoute(
        path: '/signup',
        pageBuilder:
            (context, state) =>
                MaterialPage(key: state.pageKey, child: const SignUpScreen()),
      ),

      GoRoute(
        path: '/forgot-password',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const ForgotPasswordScreen()),
      ),

      GoRoute(
        path: '/email-verification',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const EmailVerificationScreen()),
      ),

      // ════════════════════════════════════════════════════════
      // Survey Routes
      // ════════════════════════════════════════════════════════
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        pageBuilder:
            (context, state) =>
                MaterialPage(key: state.pageKey, child: const WelcomeScreen()),
      ),
      GoRoute(
        path: '/survey',
        name: 'survey',
        pageBuilder:
            (context, state) =>
                MaterialPage(key: state.pageKey, child: const SurveyScreen()),
      ),
      GoRoute(
        path: '/processing',
        name: 'processing',
        pageBuilder: (context, state) {
          final surveyData = state.extra as Map<String, dynamic>?;
          if (surveyData == null) {
            return const MaterialPage(
              child: ErrorPage(message: 'بيانات الاستبيان مفقودة'),
            );
          }
          return MaterialPage(
            key: state.pageKey,
            child: ProcessingScreen(surveyData: surveyData),
          );
        },
      ),

      // ════════════════════════════════════════════════════════
      // Main Shell Routes (with BottomNavigationBar)
      // ════════════════════════════════════════════════════════
      ShellRoute(
        builder: (context, state, child) {
          // الترتيب الجديد:
          // 0: الملف الشخصي | 1: الجدول | 2: الرئيسية | 3: المهام | 4: مجالاتي
          int currentIndex = 2; // home هو الافتراضي في المنتصف
          final location = state.uri.path;

          if (location.startsWith('/profile'))
            currentIndex = 0;
          else if (location.startsWith('/schedule'))
            currentIndex = 1;
          else if (location.startsWith('/home'))
            currentIndex = 2;
          else if (location.startsWith('/tasks'))
            currentIndex = 3;
          else if (location.startsWith('/fields-hub'))
            currentIndex = 4;

          return MainScaffold(currentIndex: currentIndex, child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder:
                (context, state) =>
                    MaterialPage(key: state.pageKey, child: const HomeScreen()),
          ),
          GoRoute(
            path: '/schedule',
            pageBuilder:
                (context, state) => MaterialPage(
                  key: state.pageKey,
                  child: const ScheduleScreen(),
                ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder:
                (context, state) => MaterialPage(
                  key: state.pageKey,
                  child: const ProfileScreen(),
                ),
          ),
          GoRoute(
            path: '/tasks',
            name: 'tasks',
            pageBuilder:
                (context, state) => MaterialPage(
                  key: state.pageKey,
                  child: const TasksScreen(),
                ),
          ),
          GoRoute(
            path: '/fields-hub',
            name: 'my-fields',
            pageBuilder: (context, state) {
              final tab = state.uri.queryParameters['tab'];
              return MaterialPage(
                key: state.pageKey,
                child: FieldsHubScreen(
                  initialTab: tab != null ? int.tryParse(tab) ?? 0 : 0,
                ),
              );
            },
          ),
        ],
      ),

      // ════════════════════════════════════════════════════════
      // Task Routes
      // ════════════════════════════════════════════════════════
      GoRoute(
        path: '/tasks/detail',
        name: 'task-detail',
        pageBuilder: (context, state) {
          final task = state.extra as TaskModel?;
          if (task == null) {
            return MaterialPage(
              key: state.pageKey,
              child: const ErrorPage(message: 'بيانات المهمة غير متوفرة'),
            );
          }
          return MaterialPage(
            key: state.pageKey,
            child: TaskDetailsScreen(task: task),
          );
        },
      ),

      GoRoute(
        path: '/tasks/add',
        name: 'add-custom-task',
        pageBuilder:
            (context, state) => MaterialPage(
              key: state.pageKey,
              child: const AddCustomTaskScreen(),
            ),
      ),

      // ════════════════════════════════════════════════════════
      // Schedule Routes
      // ════════════════════════════════════════════════════════
      GoRoute(
        path: '/subject-details',
        pageBuilder: (context, state) {
          try {
            // [FIX] استخدام Map<String, dynamic> بدل Map<String, String>
            final extra = state.extra as Map<String, dynamic>?;
            final subjectId   = extra?['subjectId']   as String? ?? '';
            final subjectName = extra?['subjectName']  as String? ?? '';
            if (subjectName.isEmpty) {
              return MaterialPage(
                key: state.pageKey,
                child: const ErrorPage(message: 'معلومات المادة غير متوفرة'),
              );
            }
            return MaterialPage(
              key: state.pageKey,
              child: SubjectDetailScreen(
                subjectId: subjectId,
                subjectName: subjectName,
              ),
            );
          } catch (e) {
            debugPrint('Error building subject-details route: $e');
            return MaterialPage(
              key: state.pageKey,
              child: const ErrorPage(message: 'حدث خطأ في تحميل تفاصيل المادة'),
            );
          }
        },
      ),

      GoRoute(
        path: '/schedule/plan',
        pageBuilder:
            (context, state) => MaterialPage(
              key: state.pageKey,
              child: const SmartPlanScreen(),
            ),
      ),

      GoRoute(
        path: '/schedule/edit',
        pageBuilder:
            (context, state) => MaterialPage(
              key: state.pageKey,
              child: const EditScheduleScreen(),
            ),
      ),

      GoRoute(
        path: '/schedule/analytics',
        pageBuilder:
            (context, state) => MaterialPage(
              key: state.pageKey,
              child: const AnalyticsScreen(),
            ),
      ),

      GoRoute(
        path: '/schedule/achievements',
        pageBuilder:
            (context, state) => MaterialPage(
              key: state.pageKey,
              child: const AchievementsScreen(),
            ),
      ),

      // ── تخصيص أوقات المحاضرات ────────────────────────────────────────────
      GoRoute(
        path: '/schedule/time-slots',
        name: 'time-slots-editor',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const TimeSlotsEditorScreen(),
        ),
      ),

      // ── حساب GPA ─────────────────────────────────────────────────────────
      GoRoute(
        path: '/schedule/gpa',
        name: 'gpa-calculator',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const GpaScreen(),
        ),
      ),

      // ── إدارة امتحانات الفصل ─────────────────────────────────────────────
      GoRoute(
        path: '/schedule/subjects',
        name: 'subject-management',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const SubjectManagementScreen(),
        ),
      ),

      // ── Subjects Setup (جديد) ─────────────────────────────────────────────
      // الشاشة الأولى في flow الفصل: إدخال المواد + الصعوبة
      // تستقبل: {'isSummer': bool}
      GoRoute(
        path: '/subjects-setup',
        name: 'subjects-setup',
        pageBuilder: (context, state) {
          final extra   = state.extra as Map<String, dynamic>?;
          final isSummer = extra?['isSummer'] as bool? ?? false;
          return MaterialPage(
            key: state.pageKey,
            child: SubjectsSetupScreen(isSummer: isSummer),
          );
        },
      ),

      // ── Semester Setup (محدَّث) ───────────────────────────────────────────
      // الشاشة الثانية في flow الفصل: مدة الفصل + الامتحانات + تهيئة التقدم
      // تستقبل: {'subjects': List<Subject>, 'isSummer': bool}
      GoRoute(
        path: '/semester-setup',
        name: 'semester-setup',
        pageBuilder: (context, state) {
          final extra    = state.extra as Map<String, dynamic>?;
          final subjects = (extra?['subjects'] as List?)
                  ?.whereType<Subject>()
                  .toList() ??
              [];
          final isSummer = extra?['isSummer'] as bool? ?? false;
          return MaterialPage(
            key: state.pageKey,
            child: SemesterSetupScreen(
              subjects: subjects,
              isSummer: isSummer,
            ),
          );
        },
      ),


      // ════════════════════════════════════════════════════════
      // Learning Routes
      // ════════════════════════════════════════════════════════
      GoRoute(
        path: '/field-details/:fieldId',
        pageBuilder: (context, state) {
          try {
            final fieldId = state.pathParameters['fieldId'];
            if (fieldId == null || fieldId.isEmpty) {
              return MaterialPage(
                key: state.pageKey,
                child: const ErrorPage(message: 'معرف المجال غير صحيح'),
              );
            }
            return MaterialPage(
              key: state.pageKey,
              child: FieldDetailsScreen(fieldId: fieldId),
            );
          } catch (e) {
            debugPrint('Error building field-details route: $e');
            return MaterialPage(
              key: state.pageKey,
              child: ErrorPage(
                message: 'حدث خطأ في تحميل المجال',
                onRetry: () => context.go('/fields-hub?tab=0'),
              ),
            );
          }
        },
      ),

      GoRoute(
        path: '/roadmap/:fieldId',
        pageBuilder: (context, state) {
          try {
            final fieldId = state.pathParameters['fieldId'];
            if (fieldId == null || fieldId.isEmpty) {
              return MaterialPage(
                key: state.pageKey,
                child: const ErrorPage(message: 'معرف المجال غير صحيح'),
              );
            }
            return CustomTransitionPage(
              key: state.pageKey,
              child: RoadmapScreen(fieldId: fieldId),
              transitionsBuilder: (context, animation, secondary, child) {
                return FadeTransition(
                  opacity: CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOut,
                  ),
                  child: child,
                );
              },
            );
          } catch (e) {
            debugPrint('Error building roadmap route: $e');
            return MaterialPage(
              key: state.pageKey,
              child: const ErrorPage(message: 'حدث خطأ في تحميل خريطة التعلم'),
            );
          }
        },
      ),

      GoRoute(
        path: '/skill-details/:fieldId/:skillId',
        pageBuilder: (context, state) {
          try {
            final fieldId = state.pathParameters['fieldId'];
            final skillId = state.pathParameters['skillId'];
            if (fieldId == null ||
                fieldId.isEmpty ||
                skillId == null ||
                skillId.isEmpty) {
              return MaterialPage(
                key: state.pageKey,
                child: const ErrorPage(message: 'معرف المهارة غير صحيح'),
              );
            }
            return MaterialPage(
              key: state.pageKey,
              child: SkillDetailsScreen(fieldId: fieldId, skillId: skillId),
            );
          } catch (e) {
            debugPrint('Error building skill-details route: $e');
            return MaterialPage(
              key: state.pageKey,
              child: const ErrorPage(message: 'حدث خطأ في تحميل المهارة'),
            );
          }
        },
      ),

      GoRoute(
        path: '/course-details/:fieldId/:skillId/:courseId',
        pageBuilder: (context, state) {
          try {
            final fieldId = state.pathParameters['fieldId'];
            final skillId = state.pathParameters['skillId'];
            final courseId = state.pathParameters['courseId'];
            if (fieldId == null ||
                fieldId.isEmpty ||
                skillId == null ||
                skillId.isEmpty ||
                courseId == null ||
                courseId.isEmpty) {
              return MaterialPage(
                key: state.pageKey,
                child: const ErrorPage(message: 'معرف الكورس غير صحيح'),
              );
            }
            return MaterialPage(
              key: state.pageKey,
              child: CourseDetailsScreen(
                fieldId: fieldId,
                skillId: skillId,
                courseId: courseId,
              ),
            );
          } catch (e) {
            debugPrint('Error building course-details route: $e');
            return MaterialPage(
              key: state.pageKey,
              child: const ErrorPage(message: 'حدث خطأ في تحميل الكورس'),
            );
          }
        },
      ),

      // ════════════════════════════════════════════════════════
      // Tracking Routes
      // ════════════════════════════════════════════════════════
      GoRoute(
        path: '/active-skills',
        name: 'active-skills',
        pageBuilder:
            (context, state) => MaterialPage(
              key: state.pageKey,
              child: const ActiveSkillsScreen(),
            ),
      ),

      GoRoute(
        path: '/learned-skills',
        name: 'learned-skills',
        pageBuilder:
            (context, state) => MaterialPage(
              key: state.pageKey,
              child: const LearnedSkillsScreen(),
            ),
      ),

      GoRoute(
        path: '/active-courses',
        name: 'active-courses',
        pageBuilder:
            (context, state) => MaterialPage(
              key: state.pageKey,
              child: const ActiveCoursesScreen(),
            ),
      ),

      GoRoute(
        path: '/completed-courses',
        name: 'completed-courses',
        pageBuilder:
            (context, state) => MaterialPage(
              key: state.pageKey,
              child: const CompletedCoursesScreen(),
            ),
      ),

      // ════════════════════════════════════════════════════════
      // Notification Routes
      // ════════════════════════════════════════════════════════
      GoRoute(
        path: '/notifications/settings',
        name: 'notification-settings',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const NotificationSettingsScreen(),
        ),
      ),
      GoRoute(
        path: '/notifications/history',
        name: 'notification-history',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const NotificationHistoryScreen(),
        ),
      ),

      // ════════════════════════════════════════════════════════
      // CV Builder Route
      // ════════════════════════════════════════════════════════
      GoRoute(
        path: '/cv-builder',
        name: 'cv-builder',
        pageBuilder: (context, state) {
          // تهيئة CVController وحقن userId قبل فتح الشاشة
          final uid = state.extra as String? ?? '';
          if (uid.isEmpty) {
            return MaterialPage(
              key: state.pageKey,
              child: const ErrorPage(message: 'معرّف المستخدم غير متوفر'),
            );
          }
          // تسجيل الـ controller إذا لم يكن موجوداً
          if (!Get.isRegistered<CVController>()) {
            Get.put(CVController());
          }
          // حقن uid وتحميل البيانات
          Get.find<CVController>().init(uid);
          return MaterialPage(
            key: state.pageKey,
            child: const CVBuilderScreen(),
          );
        },
      ),

      // Fallback
      GoRoute(
        path: '/404',
        pageBuilder:
            (context, state) => MaterialPage(
              key: state.pageKey,
              child: const ErrorPage(message: 'الصفحة المطلوبة غير موجودة'),
            ),
      ),
    ],
  );
}

// ============================================
// Router Extensions
// ============================================
extension AppRouterExtension on GoRouter {
  void safeGo(String location, {Object? extra}) {
    try {
      go(location, extra: extra);
    } catch (e) {
      debugPrint('Navigation error: $e');
      go('/home');
    }
  }

  void safePush(String location, {Object? extra}) {
    try {
      push(location, extra: extra);
    } catch (e) {
      debugPrint('Navigation error: $e');
      go('/home');
    }
  }
}

// ============================================
// AppNavigation Helper
// ============================================
class AppNavigation {
  static GoRouter get router {
    final context = navigatorKey.currentContext;
    if (context != null) {
      return GoRouter.of(context);
    }
    throw Exception('Navigation context not available');
  }

  // ── Basic ──────────────────────────────────────────────────────

  static void goToHome() {
    try {
      router.safeGo('/home');
    } catch (e) {
      debugPrint('Navigation to home failed: $e');
    }
  }

  static void goToTasks() {
    try {
      router.safeGo('/tasks');
    } catch (e) {
      debugPrint('Navigation to tasks failed: $e');
    }
  }

  static void goToProfile() {
    try {
      router.safeGo('/profile');
    } catch (e) {
      debugPrint('Navigation to profile failed: $e');
    }
  }

  static void goToSchedule() {
    try {
      router.safeGo('/schedule');
    } catch (e) {
      debugPrint('Navigation to schedule failed: $e');
    }
  }

  @Deprecated(
    'استخدم goToSubjectsSetup() بدلاً منها. '
    'سيتم حذف هذه الدالة في الإصدار القادم.',
  )
  static void goToSemesterSetup() {
    debugPrint('[AppNavigation] goToSemesterSetup() deprecated — use goToSubjectsSetup()');
    goToSubjectsSetup();
  }

  /// الانتقال لشاشة إدخال المواد (بداية flow الفصل الجديد)
  static void goToSubjectsSetup({bool isSummer = false}) {
    try {
      router.safePush('/subjects-setup', extra: {'isSummer': isSummer});
    } catch (e) {
      debugPrint('Navigation to subjects-setup failed: $e');
    }
  }

  static void goToTimeSlotsEditor() {
    try {
      router.safePush('/schedule/time-slots');
    } catch (e) {
      debugPrint('Navigation to time-slots-editor failed: $e');
    }
  }

  static void goToGpaCalculator() {
    try {
      router.safePush('/schedule/gpa');
    } catch (e) {
      debugPrint('Navigation to gpa-calculator failed: $e');
    }
  }

  static void goToAnalytics() {
    try {
      router.safePush('/schedule/analytics');
    } catch (e) {
      debugPrint('Navigation to analytics failed: $e');
    }
  }

  static void goToAchievements() {
    try {
      router.safePush('/schedule/achievements');
    } catch (e) {
      debugPrint('Navigation to achievements failed: $e');
    }
  }

  static void goToSubjectDetail(String subjectId, String subjectName) {
    try {
      router.safePush(
        '/subject-details',
        extra: {'subjectId': subjectId, 'subjectName': subjectName},
      );
    } catch (e) {
      debugPrint('Navigation to subject-detail failed: $e');
    }
  }

  // ── Tasks ──────────────────────────────────────────────────────

  static void goToTasksScreen() {
    try {
      router.safeGo('/tasks');
    } catch (e) {
      debugPrint('Navigation to tasks failed: $e');
    }
  }

  static void goToTaskDetail(BuildContext context, TaskModel task) {
    try {
      context.push('/tasks/detail', extra: task);
    } catch (e) {
      debugPrint('Navigation to task-detail failed: $e');
    }
  }

  static void goToAddCustomTask(BuildContext context) {
    try {
      context.push('/tasks/add');
    } catch (e) {
      debugPrint('Navigation to add-custom-task failed: $e');
    }
  }

  // ── Learning ───────────────────────────────────────────────────

  static void toFieldsHub(BuildContext context, {int tab = 0}) {
    try {
      router.go('/fields-hub?tab=$tab');
    } catch (e) {
      debugPrint('Navigation to fields-hub failed: $e');
    }
  }

  static void goToMyFields() {
    try {
      router.go('/fields-hub?tab=0');
    } catch (e) {
      debugPrint('Navigation to my-fields failed: $e');
    }
  }

  static void goToFieldDetails(String fieldId) {
    try {
      router.safePush('/field-details/$fieldId');
    } catch (e) {
      debugPrint('Navigation to field-details failed: $e');
    }
  }

  static void goToRoadmap(String fieldId) {
    try {
      router.safePush('/roadmap/$fieldId');
    } catch (e) {
      debugPrint('Navigation to roadmap failed: $e');
    }
  }

  static void goToSkillDetails(String fieldId, String skillId) {
    try {
      router.safePush('/skill-details/$fieldId/$skillId');
    } catch (e) {
      debugPrint('Navigation to skill-details failed: $e');
    }
  }

  static void goToCourseDetails(
    String fieldId,
    String skillId,
    String courseId,
  ) {
    try {
      router.safePush('/course-details/$fieldId/$skillId/$courseId');
    } catch (e) {
      debugPrint('Navigation to course-details failed: $e');
    }
  }

  static void goToActiveSkills() {
    try {
      router.go('/fields-hub?tab=1');
    } catch (e) {
      debugPrint('Navigation to active-skills failed: $e');
    }
  }

  static void goToActiveCourses() {
    try {
      router.go('/fields-hub?tab=2');
    } catch (e) {
      debugPrint('Navigation to active-courses failed: $e');
    }
  }

  static void goToLearnedSkills() {
    try {
      router.safePush('/learned-skills');
    } catch (e) {
      debugPrint('Navigation to learned-skills failed: $e');
    }
  }

  static void goToCompletedCourses() {
    try {
      router.safePush('/completed-courses');
    } catch (e) {
      debugPrint('Navigation to completed-courses failed: $e');
    }
  }

  // ── Notifications ──────────────────────────────────────────────

  static void goToNotificationSettings() {
    try {
      router.safePush('/notifications/settings');
    } catch (e) {
      debugPrint('Navigation to notification-settings failed: $e');
    }
  }

  static void goToNotificationHistory() {
    try {
      router.safePush('/notifications/history');
    } catch (e) {
      debugPrint('Navigation to notification-history failed: $e');
    }
  }

  // ── CV Builder ─────────────────────────────────────────────────
  /// يُستدعى من ProfileScreen — يمرر uid للـ route
  static void goToCVBuilder(String uid) {
    try {
      router.safePush('/cv-builder', extra: uid);
    } catch (e) {
      debugPrint('Navigation to cv-builder failed: $e');
    }
  }

  /// يُستدعى من main.dart عند ضغط المستخدم على أي إشعار
  /// payload مثال: {"type": "lecture_before", "taskId": "lec_xyz_2024-01-01"}
  static void handleNotificationTap(String? payload) {
    if (payload == null || payload.isEmpty) {
      goToHome();
      return;
    }

    try {
      // تحليل الـ payload
      final Map<String, dynamic> data =
          Map<String, dynamic>.from(_parsePayload(payload));
      final String type = data['type'] as String? ?? '';

      debugPrint('[Router] handleNotificationTap: type=$type');

      switch (type) {
        // ── إشعارات المهام → شاشة المهام
        case 'lecture_before':
        case 'lecture_start':
        case 'lecture_followup':
        case 'study_before':
        case 'study_start':
        case 'study_followup':
        case 'custom':
          router.safeGo('/tasks');
          break;

        // ── إشعارات الكورسات → شاشة الكورسات النشطة
        case 'course_reminder':
        case 'course_inactive':
          router.safeGo('/fields-hub?tab=2');
          break;

        // ── الإنجازات → شاشة الإنجازات
        case 'achievement':
          router.safePush('/schedule/achievements');
          break;

        // ── الملخصات → سجل الإشعارات
        case 'summary_morning':
        case 'summary_evening':
        case 'summary_weekly':
          router.safePush('/notifications/history');
          break;
        
        // ── تذكير خطة الدراسة → شاشة خطة الدراسة الذكية
        case 'study_plan_reminder':
          router.safePush('/schedule/plan');
          break;

        // ── افتراضي → الرئيسية
        default:
          goToHome();
      }
    } catch (e) {
      debugPrint('[Router] handleNotificationTap error: $e');
      goToHome();
    }
  }

  static Map<String, dynamic> _parsePayload(String payload) {
    try {
      if (payload.startsWith('{')) {
        final decoded = jsonDecode(payload);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      }
      return {};
    } catch (e) {
      debugPrint('[Router] _parsePayload error: $e');
      return {};
    }
  }

  static void goBack() {
    try {
      if (router.canPop()) {
        router.pop();
      } else {
        goToHome();
      }
    } catch (e) {
      debugPrint('Back navigation error: $e');
      goToHome();
    }
  }
}