import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../services/firebase_service.dart';
import '../models/field_model.dart';
import '../models/skill_model.dart';
import '../models/course_model.dart';

class GlobalLearningState extends ChangeNotifier {
  static final GlobalLearningState _instance = GlobalLearningState._internal();
  factory GlobalLearningState() => _instance;

  GlobalLearningState._internal() {
    _initAndNotify();
  }

  // Services
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Notification callback
  Future<void> Function({
    required String courseId,
    required String courseTitle,
    required String skillName,
  })? onCourseAccessedCallback;

  Future<void> Function()? onCourseProgressChangedCallback;

  String? _currentUserId;

  // Streams subscriptions
  StreamSubscription<DocumentSnapshot>? _userProfileSubscription;
  final Map<String, StreamSubscription<DocumentSnapshot>>
  _fieldProgressSubscriptions = {};
  final Map<String, StreamSubscription<FieldModel>> _fieldDataSubscriptions =
      {};

  // Loading states
  bool _isLoadingStaticData = false;
  bool _isLoadingUserProfile = false;
  bool _isInitialized = false;
  String? _lastError;
  String? _userProfileError;

  bool get isInitialized => _isInitialized;

  bool _pendingCourseCompletionChoice = false;
  bool get pendingCourseCompletionChoice => _pendingCourseCompletionChoice;

  void clearPendingCourseCompletionChoice() {
    _pendingCourseCompletionChoice = false;
  }

  // ═════════════════════════════════════════════════════════════════════════
  // البيانات الثابتة (Static Data) - من Firebase
  // ═════════════════════════════════════════════════════════════════════════

  final Map<String, FieldModel> _allFields = {};

  // ═════════════════════════════════════════════════════════════════════════
  // بيانات المستخدم (User Data)
  // ═════════════════════════════════════════════════════════════════════════

  UserLearningProfile? _userProfile;

  // ═════════════════════════════════════════════════════════════════════════
  // Getters
  // ═════════════════════════════════════════════════════════════════════════

  Map<String, FieldModel> get allFields => Map.unmodifiable(_allFields);
  UserLearningProfile? get userProfile => _userProfile;
  bool get hasUserProfile => _userProfile != null;
  bool get isLoadingStaticData => _isLoadingStaticData;
  bool get isLoadingUserProfile => _isLoadingUserProfile;
  String? get lastError => _lastError;
  String? get userProfileError => _userProfileError;
  String? get currentUserId => _currentUserId;
  String? get primaryField => _userProfile?.primaryFieldId;
  String? get secondaryField => _userProfile?.secondaryFieldId;

  List<String> get selectedFields {
    List<String> fields = [];
    if (_userProfile?.primaryFieldId != null) {
      fields.add(_userProfile!.primaryFieldId);
    }
    if (_userProfile?.secondaryFieldId != null) {
      fields.add(_userProfile!.secondaryFieldId!);
    }
    return fields;
  }

  FieldModel? getFieldData(String fieldId) => _allFields[fieldId];

  SkillModel? getSkillData(String fieldId, String skillId) {
    return _allFields[fieldId]?.skills[skillId];
  }

  CourseModel? getCourseData(String fieldId, String skillId, String courseId) {
    final skill = _allFields[fieldId]?.skills[skillId];
    if (skill == null) return null;

    try {
      return skill.courses.firstWhere((course) => course.id == courseId);
    } catch (e) {
      return null;
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // التهيئة (Initialization)
  // ═════════════════════════════════════════════════════════════════════════

  Future<void> _initAndNotify() async {
    await _initializeFirestore();
    notifyListeners();
  }

  /// يُستدعى من main() لضمان اكتمال التهيئة قبل runApp
  Future<void> ensureInitialized() async {
    if (_isInitialized) return;
    await _initializeFirestore();
  }

  Future<void> _initializeFirestore() async {
    try {
      await _firebaseService.initialize();
      _isInitialized = true;
      debugPrint('✅ GlobalLearningState initialized with Firebase');
    } catch (e) {
      debugPrint('❌ Error initializing GlobalLearningState: $e');
      _lastError = e.toString();
      _isInitialized = false;
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // تحميل البيانات الثابتة
  // ═════════════════════════════════════════════════════════════════════════

  /// تحميل جميع المجالات من Firebase.
  /// [forceRefresh] — يتجاهل الـ cache الصالح ويجلب الكل من Firestore.
  /// يُستخدم عندما يكون عدد المجالات المحملة أقل من المتوقع.
  Future<void> loadAllFields({bool forceRefresh = false}) async {
    if (_isLoadingStaticData) return;

    _isLoadingStaticData = true;
    _lastError = null;
    notifyListeners();

    try {
      debugPrint('📚 Loading all fields from Firebase (forceRefresh=$forceRefresh)...');

      final fields = await _firebaseService.getAllFields(forceRefresh: forceRefresh);
      _allFields.clear();
      _allFields.addAll(fields);

      debugPrint('✅ Loaded ${fields.length} fields successfully');
      _lastError = null;
    } catch (e) {
      debugPrint('❌ Error loading fields: $e');
      _lastError = 'فشل تحميل المجالات: ${e.toString()}';
    } finally {
      _isLoadingStaticData = false;
      notifyListeners();
    }
  }

  /// تحميل مجال واحد
  Future<void> loadField(String fieldId) async {
    try {
      debugPrint('📖 Loading field: $fieldId');

      final field = await _firebaseService.getField(fieldId);
      if (field != null) {
        _allFields[fieldId] = field;
        notifyListeners();
        debugPrint('✅ Field $fieldId loaded successfully');
      }
    } catch (e) {
      debugPrint('❌ Error loading field $fieldId: $e');
      _lastError = 'فشل تحميل المجال: ${e.toString()}';
      notifyListeners();
    }
  }

  /// تحميل مجالات محددة (Batch)
  Future<void> loadFieldsBatch(List<String> fieldIds) async {
    if (fieldIds.isEmpty) return;

    _isLoadingStaticData = true;
    notifyListeners();

    try {
      debugPrint('📚 Loading ${fieldIds.length} fields...');

      final fields = await _firebaseService.getFieldsBatch(fieldIds);
      _allFields.addAll(fields);

      debugPrint('✅ Loaded ${fields.length} fields');
    } catch (e) {
      debugPrint('❌ Error loading fields batch: $e');
      _lastError = e.toString();
    } finally {
      _isLoadingStaticData = false;
      notifyListeners();
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Streams للتحديثات الفورية
  // ═════════════════════════════════════════════════════════════════════════

  /// متابعة التحديثات على مجال معين
  void watchField(String fieldId) {
    // إلغاء الاشتراك القديم إن وجد
    _fieldDataSubscriptions[fieldId]?.cancel();

    // الاشتراك الجديد
    _fieldDataSubscriptions[fieldId] = _firebaseService
        .watchField(fieldId)
        .listen(
          (field) {
            _allFields[fieldId] = field;
            notifyListeners();
            debugPrint('🔄 Field $fieldId updated from stream');
          },
          onError: (error) {
            debugPrint('❌ Error in field stream $fieldId: $error');
          },
        );
  }

  /// إلغاء متابعة مجال
  void unwatchField(String fieldId) {
    _fieldDataSubscriptions[fieldId]?.cancel();
    _fieldDataSubscriptions.remove(fieldId);
  }

  // ═════════════════════════════════════════════════════════════════════════
  // إدارة بروفايل المستخدم
  // ═════════════════════════════════════════════════════════════════════════

  /// تحميل بروفايل المستخدم
  Future<void> loadUserProfile(String userId) async {
    if (_currentUserId == userId && _userProfile != null) {
      return; // Already loaded
    }

    // إذا كان المستخدم مختلفاً، نُنظف البيانات القديمة أولاً
    if (_currentUserId != null && _currentUserId != userId) {
      await _clearUserData();
    }

    _isLoadingUserProfile = true;
    _currentUserId = userId;
    notifyListeners();

    try {
      await _userProfileSubscription?.cancel();

      _userProfileSubscription = _firestore
          .collection('user_profiles')
          .doc(userId)
          .snapshots()
          .listen(
            (snapshot) {
              if (snapshot.exists && snapshot.data() != null) {
                _userProfile = UserLearningProfile.fromJson(
                  snapshot.data() as Map<String, dynamic>,
                );

                // تحميل المجالات المطلوبة
                final fieldsToLoad = selectedFields;
                if (fieldsToLoad.isNotEmpty) {
                  loadFieldsBatch(fieldsToLoad);
                }

                _isLoadingUserProfile = false;
                notifyListeners();
              } else {
                // مستخدم جديد — لا يوجد document بعد
                debugPrint('ℹ️ New user, no profile document yet');
                _isLoadingUserProfile = false;
                notifyListeners();
              }
            },
            onError: (error) {
              debugPrint('❌ Error loading user profile: $error');
              _userProfileError = error.toString();
              _lastError = error.toString();
              _isLoadingUserProfile = false;
              notifyListeners();
            },
          );
    } catch (e) {
      debugPrint('❌ Error setting up user profile: $e');
      _userProfileError = e.toString();
      _lastError = e.toString();
      _isLoadingUserProfile = false;
      notifyListeners();
    }
  }

  /// تنظيف بيانات المستخدم الحالي (عند تسجيل الخروج أو تبديل الحساب)
  Future<void> signOut() async {
    await _clearUserData();
  }

  /// اختصار لتحديث بيانات المستخدم الحالي — يُستخدم في onRefresh
  Future<void> refreshCurrentUser() async {
    if (_currentUserId != null) {
      await loadUserProfile(_currentUserId!);
    }
  }

  /// يُعلّم الكورس كمكتمل يدوياً — يُستخدم بعد نجاح الاختبار للمستخدم المتقدم
  Future<void> markCourseAsCompleted({
    required String fieldId,
    required String skillId,
    required String courseId,
  }) async {
    if (_userProfile == null || _currentUserId == null) return;

    final courseProgress = _userProfile!
        .fieldProgress[fieldId]
        ?.skillsProgress[skillId]
        ?.coursesProgress[courseId];

    if (courseProgress == null || courseProgress.isCompleted) return;

    final updatedCourse = CourseProgress(
      courseId: courseProgress.courseId,
      skillId: courseProgress.skillId,
      fieldId: courseProgress.fieldId,
      startedAt: courseProgress.startedAt,
      lastAccessedAt: DateTime.now(),
      currentLessonIndex: courseProgress.totalLessons,
      totalLessons: courseProgress.totalLessons,
      completedLessons:
          List.generate(courseProgress.totalLessons, (i) => i),
      isCompleted: true,
      completedAt: DateTime.now(),
      userRating: courseProgress.userRating,
      accessCount: courseProgress.accessCount,
      totalStudyMinutes: courseProgress.totalStudyMinutes,
    );

    _userProfile!.fieldProgress[fieldId]!
        .skillsProgress[skillId]!
        .coursesProgress[courseId] = updatedCourse;

    await _updateSkillProgress(fieldId, skillId);
    notifyListeners();

    await _firestore
        .collection('user_profiles')
        .doc(_currentUserId)
        .update({
      'fieldProgress.$fieldId.skillsProgress.$skillId'
          '.coursesProgress.$courseId':
          updatedCourse.toJson(),
    });
  }

  Future<void> _clearUserData() async {
    await _userProfileSubscription?.cancel();
    _userProfileSubscription = null;

    for (var sub in _fieldProgressSubscriptions.values) {
      await sub.cancel();
    }
    _fieldProgressSubscriptions.clear();

    for (var sub in _fieldDataSubscriptions.values) {
      await sub.cancel();
    }
    _fieldDataSubscriptions.clear();

    _userProfile = null;
    _currentUserId = null;
    _lastError = null;
    _userProfileError = null;

    // [FIX] مسح _allFields عند تسجيل الخروج —
    // كان يبقى محملاً بمجالات المستخدم السابق، فإذا سجّل مستخدم
    // ثانٍ دخوله يجد allFields.isNotEmpty == true فيُشغّل
    // syncCourseTasks بمجالات خاطئة قبل اكتمال loadUserProfile.
    _allFields.clear();

    notifyListeners();
    debugPrint('✅ User data cleared');
  }

  /// إنشاء بروفايل مستخدم جديد
  /// [preferences] — التفضيلات الكاملة من الاستبيان (تشمل skillLevels).
  /// تُمرَّر هنا لأن _userProfile لم يُعيَّن بعد عند استدعاء _initializeFieldProgress.
  Future<void> createUserProfile({
    required String userId,
    required String primaryFieldId,
    String? secondaryFieldId,
    Map<String, dynamic> preferences = const {},
  }) async {
    try {
      final docRef = _firestore.collection('user_profiles').doc(userId);

      // استخراج skillLevels من preferences لتمريرها لـ _initializeFieldProgress
      final skillLevels =
          preferences['skillLevels'] as Map<String, dynamic>? ?? {};

      // تحقق من وجود بروفايل سابق لتجنب مسح البيانات الموجودة
      final existingDoc = await docRef.get();
      if (existingDoc.exists) {
        debugPrint('ℹ️ Profile already exists, updating fields only');
        await docRef.update({
          'primaryFieldId': primaryFieldId,
          if (secondaryFieldId != null) 'secondaryFieldId': secondaryFieldId,
          if (preferences.isNotEmpty) 'preferences': preferences,
        });
        // تهيئة التقدم للمجالات الجديدة فقط إن لم تكن موجودة
        final data = existingDoc.data() as Map<String, dynamic>;
        final existingProgress =
            (data['fieldProgress'] as Map?)?.keys.toSet() ?? {};
        if (!existingProgress.contains(primaryFieldId)) {
          await _initializeFieldProgress(
            userId,
            primaryFieldId,
            skillLevels: skillLevels,
          );
        }
        if (secondaryFieldId != null &&
            !existingProgress.contains(secondaryFieldId)) {
          await _initializeFieldProgress(
            userId,
            secondaryFieldId,
            skillLevels: skillLevels,
          );
        }
        // إعادة تحميل البروفايل
        await loadUserProfile(userId);
        return;
      }

      // مستخدم جديد تماماً — إنشاء بروفايل من الصفر
      final profile = UserLearningProfile(
        userId: userId,
        primaryFieldId: primaryFieldId,
        secondaryFieldId: secondaryFieldId,
        createdAt: DateTime.now(),
        preferences: Map<String, dynamic>.from(preferences),
        fieldProgress: {},
      );

      // حفظ في Firestore
      await docRef.set(profile.toJson());

      // تعيين _userProfile قبل _initializeFieldProgress
      // حتى تجد الـ stream snapshot جاهزاً عند وصوله
      _userProfile = profile;
      _currentUserId = userId;

      // تهيئة التقدم للمجالات مع تمرير skillLevels صراحةً
      await _initializeFieldProgress(
        userId,
        primaryFieldId,
        skillLevels: skillLevels,
      );
      if (secondaryFieldId != null) {
        await _initializeFieldProgress(
          userId,
          secondaryFieldId,
          skillLevels: skillLevels,
        );
      }

      notifyListeners();
      debugPrint('✅ User profile created successfully');
    } catch (e) {
      debugPrint('❌ Error creating user profile: $e');
      _lastError = e.toString();
      rethrow;
    }
  }

  /// تهيئة التقدم لمجال معين
  /// [skillLevels] — مستويات المهارات المختارة من الاستبيان أو شاشة التعديل.
  /// يُمرَّر صراحةً بدلاً من قراءته من _userProfile لأن هذه الدالة قد تُستدعى
  /// قبل وصول أول snapshot من Firestore (وقبل تعيين _userProfile).
  Future<void> _initializeFieldProgress(
    String userId,
    String fieldId, {
    Map<String, dynamic> skillLevels = const {},
  }) async {
    try {
      // جلب بيانات المجال
      final field = await _firebaseService.getField(fieldId);
      if (field == null) return;

      final Map<String, SkillProgress> skillsProgress = {};

      for (final entry in field.skills.entries) {
        final userSkillLevel =
            skillLevels[entry.key] as String? ?? 'foundation';
        final defaults = _getLevelDefaults(userSkillLevel);

        skillsProgress[entry.key] = SkillProgress(
          skillId: entry.key,
          fieldId: fieldId,
          startedAt: DateTime.now(),
          currentLessonIndex: 0,
          progressPercentage: defaults.initialProgress,
          coursesProgress: {},
          initialProgress: defaults.initialProgress,
          effectiveRatio: defaults.effectiveRatio,
        );
      }

      final fieldProgress = UserFieldProgress(
        fieldId: fieldId,
        currentLevel: 'foundation',
        overallProgress: 0,
        startedAt: DateTime.now(),
        skillsProgress: skillsProgress,
      );

      // حفظ في Firestore
      await _firestore.collection('user_profiles').doc(userId).update({
        'fieldProgress.$fieldId': fieldProgress.toJson(),
      });

      debugPrint('✅ Field progress initialized for $fieldId');
    } catch (e) {
      debugPrint('❌ Error initializing field progress: $e');
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // تحديث التقدم (Progress Updates) مع Optimistic Updates
  // ═════════════════════════════════════════════════════════════════════════

  /// بدء كورس جديد أو تحديث آخر وصول لكورس موجود
  Future<void> startCourse({
    required String fieldId,
    required String skillId,
    required String courseId,
    int? totalLessons,
  }) async {
    if (_userProfile == null || _currentUserId == null) return;

    final fieldProgress = _userProfile!.fieldProgress[fieldId];
    if (fieldProgress == null) return;

    final skillProgress = fieldProgress.skillsProgress[skillId];
    if (skillProgress == null) return;

    // التحقق من وجود الكورس مسبقاً
    final existingCourse = skillProgress.coursesProgress[courseId];

    CourseProgress courseProgress;

    if (existingCourse != null) {
      // الكورس موجود - نحدث فقط lastAccessedAt
      courseProgress = CourseProgress(
        courseId: existingCourse.courseId,
        skillId: existingCourse.skillId,
        fieldId: existingCourse.fieldId,
        startedAt: existingCourse.startedAt,
        lastAccessedAt: DateTime.now(), // تحديث
        currentLessonIndex: existingCourse.currentLessonIndex,
        totalLessons: existingCourse.totalLessons,
        completedLessons: existingCourse.completedLessons,
        isCompleted: existingCourse.isCompleted,
        completedAt: existingCourse.completedAt,
        userRating: existingCourse.userRating,
        accessCount: existingCourse.accessCount + 1, // زيادة العداد
      );
    } else {
      // كورس جديد
      if (totalLessons == null) {
        debugPrint('❌ totalLessons required for new course');
        return;
      }

      courseProgress = CourseProgress(
        courseId: courseId,
        skillId: skillId,
        fieldId: fieldId,
        startedAt: DateTime.now(),
        lastAccessedAt: DateTime.now(),
        currentLessonIndex: 0,
        totalLessons: totalLessons,
        completedLessons: [],
        isCompleted: false,
      );
    }

    // Optimistic Update
    skillProgress.coursesProgress[courseId] = courseProgress;
    notifyListeners();

    // حفظ في Firebase
    try {
      await _firestore.collection('user_profiles').doc(_currentUserId).update({
        'fieldProgress.$fieldId.skillsProgress.$skillId.coursesProgress.$courseId':
            courseProgress.toJson(),
      });

      debugPrint(
        '✅ Course ${existingCourse != null ? "accessed" : "started"}: $courseId',
      );

      // جدولة إشعار "غياب عن الكورس" بعد 3 أيام
      final courseData = getCourseData(fieldId, skillId, courseId);
      final skillData  = getSkillData(fieldId, skillId);
      if (courseData != null && skillData != null) {
        onCourseAccessedCallback?.call(
          courseId:    courseId,
          courseTitle: courseData.title,
          skillName:   skillData.name,
        );
      }
    } catch (e) {
      debugPrint('❌ Error starting/accessing course: $e');
      onCourseProgressChangedCallback?.call().ignore();
      _lastError = e.toString();
    }
  }

  /// تحديث تقدم الكورس
  Future<void> updateCourseProgress({
    required String fieldId,
    required String skillId,
    required String courseId,
    required int lessonIndex,
  }) async {
    if (_userProfile == null || _currentUserId == null) return;

    final fieldProgress = _userProfile!.fieldProgress[fieldId];
    if (fieldProgress == null) return;

    final skillProgress = fieldProgress.skillsProgress[skillId];
    if (skillProgress == null) return;

    final courseProgress = skillProgress.coursesProgress[courseId];
    if (courseProgress == null) return;

    // Optimistic Update
    final newCompletedLessons = [
      ...courseProgress.completedLessons,
      if (!courseProgress.completedLessons.contains(lessonIndex)) lessonIndex,
    ];
    final isNowCompleted =
        newCompletedLessons.length >= courseProgress.totalLessons;

    // ✅ نحافظ على completedAt القديم إذا كان الكورس مكتملاً مسبقاً
    final newCompletedAt =
        courseProgress.isCompleted
            ? courseProgress.completedAt
            : isNowCompleted
            ? DateTime.now()
            : null;

    final updatedProgress = CourseProgress(
      courseId: courseProgress.courseId,
      skillId: courseProgress.skillId,
      fieldId: courseProgress.fieldId,
      startedAt: courseProgress.startedAt,
      lastAccessedAt: DateTime.now(),
      currentLessonIndex: lessonIndex,
      totalLessons: courseProgress.totalLessons,
      completedLessons: newCompletedLessons,
      isCompleted: courseProgress.isCompleted || isNowCompleted,
      completedAt: newCompletedAt,
      userRating: courseProgress.userRating,
      accessCount: courseProgress.accessCount,
    );

    skillProgress.coursesProgress[courseId] = updatedProgress;

    // تحديث تقدم المهارة
    await _updateSkillProgress(fieldId, skillId);

    notifyListeners();

    // حفظ في Firebase
    try {
      await _firestore.collection('user_profiles').doc(_currentUserId).update({
        'fieldProgress.$fieldId.skillsProgress.$skillId.coursesProgress.$courseId':
            updatedProgress.toJson(),
      });

      debugPrint('✅ Course progress updated: $courseId');
    } catch (e) {
      debugPrint('❌ Error updating course progress: $e');
      _lastError = e.toString();
    }
  }

  /// تحديث تقدم المهارة
  Future<void> _updateSkillProgress(
    String fieldId,
    String skillId, {
    WriteBatch? batch,
  }) async {
    final fieldProgress = _userProfile?.fieldProgress[fieldId];
    if (fieldProgress == null) return;
 
    final skillProgress = fieldProgress.skillsProgress[skillId];
    if (skillProgress == null) return;
 
    final courses = skillProgress.coursesProgress.values.toList();
 
    if (courses.isEmpty) {
      final newProgressPercentage = skillProgress.initialProgress;
      final updatedSkillProgress = SkillProgress(
        skillId: skillProgress.skillId,
        fieldId: skillProgress.fieldId,
        startedAt: skillProgress.startedAt,
        currentLessonIndex: skillProgress.currentLessonIndex,
        progressPercentage: newProgressPercentage,
        coursesProgress: skillProgress.coursesProgress,
        initialProgress: skillProgress.initialProgress,
        effectiveRatio: skillProgress.effectiveRatio,
        assessmentAttempts: skillProgress.assessmentAttempts,
        lastAssessmentAt: skillProgress.lastAssessmentAt,
        cheatingAttemptsCount: skillProgress.cheatingAttemptsCount,
        lessonsMarkedToday: skillProgress.lessonsMarkedToday,
        lastLessonDate: skillProgress.lastLessonDate,
        dailyWarningSent: skillProgress.dailyWarningSent,
        weeklyActiveDays: skillProgress.weeklyActiveDays,
        currentWeekKey: skillProgress.currentWeekKey,
        weeklyWarningSent: skillProgress.weeklyWarningSent,
      );
      fieldProgress.skillsProgress[skillId] = updatedSkillProgress;
      await _updateFieldOverallProgress(fieldId, batch: batch);
      return;
    }
 
    final hasAnyCompleted = courses.any((c) => c.isCompleted);
    final initialProgress = skillProgress.initialProgress;
    final effectiveRatio  = skillProgress.effectiveRatio;
 
    int newProgressPercentage;
    if (hasAnyCompleted) {
      // كورس مكتمل → 80% دائماً بصرف النظر عن المستوى
      newProgressPercentage = 80;
    } else if (initialProgress >= 80) {
      // خبير — الكورسات للمراجعة فقط، التقدم لا يتغير إلا بالاختبار.
      // نُبقيه على initialProgress لتجنب clamp(80, 79) الخاطئ.
      newProgressPercentage = initialProgress;
    } else {
      // مستويات أخرى (foundation / intermediate / advanced) —
      // clamp آمن هنا لأن initialProgress < 80 دائماً.
      final totalLessonProgress = courses.fold<double>(
        0,
        (total, c) => total + (c.totalLessons > 0
            ? c.completedLessons.length / c.totalLessons
            : 0),
      );
      final courseContribution =
          (totalLessonProgress / courses.length) * 75;
 
      newProgressPercentage = (initialProgress +
              courseContribution * effectiveRatio)
          .round()
          .clamp(initialProgress, 79);
    }
 
    final updatedSkillProgress = SkillProgress(
      skillId: skillProgress.skillId,
      fieldId: skillProgress.fieldId,
      startedAt: skillProgress.startedAt,
      currentLessonIndex: skillProgress.currentLessonIndex,
      progressPercentage: newProgressPercentage,
      coursesProgress: skillProgress.coursesProgress,
      initialProgress: skillProgress.initialProgress,
      effectiveRatio: skillProgress.effectiveRatio,
      assessmentAttempts: skillProgress.assessmentAttempts,
      lastAssessmentAt: skillProgress.lastAssessmentAt,
      cheatingAttemptsCount: skillProgress.cheatingAttemptsCount,
      lessonsMarkedToday: skillProgress.lessonsMarkedToday,
      lastLessonDate: skillProgress.lastLessonDate,
      dailyWarningSent: skillProgress.dailyWarningSent,
      weeklyActiveDays: skillProgress.weeklyActiveDays,
      currentWeekKey: skillProgress.currentWeekKey,
      weeklyWarningSent: skillProgress.weeklyWarningSent,
    );
 
    fieldProgress.skillsProgress[skillId] = updatedSkillProgress;
    await _updateFieldOverallProgress(fieldId, batch: batch);
 
    final docRef = _firestore.collection('user_profiles').doc(_currentUserId);
 
    if (batch != null) {
      batch.update(docRef, {
        'fieldProgress.$fieldId.skillsProgress.$skillId':
            updatedSkillProgress.toJson(),
      });
    } else {
      try {
        await docRef.update({
          'fieldProgress.$fieldId.skillsProgress.$skillId':
              updatedSkillProgress.toJson(),
        });
      } catch (e) {
        debugPrint('❌ Error saving skill progress: $e');
      }
    }
  }

  /// إعادة حساب overallProgress للمجال بناءً على متوسط المهارات
  Future<void> _updateFieldOverallProgress(
    String fieldId, {
    WriteBatch? batch,
  }) async {
    final fieldProgress = _userProfile?.fieldProgress[fieldId];
    if (fieldProgress == null) return;

    final skills = fieldProgress.skillsProgress.values.toList();
    if (skills.isEmpty) return;

    final totalProgress = skills.fold<int>(
      0,
      (total, s) => total + s.progressPercentage,
    );
    final newOverall = (totalProgress / skills.length).round();

    fieldProgress.overallProgress = newOverall;

    final docRef = _firestore.collection('user_profiles').doc(_currentUserId);

    if (batch != null) {
      // أضف للـ batch بدون تنفيذ فوري
      batch.update(docRef, {
        'fieldProgress.$fieldId.overallProgress': newOverall,
      });
    } else {
      // write مستقل عند الاستدعاء خارج batch
      try {
        await docRef.update({
          'fieldProgress.$fieldId.overallProgress': newOverall,
        });
      } catch (e) {
        debugPrint('❌ Error saving field overall progress: $e');
      }
    }

    debugPrint('✅ Field $fieldId overallProgress updated: $newOverall%');
  }

  Future<AssessmentOutcome> applyAssessmentResult({
    required String fieldId,
    required String skillId,
    required int scorePercent,
    required int questionsAnswered,
    required int exitCount,
    required int pasteCount,
    required int initialProgress,
  }) async {
    if (_userProfile == null || _currentUserId == null) {
      return AssessmentOutcome.error;
    }

    final fieldProgress = _userProfile!.fieldProgress[fieldId];
    final skillProgress = fieldProgress?.skillsProgress[skillId];
    if (skillProgress == null) return AssessmentOutcome.error;

    // ── فحوصات ما قبل التقييم ───────────────────────────────────────────────

    // 1. فحص فترة الانتظار بين المحاولات
    if (skillProgress.lastAssessmentAt != null) {
      final attempts = skillProgress.assessmentAttempts;
      final waitHours =
          attempts == 1
              ? 24
              : attempts == 2
              ? 48
              : 0;
      final hoursSince =
          DateTime.now().difference(skillProgress.lastAssessmentAt!).inHours;
      if (waitHours > 0 && hoursSince < waitHours) {
        return AssessmentOutcome.waitRequired;
      }
    }

    // 2. فحص الحد الأقصى للمحاولات
    if (skillProgress.assessmentAttempts >= 3) {
      return AssessmentOutcome.maxAttemptsReached;
    }

    // 3. فحص الحد الأدنى من الأسئلة (8 أسئلة على الأقل)
    if (questionsAnswered < 8) {
      skillProgress.assessmentAttempts++;
      skillProgress.lastAssessmentAt = DateTime.now();

      await _firestore.collection('user_profiles').doc(_currentUserId).update({
        'fieldProgress.$fieldId.skillsProgress.$skillId.assessmentAttempts':
            skillProgress.assessmentAttempts,
        'fieldProgress.$fieldId.skillsProgress.$skillId.lastAssessmentAt':
            skillProgress.lastAssessmentAt!.toIso8601String(),
      });

      notifyListeners();
      debugPrint(
        '⚠️ Assessment incomplete: $questionsAnswered/8 questions answered',
      );
      return AssessmentOutcome.incomplete;
    }

    // ── حساب النتيجة النهائية الموزونة ──────────────────────────────────────

    // مؤشر السلوك: كل خروج أو لصق يُخفّض النتيجة كعامل مساعد فقط
    // الحد الأقصى للتأثير السلوكي: -10 نقاط
    final behaviorPenalty = ((exitCount * 2) + (pasteCount * 1)).clamp(0, 10);

    // نسبة الإنجاز داخل الاختبار
    final completionScore = ((questionsAnswered / 15) * 100).round();

    // المعادلة الموزونة: 80% تقييم Gemini + 20% نسبة الإنجاز
    final weightedScore = (0.8 * scorePercent + 0.2 * completionScore).round();

    // النتيجة النهائية بعد خصم السلوك
    final finalScore = (weightedScore - behaviorPenalty).clamp(0, 100);

    // ── تحديث عدادات المحاولات دائماً ────────────────────────────────────────
    skillProgress.assessmentAttempts++;
    skillProgress.lastAssessmentAt = DateTime.now();

    // ── إيجاد الكورس المكتمل (الأول المكتمل) لتعديله عند الحاجة ────────────
    final completedCourseEntry =
        skillProgress.coursesProgress.entries
            .where((e) => e.value.isCompleted)
            .firstOrNull;

    // ── تحديد الحالة وتأثيرها على البيانات ──────────────────────────────────
    int newProgress;
    AssessmentOutcome outcome;

    if (finalScore >= 80) {
      // ✅ اجتاز — يبقى على 80%
      newProgress = 80;
      outcome = AssessmentOutcome.passed;
      if (initialProgress >= 65) {
        _pendingCourseCompletionChoice = true;
      }
      debugPrint('✅ Assessment passed: finalScore=$finalScore%');
    } else if (finalScore >= 50) {
      // 🔄 يحتاج مراجعة — يُعاد التقدم للنتيجة
      newProgress = finalScore;
      outcome = AssessmentOutcome.needsReview;

      if (completedCourseEntry != null) {
        final cp = completedCourseEntry.value;
        final lessonsToKeep = ((finalScore / 100) * cp.totalLessons).round();
        final keptLessons = List<int>.generate(lessonsToKeep, (i) => i);

        final partialCourse = CourseProgress(
          courseId: cp.courseId,
          skillId: cp.skillId,
          fieldId: cp.fieldId,
          startedAt: cp.startedAt,
          lastAccessedAt: DateTime.now(),
          currentLessonIndex: lessonsToKeep,
          totalLessons: cp.totalLessons,
          completedLessons: keptLessons,
          isCompleted: false,
          completedAt: null,
          userRating: cp.userRating,
          accessCount: cp.accessCount,
          totalStudyMinutes: cp.totalStudyMinutes,
        );
        skillProgress.coursesProgress[completedCourseEntry.key] = partialCourse;

        await _firestore
            .collection('user_profiles')
            .doc(_currentUserId)
            .update({
              'fieldProgress.$fieldId.skillsProgress.$skillId'
                      '.coursesProgress.${completedCourseEntry.key}':
                  partialCourse.toJson(),
            });
      }
      debugPrint('🔄 Assessment needsReview: finalScore=$finalScore%');
    } else if (finalScore >= 20) {
      // ⚠️ مستوى ضعيف — يُعاد لنسبة مكافئة
      newProgress = finalScore;
      outcome = AssessmentOutcome.weak;

      if (completedCourseEntry != null) {
        final cp = completedCourseEntry.value;
        final lessonsToKeep = ((finalScore / 100) * cp.totalLessons).round();
        final keptLessons = List<int>.generate(lessonsToKeep, (i) => i);

        final partialCourse = CourseProgress(
          courseId: cp.courseId,
          skillId: cp.skillId,
          fieldId: cp.fieldId,
          startedAt: cp.startedAt,
          lastAccessedAt: DateTime.now(),
          currentLessonIndex: lessonsToKeep,
          totalLessons: cp.totalLessons,
          completedLessons: keptLessons,
          isCompleted: false,
          completedAt: null,
          userRating: cp.userRating,
          accessCount: cp.accessCount,
          totalStudyMinutes: cp.totalStudyMinutes,
        );
        skillProgress.coursesProgress[completedCourseEntry.key] = partialCourse;

        await _firestore
            .collection('user_profiles')
            .doc(_currentUserId)
            .update({
              'fieldProgress.$fieldId.skillsProgress.$skillId'
                      '.coursesProgress.${completedCourseEntry.key}':
                  partialCourse.toJson(),
            });
      }
      debugPrint('⚠️ Assessment weak: finalScore=$finalScore%');
    } else {
      // ❌ غش / نتيجة منخفضة جداً — إلغاء الكورس كاملاً
      newProgress = 0;
      outcome = AssessmentOutcome.cheating;

      skillProgress.cheatingAttemptsCount++;

      if (completedCourseEntry != null) {
        final cp = completedCourseEntry.value;
        final resetCourse = CourseProgress(
          courseId: cp.courseId,
          skillId: cp.skillId,
          fieldId: cp.fieldId,
          startedAt: cp.startedAt,
          lastAccessedAt: DateTime.now(),
          currentLessonIndex: 0,
          totalLessons: cp.totalLessons,
          completedLessons: [],
          isCompleted: false,
          completedAt: null,
          userRating: null,
          accessCount: cp.accessCount,
          totalStudyMinutes: 0,
        );
        skillProgress.coursesProgress[completedCourseEntry.key] = resetCourse;

        await _firestore
            .collection('user_profiles')
            .doc(_currentUserId)
            .update({
              'fieldProgress.$fieldId.skillsProgress.$skillId'
                      '.coursesProgress.${completedCourseEntry.key}':
                  resetCourse.toJson(),
            });
      }
      debugPrint(
        '❌ Assessment cheating: finalScore=$finalScore%'
        ' (cheatingCount=${skillProgress.cheatingAttemptsCount})',
      );
    }

    // ── تحديث SkillProgress النهائي ─────────────────────────────────────────
    final updatedSkill = SkillProgress(
      skillId: skillProgress.skillId,
      fieldId: skillProgress.fieldId,
      startedAt: skillProgress.startedAt,
      currentLessonIndex: skillProgress.currentLessonIndex,
      progressPercentage: newProgress,
      coursesProgress: skillProgress.coursesProgress,
      assessmentAttempts: skillProgress.assessmentAttempts,
      lastAssessmentAt: skillProgress.lastAssessmentAt,
      cheatingAttemptsCount: skillProgress.cheatingAttemptsCount,
      initialProgress: skillProgress.initialProgress,
      effectiveRatio: skillProgress.effectiveRatio,
      lessonsMarkedToday: skillProgress.lessonsMarkedToday,
      lastLessonDate: skillProgress.lastLessonDate,
      dailyWarningSent: skillProgress.dailyWarningSent,
      weeklyActiveDays: skillProgress.weeklyActiveDays,
      currentWeekKey: skillProgress.currentWeekKey,
      weeklyWarningSent: skillProgress.weeklyWarningSent,
      isAssessmentPassed: outcome == AssessmentOutcome.passed
          ? true
          : skillProgress.isAssessmentPassed, // لا تمسح النجاح السابق
    );

    fieldProgress!.skillsProgress[skillId] = updatedSkill;
    await _updateFieldOverallProgress(fieldId);
    _checkAndAdvanceLevel(fieldId);
    notifyListeners();

    // ── حفظ كل شيء في Firestore في update واحد ───────────────────────────────
    await _firestore.collection('user_profiles').doc(_currentUserId).update({
      'fieldProgress.$fieldId.skillsProgress.$skillId.progressPercentage':
          newProgress,
      'fieldProgress.$fieldId.skillsProgress.$skillId.assessmentAttempts':
          updatedSkill.assessmentAttempts,
      'fieldProgress.$fieldId.skillsProgress.$skillId.lastAssessmentAt':
          updatedSkill.lastAssessmentAt?.toIso8601String(),
      'fieldProgress.$fieldId.skillsProgress.$skillId.cheatingAttemptsCount':
          updatedSkill.cheatingAttemptsCount,
      'fieldProgress.$fieldId.skillsProgress.$skillId.isAssessmentPassed':
          updatedSkill.isAssessmentPassed,
    });

    debugPrint(
      '✅ applyAssessmentResult done: score=$scorePercent% '
      'questions=$questionsAnswered exits=$exitCount pastes=$pasteCount '
      '→ final=$finalScore% outcome=$outcome',
    );

    return outcome;
  }

  AssessmentOutcome? checkAssessmentEligibility({
    required String fieldId,
    required String skillId,
  }) {
    final skillProgress =
        _userProfile?.fieldProgress[fieldId]?.skillsProgress[skillId];

    if (skillProgress == null) return AssessmentOutcome.error;

    // فحص الحد الأقصى
    if (skillProgress.assessmentAttempts >= 3) {
      return AssessmentOutcome.maxAttemptsReached;
    }

    // فحص فترة الانتظار
    if (skillProgress.lastAssessmentAt != null) {
      final attempts = skillProgress.assessmentAttempts;
      final waitHours =
          attempts == 1
              ? 24
              : attempts == 2
              ? 48
              : 0;
      final hoursSince =
          DateTime.now().difference(skillProgress.lastAssessmentAt!).inHours;
      if (waitHours > 0 && hoursSince < waitHours) {
        return AssessmentOutcome.waitRequired;
      }
    }

    return null; // لا مانع — يمكن إجراء الاختبار
  }

  // ─────────────────────────────────────────────────────────────────────────
  // حساب حدود التعلم من preferences المستخدم
  // ─────────────────────────────────────────────────────────────────────────

  /// الحد اليومي للدروس بعد هامش التسامح
  int _getMaxLessonsPerDay() {
    final prefs = _userProfile?.preferences ?? {};
    final session = prefs['sessionDuration'] as String? ?? 'medium';
    final goals = prefs['goals'] as Map<String, dynamic>? ?? {};
    final commitment = goals['commitmentLevel'] as String? ?? 'medium';

    // الحد الأساسي حسب مدة الجلسة
    final base = switch (session) {
      'short'  => 1,
      'medium' => 2,
      'long'   => 4,
      _        => 2,
    };

    // معامل التسامح
    final tolerance = switch (commitment) {
      'low'    => 0.1,
      'medium' => 0.2,
      'high'   => 0.3,
      _        => 0.2,
    };

    return (base * (1 + tolerance)).ceil();
  }

  /// الحد الأسبوعي للأيام بعد هامش التسامح
  int _getMaxDaysPerWeek() {
    final prefs = _userProfile?.preferences ?? {};
    final schedule = prefs['schedule'] as Map<String, dynamic>? ?? {};
    final days = (schedule['daysPerWeek'] as num?)?.toInt() ?? 3;
    final goals = prefs['goals'] as Map<String, dynamic>? ?? {};
    final commitment = goals['commitmentLevel'] as String? ?? 'medium';

    final tolerance = switch (commitment) {
      'low'    => 0.1,
      'medium' => 0.2,
      'high'   => 0.3,
      _        => 0.2,
    };

    return (days * (1 + tolerance)).ceil();
  }

  /// يُحوّل مستوى المستخدم في المهارة إلى (initialProgress, effectiveRatio)
  ({int initialProgress, double effectiveRatio}) _getLevelDefaults(
      String skillLevel) {
    return switch (skillLevel) {
      'intermediate' => (initialProgress: 40, effectiveRatio: 0.6),
      'advanced'     => (initialProgress: 65, effectiveRatio: 0.25),
      'expert'       => (initialProgress: 80, effectiveRatio: 0.1),
      _              => (initialProgress: 0,  effectiveRatio: 1.0),
    };
  }

  /// مفتاح الأسبوع الحالي بصيغة 'yyyy-Www'
  String _currentWeekKey() {
  final now = DateTime.now();
 
  // نجد يوم الخميس في نفس الأسبوع (ISO: الأسبوع ينتمي للسنة التي يقع فيها خميسه)
  // weekday في Dart: الاثنين=1 ... الأحد=7
  final thursday = now.add(Duration(days: 4 - now.weekday));
  final startOfYear = DateTime(thursday.year, 1, 1);
  final weekNumber = ((thursday.difference(startOfYear).inDays) / 7).floor() + 1;
 
  return '${thursday.year}-W${weekNumber.toString().padLeft(2, '0')}';
}

  /// تاريخ اليوم بصيغة 'yyyy-MM-dd'
  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // فحص ما إذا كان مسموحاً بتعليم درس جديد
  // ─────────────────────────────────────────────────────────────────────────

  LessonCheckResult checkLessonAllowed(String fieldId, String skillId) {
    final skillProgress = _userProfile
        ?.fieldProgress[fieldId]
        ?.skillsProgress[skillId];
    if (skillProgress == null) return LessonCheckResult.allowed;

    final todayKey   = _todayKey();
    final weekKey    = _currentWeekKey();
    final maxDaily   = _getMaxLessonsPerDay();
    final maxWeekly  = _getMaxDaysPerWeek();

    // ── إعادة تصفير العدادات إذا تغيّر اليوم أو الأسبوع ───────────────────
    final isNewDay  = skillProgress.lastLessonDate != todayKey;
    final isNewWeek = skillProgress.currentWeekKey != weekKey;

    if (isNewDay) {
      skillProgress.lessonsMarkedToday = 0;
      skillProgress.dailyWarningSent   = false;
      skillProgress.lastLessonDate     = todayKey;
    }

    if (isNewWeek) {
      skillProgress.weeklyActiveDays  = 0;
      skillProgress.weeklyWarningSent = false;
      skillProgress.currentWeekKey    = weekKey;
    }

    // ── فحص الحد الأسبوعي أولاً (أعلى أولوية) ────────────────────────────
    final wouldAddNewDay = isNewDay && !isNewWeek
        ? true   // يوم جديد في نفس الأسبوع
        : isNewWeek
            ? false  // أسبوع جديد — العداد يُصفَّر
            : false; // نفس اليوم — لا يُضاف

    final projectedWeeklyDays = wouldAddNewDay
        ? skillProgress.weeklyActiveDays + 1
        : isNewWeek
            ? 1  // أول يوم في الأسبوع الجديد
            : skillProgress.weeklyActiveDays;

    if (projectedWeeklyDays > maxWeekly) {
      if (!skillProgress.weeklyWarningSent) {
        return LessonCheckResult.weeklyWarning;
      } else {
        return LessonCheckResult.weeklyBlocked;
      }
    }

    // ── فحص الحد اليومي ───────────────────────────────────────────────────
    if (skillProgress.lessonsMarkedToday >= maxDaily) {
      if (!skillProgress.dailyWarningSent) {
        return LessonCheckResult.dailyWarning;
      } else {
        return LessonCheckResult.dailyBlocked;
      }
    }

    return LessonCheckResult.allowed;
  }

  void markDailyWarningSent(String fieldId, String skillId) {
    final sp = _userProfile?.fieldProgress[fieldId]?.skillsProgress[skillId];
    if (sp == null) return;
    sp.dailyWarningSent = true;
    _firestore.collection('user_profiles').doc(_currentUserId).update({
      'fieldProgress.$fieldId.skillsProgress.$skillId.dailyWarningSent': true,
    });
  }

  void markWeeklyWarningSent(String fieldId, String skillId) {
    final sp = _userProfile?.fieldProgress[fieldId]?.skillsProgress[skillId];
    if (sp == null) return;
    sp.weeklyWarningSent = true;
    _firestore.collection('user_profiles').doc(_currentUserId).update({
      'fieldProgress.$fieldId.skillsProgress.$skillId.weeklyWarningSent': true,
    });
  }

  /// يُعيد الوقت المتبقي بالدقائق قبل انتهاء فترة الانتظار
  int getRemainingWaitMinutes({
    required String fieldId,
    required String skillId,
  }) {
    final skillProgress =
        _userProfile?.fieldProgress[fieldId]?.skillsProgress[skillId];

    if (skillProgress?.lastAssessmentAt == null) return 0;

    final attempts = skillProgress!.assessmentAttempts;
    final waitHours =
        attempts == 1
            ? 24
            : attempts == 2
            ? 48
            : 0;
    if (waitHours == 0) return 0;

    final minutesSince =
        DateTime.now().difference(skillProgress.lastAssessmentAt!).inMinutes;
    final waitMinutes = waitHours * 60;
    return (waitMinutes - minutesSince).clamp(0, waitMinutes);
  }

  /// ترقية currentLevel عندما يُتقن المستخدم كافة مهارات مستواه الحالي
  void _checkAndAdvanceLevel(String fieldId) {
    final fieldProgress = _userProfile?.fieldProgress[fieldId];
    if (fieldProgress == null) return;

    const levelOrder = ['foundation', 'intermediate', 'advanced', 'expert'];
    final currentLevelIndex = levelOrder.indexOf(fieldProgress.currentLevel);

    // لا ترقية إذا كان بالفعل في أعلى مستوى
    if (currentLevelIndex >= levelOrder.length - 1) return;

    final field = _allFields[fieldId];
    if (field == null) return;

    // هل أتقن المستخدم ≥ 80% من مهارات مستواه الحالي؟
    final currentLevelSkills =
        field.skills.values
            .where((s) => s.level == fieldProgress.currentLevel)
            .toList();

    if (currentLevelSkills.isEmpty) return;

    final masteredCount =
        currentLevelSkills.where((skill) {
          final sp = fieldProgress.skillsProgress[skill.id];
          return (sp?.progressPercentage ?? 0) >= 80;
        }).length;

    // شرط الترقية: 80% من مهارات المستوى الحالي مُتقَنة
    final masteredRatio = masteredCount / currentLevelSkills.length;
    if (masteredRatio < 0.8) return;

    // ترقية المستوى
    final newLevel = levelOrder[currentLevelIndex + 1];
    fieldProgress.currentLevel = newLevel;

    // حفظ في Firebase
    _firestore.collection('user_profiles').doc(_currentUserId).update({
      'fieldProgress.$fieldId.currentLevel': newLevel,
    });

    debugPrint('🎉 User advanced to level: $newLevel in field: $fieldId');
  }

  // ═════════════════════════════════════════════════════════════════════════
  // المهارات والكورسات النشطة
  // ═════════════════════════════════════════════════════════════════════════

  List<SkillProgress> getActiveSkills({String? fieldId}) {
    if (_userProfile == null) return [];

    List<SkillProgress> activeSkills = [];
    List<String> fieldsToCheck = fieldId != null ? [fieldId] : selectedFields;

    for (String fId in fieldsToCheck) {
      FieldModel? field = _allFields[fId];
      if (field == null) continue;

      UserFieldProgress? fieldProgress = _userProfile!.fieldProgress[fId];
      if (fieldProgress == null) continue;

      String userLevel = fieldProgress.currentLevel;

      for (SkillProgress skillProgress in fieldProgress.skillsProgress.values) {
        SkillModel? skillData = getSkillData(fId, skillProgress.skillId);
        if (skillData == null) continue;

        bool isLevelSuitable = _isSkillLevelSuitable(
          skillData.level,
          userLevel,
        );
        // المهارة نشطة إذا لم يجتز الاختبار بعد — بصرف النظر عن نسبة التقدم.
        // progressPercentage >= 80 بدون اختبار = "جاهز للاختبار" وليس "متعلم".
        bool isNotMastered = !skillProgress.isAssessmentPassed;

        if (isLevelSuitable && isNotMastered) {
          activeSkills.add(skillProgress);
        }
      }
    }

    // حساب fieldId للترتيب مرة واحدة قبل الـ sort
    activeSkills.sort((a, b) {
      // كل مهارة تستخدم fieldId الخاص بها لضمان الحصول على البيانات الصحيحة
      final skillA = getSkillData(a.fieldId, a.skillId);
      final skillB = getSkillData(b.fieldId, b.skillId);

      int importanceCompare = (skillB?.importance ?? 0).compareTo(
        skillA?.importance ?? 0,
      );
      if (importanceCompare != 0) return importanceCompare;

      return a.progressPercentage.compareTo(b.progressPercentage);
    });

    return activeSkills;
  }

  List<CourseProgress> getActiveCourses({String? fieldId, String? skillId}) {
    if (_userProfile == null) return [];
 
    List<CourseProgress> activeCourses = [];
    List<String> fieldsToCheck = fieldId != null ? [fieldId] : selectedFields;
 
    for (String fId in fieldsToCheck) {
      UserFieldProgress? fieldProgress = _userProfile!.fieldProgress[fId];
      if (fieldProgress == null) continue;
 
      for (SkillProgress skillProgress in fieldProgress.skillsProgress.values) {
        if (skillId != null && skillProgress.skillId != skillId) continue;
 
        for (CourseProgress courseProgress
            in skillProgress.coursesProgress.values) {
          if (!courseProgress.isCompleted &&
              courseProgress.totalLessons > 0) {
            activeCourses.add(courseProgress);
          }
        }
      }
    }
 
    activeCourses.sort((a, b) => b.lastAccessedAt.compareTo(a.lastAccessedAt));
    return activeCourses;
  }

  /// الحصول على المهارات المتعلمة (progressPercentage >= 80)
  List<SkillProgress> getLearnedSkills({String? fieldId}) {
    if (_userProfile == null) return [];

    List<SkillProgress> learnedSkills = [];
    List<String> fieldsToCheck = fieldId != null ? [fieldId] : selectedFields;

    for (String fId in fieldsToCheck) {
      UserFieldProgress? fieldProgress = _userProfile!.fieldProgress[fId];
      if (fieldProgress == null) continue;

      for (SkillProgress skillProgress in fieldProgress.skillsProgress.values) {
        // المهارة متعلمة فقط إذا اجتاز المستخدم الاختبار بنجاح.
        // progressPercentage >= 80 وحده لا يكفي — قد يكون خبيراً لم يختبر بعد.
        if (skillProgress.isAssessmentPassed) {
          learnedSkills.add(skillProgress);
        }
      }
    }

    // ترتيب حسب تاريخ الإكمال (الأحدث أولاً)
    learnedSkills.sort((a, b) {
      // حساب آخر تاريخ إكمال كورس
      DateTime? dateA;
      DateTime? dateB;

      for (final course in a.coursesProgress.values) {
        if (course.completedAt != null) {
          if (dateA == null || course.completedAt!.isAfter(dateA)) {
            dateA = course.completedAt;
          }
        }
      }

      for (final course in b.coursesProgress.values) {
        if (course.completedAt != null) {
          if (dateB == null || course.completedAt!.isAfter(dateB)) {
            dateB = course.completedAt;
          }
        }
      }

      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;
      return dateB.compareTo(dateA);
    });

    return learnedSkills;
  }

  /// الحصول على الكورسات المكتملة
  List<CourseProgress> getCompletedCourses({String? fieldId, String? skillId}) {
    if (_userProfile == null) return [];

    List<CourseProgress> completedCourses = [];
    List<String> fieldsToCheck = fieldId != null ? [fieldId] : selectedFields;

    for (String fId in fieldsToCheck) {
      UserFieldProgress? fieldProgress = _userProfile!.fieldProgress[fId];
      if (fieldProgress == null) continue;

      for (SkillProgress skillProgress in fieldProgress.skillsProgress.values) {
        if (skillId != null && skillProgress.skillId != skillId) continue;

        for (CourseProgress courseProgress
            in skillProgress.coursesProgress.values) {
          if (courseProgress.isCompleted) {
            completedCourses.add(courseProgress);
          }
        }
      }
    }

    // ترتيب حسب تاريخ الإكمال (الأحدث أولاً)
    completedCourses.sort((a, b) {
      if (a.completedAt == null && b.completedAt == null) return 0;
      if (a.completedAt == null) return 1;
      if (b.completedAt == null) return -1;
      return b.completedAt!.compareTo(a.completedAt!);
    });

    return completedCourses;
  }

  /// تقييم كورس مكتمل
  Future<void> rateCourse({
    required String fieldId,
    required String skillId,
    required String courseId,
    required double rating,
  }) async {
    if (_userProfile == null || _currentUserId == null) return;

    final fieldProgress = _userProfile!.fieldProgress[fieldId];
    if (fieldProgress == null) return;

    final skillProgress = fieldProgress.skillsProgress[skillId];
    if (skillProgress == null) return;

    final courseProgress = skillProgress.coursesProgress[courseId];
    if (courseProgress == null) return;

    // Optimistic Update
    final updatedProgress = CourseProgress(
      courseId: courseProgress.courseId,
      skillId: courseProgress.skillId,
      fieldId: courseProgress.fieldId,
      startedAt: courseProgress.startedAt,
      lastAccessedAt: courseProgress.lastAccessedAt,
      currentLessonIndex: courseProgress.currentLessonIndex,
      totalLessons: courseProgress.totalLessons,
      completedLessons: courseProgress.completedLessons,
      isCompleted: courseProgress.isCompleted,
      completedAt: courseProgress.completedAt,
      userRating: rating,
      accessCount: courseProgress.accessCount,
    );

    skillProgress.coursesProgress[courseId] = updatedProgress;
    notifyListeners();

    // حفظ في Firebase
    try {
      await _firestore.collection('user_profiles').doc(_currentUserId).update({
        'fieldProgress.$fieldId.skillsProgress.$skillId.coursesProgress.$courseId.userRating':
            rating,
      });

      debugPrint('✅ Course rated: $courseId - Rating: $rating');
    } catch (e) {
      debugPrint('❌ Error rating course: $e');
      _lastError = e.toString();
    }
  }

  /// تحديث آخر وصول لكورس (عند الضغط على "متابعة التعلم")
  Future<void> updateLastAccess({
    required String fieldId,
    required String skillId,
    required String courseId,
  }) async {
    if (_userProfile == null || _currentUserId == null) return;

    final fieldProgress = _userProfile!.fieldProgress[fieldId];
    if (fieldProgress == null) return;

    final skillProgress = fieldProgress.skillsProgress[skillId];
    if (skillProgress == null) return;

    final courseProgress = skillProgress.coursesProgress[courseId];
    if (courseProgress == null) return;

    // Optimistic Update
    final updatedProgress = CourseProgress(
      courseId: courseProgress.courseId,
      skillId: courseProgress.skillId,
      fieldId: courseProgress.fieldId,
      startedAt: courseProgress.startedAt,
      lastAccessedAt: DateTime.now(), // تحديث آخر وصول
      currentLessonIndex: courseProgress.currentLessonIndex,
      totalLessons: courseProgress.totalLessons,
      completedLessons: courseProgress.completedLessons,
      isCompleted: courseProgress.isCompleted,
      completedAt: courseProgress.completedAt,
      userRating: courseProgress.userRating,
      accessCount: courseProgress.accessCount,
    );

    skillProgress.coursesProgress[courseId] = updatedProgress;
    notifyListeners();

    // حفظ في Firebase
    try {
      await _firestore.collection('user_profiles').doc(_currentUserId).update({
        'fieldProgress.$fieldId.skillsProgress.$skillId.coursesProgress.$courseId.lastAccessedAt':
            DateTime.now().toIso8601String(),
      });

      debugPrint('✅ Last access updated: $courseId');
    } catch (e) {
      debugPrint('❌ Error updating last access: $e');
    }
  }

  /// الحصول على تقدم كورس معين
  CourseProgress? getCourseProgress(
    String fieldId,
    String skillId,
    String courseId,
  ) {
    return _userProfile
        ?.fieldProgress[fieldId]
        ?.skillsProgress[skillId]
        ?.coursesProgress[courseId];
  }

  /// تحديد درس معين كمكتمل
  Future<void> markLessonAsCompleted({
    required String fieldId,
    required String skillId,
    required String courseId,
    required int lessonIndex,
  }) async {
    if (_userProfile == null || _currentUserId == null) return;

    final fieldProgress = _userProfile!.fieldProgress[fieldId];
    if (fieldProgress == null) return;

    final skillProgress = fieldProgress.skillsProgress[skillId];
    if (skillProgress == null) return;

    final courseProgress = skillProgress.coursesProgress[courseId];
    if (courseProgress == null) return;

    if (courseProgress.completedLessons.contains(lessonIndex)) return;

    // [FIX] حفظ نسخة احتياطية من الحالة القديمة قبل الـ optimistic update —
    // تُستخدم للتراجع عند فشل Firestore write حتى لا يبقى _userProfile
    // بقيمة خاطئة في الذاكرة (كان يُسبب تجاهل الدرس عند إعادة المحاولة).
    final previousCourseProgress = courseProgress;

    final newCompletedLessons = [
      ...courseProgress.completedLessons,
      lessonIndex,
    ];
    final newCurrentIndex =
        lessonIndex >= courseProgress.currentLessonIndex
            ? lessonIndex + 1
            : courseProgress.currentLessonIndex;
    final isNowCompleted =
        newCompletedLessons.length >= courseProgress.totalLessons;

    final updatedProgress = CourseProgress(
      courseId: courseProgress.courseId,
      skillId: courseProgress.skillId,
      fieldId: courseProgress.fieldId,
      startedAt: courseProgress.startedAt,
      lastAccessedAt: DateTime.now(),
      lastLessonUnlockedAt: DateTime.now(),
      currentLessonIndex: newCurrentIndex.clamp(0, courseProgress.totalLessons),
      totalLessons: courseProgress.totalLessons,
      completedLessons: newCompletedLessons,
      // ✅ isCompleted لا يُعاد لـ false أبداً بعد أن يصبح true
      isCompleted: courseProgress.isCompleted || isNowCompleted,
      // ✅ completedAt يُحفظ أول مرة ولا يُمسح أبداً
      completedAt:
          courseProgress.completedAt ??
          (isNowCompleted ? DateTime.now() : null),
      userRating: courseProgress.userRating,
      accessCount: courseProgress.accessCount,
    );

    // Optimistic update
    skillProgress.coursesProgress[courseId] = updatedProgress;
    notifyListeners();

    try {
      // ── تحديث عدادات النشاط اليومي والأسبوعي في الذاكرة أولاً ───────────
      final todayKey  = _todayKey();
      final weekKey   = _currentWeekKey();
      final sp        = fieldProgress.skillsProgress[skillId]!;

      final isNewDay  = sp.lastLessonDate != todayKey;
      final isNewWeek = sp.currentWeekKey != weekKey;

      if (isNewWeek) {
        sp.weeklyActiveDays = 1;
      } else if (isNewDay) {
        sp.weeklyActiveDays++;
      }
      // نفس اليوم — لا تغيير على weeklyActiveDays

      sp.lessonsMarkedToday = isNewDay ? 1 : sp.lessonsMarkedToday + 1;
      sp.lastLessonDate     = todayKey;
      sp.currentWeekKey     = weekKey;

      final batch  = _firestore.batch();
      final docRef = _firestore
          .collection('user_profiles')
          .doc(_currentUserId);

      // Write 1: courseProgress
      batch.update(docRef, {
        'fieldProgress.$fieldId.skillsProgress.$skillId.coursesProgress.$courseId':
            updatedProgress.toJson(),
      });

      // Write 2 & 3: skillProgress + overallProgress (تُضاف للـ batch داخلياً)
      await _updateSkillProgress(fieldId, skillId, batch: batch);

      // Write 4: عدادات النشاط — في نفس الـ batch لضمان الاتساق
      batch.update(docRef, {
        'fieldProgress.$fieldId.skillsProgress.$skillId.lessonsMarkedToday':
            sp.lessonsMarkedToday,
        'fieldProgress.$fieldId.skillsProgress.$skillId.lastLessonDate':
            sp.lastLessonDate,
        'fieldProgress.$fieldId.skillsProgress.$skillId.weeklyActiveDays':
            sp.weeklyActiveDays,
        'fieldProgress.$fieldId.skillsProgress.$skillId.currentWeekKey':
            sp.currentWeekKey,
      });

      // تنفيذ جميع الـ writes دفعةً واحدة
      await batch.commit();

      debugPrint('✅ Lesson $lessonIndex marked as completed in $courseId');
      onCourseProgressChangedCallback?.call().ignore();
    } catch (e) {
      debugPrint('❌ Error marking lesson as completed: $e');
      skillProgress.coursesProgress[courseId] = previousCourseProgress;
      await _updateSkillProgress(fieldId, skillId);
      notifyListeners();
      _lastError = e.toString();
      rethrow;
    }
  }

  /// تسجيل جلسة تعلم — تُعلِّم فقط الدروس التي مرّ عليها وقت كافٍ
  Future<LessonSessionResult> recordLearningSession({
    required String fieldId,
    required String skillId,
    required String courseId,
    required int estimatedMinutesPerLesson, // مشتق من duration الكورس
  }) async {
    if (_userProfile == null || _currentUserId == null) {
      return LessonSessionResult(unlockedCount: 0, message: 'لا يوجد مستخدم');
    }

    final fieldProgress = _userProfile!.fieldProgress[fieldId];
    final skillProgress = fieldProgress?.skillsProgress[skillId];
    final courseProgress = skillProgress?.coursesProgress[courseId];

    if (courseProgress == null) {
      return LessonSessionResult(unlockedCount: 0, message: 'الكورس غير موجود');
    }

    if (courseProgress.isCompleted) {
      return LessonSessionResult(
        unlockedCount: 0,
        message: 'الكورس مكتمل بالفعل',
      );
    }

    final now = DateTime.now();
    final lastAccess = courseProgress.lastAccessedAt;
    final minutesSinceLastAccess = now.difference(lastAccess).inMinutes;

    // كم درساً يمكن فتحه بناءً على الوقت المنقضي؟
    // نضيف هامش 20% تسامحاً (لو الدرس 10 دقائق، يكفي 8 دقائق)
    final toleranceMultiplier = 0.8;
    final effectiveMinutesPerLesson =
        (estimatedMinutesPerLesson * toleranceMultiplier).floor();

    if (effectiveMinutesPerLesson <= 0) {
      return LessonSessionResult(
        unlockedCount: 0,
        message: 'بيانات الكورس غير مكتملة',
      );
    }

    final lessonsEarned =
        (minutesSinceLastAccess / effectiveMinutesPerLesson).floor();

    if (lessonsEarned <= 0) {
      final minutesNeeded = effectiveMinutesPerLesson - minutesSinceLastAccess;
      return LessonSessionResult(
        unlockedCount: 0,
        message: 'لم يمرّ وقت كافٍ بعد. انتظر $minutesNeeded دقيقة أخرى',
      );
    }

    // الدروس المكتملة حالياً
    final alreadyCompleted = courseProgress.completedLessons.length;
    final maxUnlockable = courseProgress.totalLessons - alreadyCompleted;
    final toUnlock = lessonsEarned.clamp(0, maxUnlockable);

    if (toUnlock == 0) {
      return LessonSessionResult(
        unlockedCount: 0,
        message: 'لا دروس جديدة لفتحها',
      );
    }

    // بناء قائمة الدروس الجديدة
    final newLessons = List<int>.generate(
      toUnlock,
      (i) => alreadyCompleted + i,
    );
    final allCompleted = [...courseProgress.completedLessons, ...newLessons];

    final isNowCompleted = allCompleted.length >= courseProgress.totalLessons;
    final newStudyMinutes =
        courseProgress.totalStudyMinutes + minutesSinceLastAccess;

    final updatedProgress = CourseProgress(
      courseId: courseProgress.courseId,
      skillId: courseProgress.skillId,
      fieldId: courseProgress.fieldId,
      startedAt: courseProgress.startedAt,
      lastAccessedAt: now,
      lastLessonUnlockedAt: now,
      currentLessonIndex: allCompleted.length,
      totalLessons: courseProgress.totalLessons,
      completedLessons: allCompleted,
      isCompleted: isNowCompleted,
      completedAt: courseProgress.completedAt ?? (isNowCompleted ? now : null),
      userRating: courseProgress.userRating,
      accessCount: courseProgress.accessCount,
      totalStudyMinutes: newStudyMinutes,
    );

    skillProgress!.coursesProgress[courseId] = updatedProgress;
    await _updateSkillProgress(fieldId, skillId);
    notifyListeners();

    try {
      await _firestore.collection('user_profiles').doc(_currentUserId).update({
        'fieldProgress.$fieldId.skillsProgress.$skillId.coursesProgress.$courseId':
            updatedProgress.toJson(),
      });
      debugPrint(
        '✅ Learning session recorded: +$toUnlock lessons in $courseId',
      );
    } catch (e) {
      debugPrint('❌ Error recording learning session: $e');
      _lastError = e.toString();
    }

    return LessonSessionResult(
      unlockedCount: toUnlock,
      message:
          isNowCompleted
              ? '🎉 أكملت الكورس!'
              : 'تم تسجيل $toUnlock ${toUnlock == 1 ? "درس" : "دروس"} جديدة',
      isCompleted: isNowCompleted,
    );
  }

  /// تسجيل دخول للكورس (لتتبع النشاط)
  Future<void> recordCourseAccess({
    required String fieldId,
    required String skillId,
    required String courseId,
  }) async {
    if (_userProfile == null || _currentUserId == null) return;

    final fieldProgress = _userProfile!.fieldProgress[fieldId];
    if (fieldProgress == null) return;

    final skillProgress = fieldProgress.skillsProgress[skillId];
    if (skillProgress == null) return;

    final courseProgress = skillProgress.coursesProgress[courseId];
    if (courseProgress == null) return;

    // Optimistic Update — immutable pattern
    final updatedCourseProgress = CourseProgress(
      courseId: courseProgress.courseId,
      skillId: courseProgress.skillId,
      fieldId: courseProgress.fieldId,
      startedAt: courseProgress.startedAt,
      lastAccessedAt: DateTime.now(),
      currentLessonIndex: courseProgress.currentLessonIndex,
      totalLessons: courseProgress.totalLessons,
      completedLessons: courseProgress.completedLessons,
      isCompleted: courseProgress.isCompleted,
      completedAt: courseProgress.completedAt,
      userRating: courseProgress.userRating,
      accessCount: courseProgress.accessCount + 1,
    );
    skillProgress.coursesProgress[courseId] = updatedCourseProgress;
    notifyListeners();

    try {
      await _firestore.collection('user_profiles').doc(_currentUserId).update({
        'fieldProgress.$fieldId.skillsProgress.$skillId.coursesProgress.$courseId.lastAccessedAt':
            updatedCourseProgress.lastAccessedAt.toIso8601String(),
        'fieldProgress.$fieldId.skillsProgress.$skillId.coursesProgress.$courseId.accessCount':
            updatedCourseProgress.accessCount,
      });
      debugPrint(
        '✅ Course access recorded: $courseId (count: ${courseProgress.accessCount})',
      );
    } catch (e) {
      debugPrint('❌ Error recording course access: $e');
    }
  }

  bool _isSkillLevelSuitable(String skillLevel, String userLevel) {
    const levelOrder = ['foundation', 'intermediate', 'advanced', 'expert'];
    int skillLevelIndex = levelOrder.indexOf(skillLevel);
    int userLevelIndex = levelOrder.indexOf(userLevel);
    return skillLevelIndex <= userLevelIndex + 1;
  }

  /// [skillLevels] — مستويات مهارات المجال الجديد يختارها المستخدم
  /// من شاشة تحديد المستوى قبل الاستدعاء (في settings_screen).
  Future<void> addSecondaryField(
    String fieldId, {
    Map<String, dynamic> skillLevels = const {},
  }) async {
    if (_userProfile == null || _currentUserId == null) {
      throw Exception('لا يوجد مستخدم مسجل');
    }

    if (_userProfile!.primaryFieldId == fieldId) {
      throw Exception('هذا المجال محدد كمجال أساسي بالفعل');
    }

    if (_userProfile!.secondaryFieldId != null) {
      throw Exception('يوجد مجال ثانوي بالفعل. يجب حذفه أولاً');
    }

    try {
      // تحديث البروفايل بالمجال الجديد أولاً
      _userProfile!.secondaryFieldId = fieldId;

      // دمج skillLevels الجديدة مع preferences الحالية
      if (skillLevels.isNotEmpty) {
        final currentSkillLevels =
            Map<String, dynamic>.from(
              _userProfile!.preferences['skillLevels']
                  as Map<String, dynamic>? ?? {},
            )..addAll(skillLevels);
        _userProfile!.preferences['skillLevels'] = currentSkillLevels;
      }

      // حفظ secondaryFieldId وskillLevels في Firebase
      await _firestore.collection('user_profiles').doc(_currentUserId).update({
        'secondaryFieldId': fieldId,
        if (skillLevels.isNotEmpty)
          'preferences.skillLevels': _userProfile!.preferences['skillLevels'],
      });

      // تهيئة التقدم للمجال الجديد مع تمرير skillLevels صراحةً
      await _initializeFieldProgress(
        _currentUserId!,
        fieldId,
        skillLevels: skillLevels,
      );

      // تحميل بيانات المجال في الذاكرة
      await loadField(fieldId);

      notifyListeners();
      debugPrint('✅ Secondary field added: $fieldId');
    } catch (e) {
      debugPrint('❌ Error adding secondary field: $e');
      rethrow;
    }
  }

  /// تغيير مجال (أساسي أو ثانوي)
  /// [skillLevels] — مستويات مهارات المجال الجديد يختارها المستخدم
  /// من شاشة تحديد المستوى قبل الاستدعاء (في settings_screen).
  Future<void> changeField({
    required bool isPrimary,
    required String newFieldId,
    Map<String, dynamic> skillLevels = const {},
  }) async {
    if (_userProfile == null || _currentUserId == null) {
      throw Exception('لا يوجد مستخدم مسجل');
    }

    final oldFieldId =
        isPrimary
            ? _userProfile!.primaryFieldId
            : _userProfile!.secondaryFieldId;

    if (oldFieldId == null && !isPrimary) {
      throw Exception('لا يوجد مجال ثانوي لتغييره');
    }

    // التحقق من عدم وجود تكرار
    if (isPrimary && _userProfile!.secondaryFieldId == newFieldId) {
      throw Exception('هذا المجال محدد كمجال ثانوي بالفعل');
    }

    if (!isPrimary && _userProfile!.primaryFieldId == newFieldId) {
      throw Exception('هذا المجال محدد كمجال أساسي بالفعل');
    }

    try {
      // حذف التقدم القديم من الذاكرة والـ cache
      if (oldFieldId != null) {
        _userProfile!.fieldProgress.remove(oldFieldId);
        await _firebaseService.clearFieldCache(oldFieldId);
        _allFields.remove(oldFieldId);
      }

      // دمج skillLevels الجديدة مع preferences الحالية
      if (skillLevels.isNotEmpty) {
        final currentSkillLevels =
            Map<String, dynamic>.from(
              _userProfile!.preferences['skillLevels']
                  as Map<String, dynamic>? ?? {},
            )..addAll(skillLevels);
        _userProfile!.preferences['skillLevels'] = currentSkillLevels;
      }

      // تحديث المجال في البروفايل
      if (isPrimary) {
        _userProfile!.primaryFieldId = newFieldId;
      } else {
        _userProfile!.secondaryFieldId = newFieldId;
      }

      // حفظ في Firebase — بدون fieldProgress الجديد لأن
      // _initializeFieldProgress ستحفظه بشكل منفصل بعده
      Map<String, dynamic> updates = {
        'fieldProgress.$oldFieldId': FieldValue.delete(),
        if (skillLevels.isNotEmpty)
          'preferences.skillLevels': _userProfile!.preferences['skillLevels'],
      };

      if (isPrimary) {
        updates['primaryFieldId'] = newFieldId;
      } else {
        updates['secondaryFieldId'] = newFieldId;
      }

      await _firestore
          .collection('user_profiles')
          .doc(_currentUserId)
          .update(updates);

      // تهيئة التقدم للمجال الجديد مع تمرير skillLevels صراحةً
      await _initializeFieldProgress(
        _currentUserId!,
        newFieldId,
        skillLevels: skillLevels,
      );

      // تحميل بيانات المجال الجديد
      await loadField(newFieldId);

      notifyListeners();
      debugPrint(
        '✅ Field changed from $oldFieldId to $newFieldId (${isPrimary ? 'primary' : 'secondary'})',
      );
    } catch (e) {
      debugPrint('❌ Error changing field: $e');
      rethrow;
    }
  }

  /// حذف المجال الثانوي
  Future<void> removeSecondaryField() async {
    if (_userProfile == null || _currentUserId == null) {
      throw Exception('لا يوجد مستخدم مسجل');
    }

    final secondaryFieldId = _userProfile!.secondaryFieldId;
    if (secondaryFieldId == null) {
      throw Exception('لا يوجد مجال ثانوي للحذف');
    }

    try {
      // حذف التقدم
      _userProfile!.fieldProgress.remove(secondaryFieldId);
      _userProfile!.secondaryFieldId = null;

      // حفظ في Firebase
      await _firestore.collection('user_profiles').doc(_currentUserId).update({
        'secondaryFieldId': FieldValue.delete(),
        'fieldProgress.$secondaryFieldId': FieldValue.delete(),
      });

      notifyListeners();
      debugPrint('✅ Secondary field removed: $secondaryFieldId');
    } catch (e) {
      debugPrint('❌ Error removing secondary field: $e');
      rethrow;
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // تحديث التفضيلات (Preferences)
  // ═════════════════════════════════════════════════════════════════════════

  /// تحديث تفضيلات التعلم
  Future<void> updatePreferences(Map<String, dynamic> newPreferences) async {
    if (_userProfile == null || _currentUserId == null) {
      throw Exception('لا يوجد مستخدم مسجل');
    }

    try {
      // دمج التفضيلات الجديدة مع القديمة
      _userProfile!.preferences.addAll(newPreferences);

      // حفظ في Firebase
      await _firestore.collection('user_profiles').doc(_currentUserId).update({
        'preferences': _userProfile!.preferences,
      });

      notifyListeners();
      debugPrint('✅ Preferences updated');
    } catch (e) {
      debugPrint('❌ Error updating preferences: $e');
      rethrow;
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // الإحصائيات (Statistics)
  // ═════════════════════════════════════════════════════════════════════════

  /// إجمالي ساعات التعلم (تقريبي)
  double getTotalLearningHours() {
    if (_userProfile == null) return 0.0;

    double totalHours = 0.0;

    for (var fieldProgress in _userProfile!.fieldProgress.values) {
      for (var skillProgress in fieldProgress.skillsProgress.values) {
        for (var courseProgress in skillProgress.coursesProgress.values) {
          // حساب تقريبي: كل درس مكتمل = 30 دقيقة
          totalHours += courseProgress.completedLessons.length * 0.5;
        }
      }
    }

    return totalHours;
  }

  /// نسبة التقدم الكلي
  double getOverallProgressPercentage() {
    if (_userProfile == null) return 0.0;

    if (_userProfile!.fieldProgress.isEmpty) return 0.0;

    int totalProgress = 0;
    int fieldCount = 0;

    for (var fieldProgress in _userProfile!.fieldProgress.values) {
      totalProgress += fieldProgress.overallProgress;
      fieldCount++;
    }

    return fieldCount > 0 ? totalProgress / fieldCount : 0.0;
  }

  /// الحصول على قائمة بالكورسات النشطة
  List<Map<String, dynamic>> getActivesCoursesList() {
    if (_userProfile == null) return [];

    List<Map<String, dynamic>> activeCourses = [];

    for (var fieldProgress in _userProfile!.fieldProgress.values) {
      final fieldData = _allFields[fieldProgress.fieldId];

      for (var skillProgress in fieldProgress.skillsProgress.values) {
        final skillData = fieldData?.skills[skillProgress.skillId];

        for (var courseProgress in skillProgress.coursesProgress.values) {
          if (!courseProgress.isCompleted) {
            final courseData = getCourseData(
              courseProgress.fieldId,
              courseProgress.skillId,
              courseProgress.courseId,
            );

            if (courseData != null) {
              activeCourses.add({
                'courseId': courseProgress.courseId,
                'skillId': courseProgress.skillId,
                'fieldId': courseProgress.fieldId,
                'courseName': courseData.title,
                'skillName': skillData?.name ?? '',
                'fieldName': fieldData?.name ?? '',
                'progress':
                    (courseProgress.completedLessons.length /
                            courseProgress.totalLessons *
                            100)
                        .round(),
                'lastAccessedAt': courseProgress.lastAccessedAt,
              });
            }
          }
        }
      }
    }

    // ترتيب حسب آخر وصول
    activeCourses.sort(
      (a, b) => (b['lastAccessedAt'] as DateTime).compareTo(
        a['lastAccessedAt'] as DateTime,
      ),
    );

    return activeCourses;
  }

  // ═════════════════════════════════════════════════════════════════════════
  // حذف حساب المستخدم
  // ═════════════════════════════════════════════════════════════════════════

  /// حذف بروفايل المستخدم من Firestore
  Future<void> deleteUserProfile() async {
    if (_currentUserId == null) {
      throw Exception('لا يوجد مستخدم مسجل');
    }

    try {
      // إلغاء جميع الاشتراكات
      await _userProfileSubscription?.cancel();

      for (var sub in _fieldProgressSubscriptions.values) {
        await sub.cancel();
      }

      for (var sub in _fieldDataSubscriptions.values) {
        await sub.cancel();
      }

      // حذف من Firestore
      await _firestore.collection('user_profiles').doc(_currentUserId).delete();

      // تنظيف البيانات المحلية
      _userProfile = null;
      _currentUserId = null;
      _fieldProgressSubscriptions.clear();
      _fieldDataSubscriptions.clear();

      notifyListeners();
      debugPrint('✅ User profile deleted');
    } catch (e) {
      debugPrint('❌ Error deleting user profile: $e');
      rethrow;
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Cache Management
  // ═════════════════════════════════════════════════════════════════════════

  Future<void> clearFieldCache(String fieldId) async {
    await _firebaseService.clearFieldCache(fieldId);
  }

  Future<void> clearAllCache() async {
    await _firebaseService.clearAllCache();
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Reset عند تسجيل الخروج
  // ═════════════════════════════════════════════════════════════════════════

  /// يُستدعى عند تسجيل الخروج لتنظيف بيانات المستخدم الحالي.
  /// ضروري لأن الكلاس Singleton ولا يُدمر الـ instance أبداً.
  Future<void> reset() async {
    debugPrint('🔄 Resetting GlobalLearningState...');

    // إلغاء جميع الـ streams
    await _userProfileSubscription?.cancel();
    _userProfileSubscription = null;

    for (var sub in _fieldProgressSubscriptions.values) {
      await sub.cancel();
    }
    _fieldProgressSubscriptions.clear();

    for (var sub in _fieldDataSubscriptions.values) {
      await sub.cancel();
    }
    _fieldDataSubscriptions.clear();

    // تنظيف بيانات المستخدم
    _userProfile = null;
    _currentUserId = null;
    _lastError = null;
    _userProfileError = null;
    _isLoadingUserProfile = false;
    _isLoadingStaticData = false;

    // تنظيف بيانات المجالات (ستُعاد للمستخدم الجديد عند تسجيل الدخول)
    _allFields.clear();

    notifyListeners();
    debugPrint('✅ GlobalLearningState reset complete');
  }

  // ═════════════════════════════════════════════════════════════════════════
  // تنظيف الموارد
  // ═════════════════════════════════════════════════════════════════════════

  @override
  void dispose() {
    _userProfileSubscription?.cancel();

    for (final sub in _fieldProgressSubscriptions.values) {
      sub.cancel();
    }
    _fieldProgressSubscriptions.clear();

    for (final sub in _fieldDataSubscriptions.values) {
      sub.cancel();
    }
    _fieldDataSubscriptions.clear();

    _firebaseService.dispose();

    super.dispose();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// نماذج بيانات المستخدم (User Data Models)
// ═══════════════════════════════════════════════════════════════════════════

class UserLearningProfile {
  String userId;
  String primaryFieldId;
  String? secondaryFieldId;
  DateTime createdAt;
  Map<String, dynamic> preferences;
  Map<String, UserFieldProgress> fieldProgress;

  UserLearningProfile({
    required this.userId,
    required this.primaryFieldId,
    this.secondaryFieldId,
    required this.createdAt,
    required this.preferences,
    required this.fieldProgress,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'primaryFieldId': primaryFieldId,
      'secondaryFieldId': secondaryFieldId,
      'createdAt': createdAt.toIso8601String(),
      'preferences': preferences,
      'fieldProgress': fieldProgress.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
    };
  }

  factory UserLearningProfile.fromJson(Map<String, dynamic> json) {
    return UserLearningProfile(
      userId: json['userId'],
      primaryFieldId: json['primaryFieldId'],
      secondaryFieldId: json['secondaryFieldId'],
      createdAt: DateTime.parse(json['createdAt']),
      preferences: json['preferences'] ?? {},
      fieldProgress:
          (json['fieldProgress'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, UserFieldProgress.fromJson(value)),
          ) ??
          {},
    );
  }
}

class UserFieldProgress {
  String fieldId;
  String currentLevel;
  int overallProgress;
  DateTime startedAt;
  Map<String, SkillProgress> skillsProgress;

  UserFieldProgress({
    required this.fieldId,
    required this.currentLevel,
    required this.overallProgress,
    required this.startedAt,
    required this.skillsProgress,
  });

  Map<String, dynamic> toJson() {
    return {
      'fieldId': fieldId,
      'currentLevel': currentLevel,
      'overallProgress': overallProgress,
      'startedAt': startedAt.toIso8601String(),
      'skillsProgress': skillsProgress.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
    };
  }

  factory UserFieldProgress.fromJson(Map<String, dynamic> json) {
    return UserFieldProgress(
      fieldId: json['fieldId'],
      currentLevel: json['currentLevel'],
      overallProgress: json['overallProgress'],
      startedAt: DateTime.parse(json['startedAt']),
      skillsProgress: ((json['skillsProgress'] as Map<String, dynamic>?) ?? {})
          .map(
            (key, value) => MapEntry(
              key,
              SkillProgress.fromJson(value as Map<String, dynamic>),
            ),
          ),
    );
  }
}

class SkillProgress {
  String skillId;
  String fieldId;
  DateTime startedAt;
  int currentLessonIndex;
  int progressPercentage;
  Map<String, CourseProgress> coursesProgress;
  int assessmentAttempts;
  DateTime? lastAssessmentAt;
  int cheatingAttemptsCount;
  int initialProgress;
  double effectiveRatio;
  int lessonsMarkedToday;
  String lastLessonDate;
  bool dailyWarningSent;
  int weeklyActiveDays;
  String currentWeekKey;
  bool weeklyWarningSent;
  /// true فقط عند اجتياز الاختبار بنجاح (outcome == passed).
  /// هو المعيار الحقيقي لتصنيف المهارة كـ "متعلمة".
  bool isAssessmentPassed;

  SkillProgress({
    required this.skillId,
    required this.fieldId,
    required this.startedAt,
    required this.currentLessonIndex,
    required this.progressPercentage,
    required this.coursesProgress,
    this.assessmentAttempts = 0,
    this.lastAssessmentAt,
    this.cheatingAttemptsCount = 0,
    this.initialProgress = 0,
    this.effectiveRatio = 1.0,
    this.lessonsMarkedToday = 0,
    this.lastLessonDate = '',
    this.dailyWarningSent = false,
    this.weeklyActiveDays = 0,
    this.currentWeekKey = '',
    this.weeklyWarningSent = false,
    this.isAssessmentPassed = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'skillId': skillId,
      'fieldId': fieldId,
      'startedAt': startedAt.toIso8601String(),
      'currentLessonIndex': currentLessonIndex,
      'progressPercentage': progressPercentage,
      'coursesProgress': coursesProgress.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'assessmentAttempts': assessmentAttempts,
      'lastAssessmentAt': lastAssessmentAt?.toIso8601String(),
      'cheatingAttemptsCount': cheatingAttemptsCount,
      'initialProgress': initialProgress,
      'effectiveRatio': effectiveRatio,
      'lessonsMarkedToday': lessonsMarkedToday,
      'lastLessonDate': lastLessonDate,
      'dailyWarningSent': dailyWarningSent,
      'weeklyActiveDays': weeklyActiveDays,
      'currentWeekKey': currentWeekKey,
      'weeklyWarningSent': weeklyWarningSent,
      'isAssessmentPassed': isAssessmentPassed,
    };
  }

  factory SkillProgress.fromJson(Map<String, dynamic> json) {
    return SkillProgress(
      skillId: json['skillId'],
      fieldId: json['fieldId'],
      startedAt: DateTime.parse(json['startedAt']),
      currentLessonIndex: json['currentLessonIndex'],
      progressPercentage: json['progressPercentage'],
      coursesProgress:
          ((json['coursesProgress'] as Map<String, dynamic>?) ?? {}).map(
            (key, value) => MapEntry(
              key,
              CourseProgress.fromJson(value as Map<String, dynamic>),
            ),
          ),
      // ── حقول جديدة مع default values لضمان التوافق مع البيانات القديمة ──
      assessmentAttempts: json['assessmentAttempts'] as int? ?? 0,
      lastAssessmentAt:
          json['lastAssessmentAt'] != null
              ? DateTime.parse(json['lastAssessmentAt'] as String)
              : null,
      cheatingAttemptsCount: json['cheatingAttemptsCount'] as int? ?? 0,
      initialProgress: json['initialProgress'] as int? ?? 0,
      effectiveRatio: (json['effectiveRatio'] as num?)?.toDouble() ?? 1.0,
      lessonsMarkedToday: json['lessonsMarkedToday'] as int? ?? 0,
      lastLessonDate: json['lastLessonDate'] as String? ?? '',
      dailyWarningSent: json['dailyWarningSent'] as bool? ?? false,
      weeklyActiveDays: json['weeklyActiveDays'] as int? ?? 0,
      currentWeekKey: json['currentWeekKey'] as String? ?? '',
      weeklyWarningSent: json['weeklyWarningSent'] as bool? ?? false,
      isAssessmentPassed: json['isAssessmentPassed'] as bool? ?? false,
    );
  }
}

class CourseProgress {
  String courseId;
  String skillId;
  String fieldId;
  DateTime startedAt;
  DateTime lastAccessedAt;
  int currentLessonIndex;
  int totalLessons;
  List<int> completedLessons;
  bool isCompleted;
  DateTime? completedAt;
  double? userRating;
  int accessCount;
  DateTime? lastLessonUnlockedAt;
  int totalStudyMinutes;

  CourseProgress({
    required this.courseId,
    required this.skillId,
    required this.fieldId,
    required this.startedAt,
    required this.lastAccessedAt,
    required this.currentLessonIndex,
    required this.totalLessons,
    required this.completedLessons,
    required this.isCompleted,
    this.completedAt,
    this.userRating,
    this.accessCount = 0,
    this.lastLessonUnlockedAt,
    this.totalStudyMinutes = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'courseId': courseId,
      'skillId': skillId,
      'fieldId': fieldId,
      'startedAt': startedAt.toIso8601String(),
      'lastAccessedAt': lastAccessedAt.toIso8601String(),
      'currentLessonIndex': currentLessonIndex,
      'totalLessons': totalLessons,
      'completedLessons': completedLessons,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'userRating': userRating,
      'accessCount': accessCount,
      'lastLessonUnlockedAt': lastLessonUnlockedAt?.toIso8601String(),
      'totalStudyMinutes': totalStudyMinutes,
    };
  }

  factory CourseProgress.fromJson(Map<String, dynamic> json) {
    return CourseProgress(
      courseId: json['courseId'],
      skillId: json['skillId'],
      fieldId: json['fieldId'],
      startedAt: DateTime.parse(json['startedAt']),
      lastAccessedAt: DateTime.parse(json['lastAccessedAt']),
      currentLessonIndex: json['currentLessonIndex'],
      totalLessons: json['totalLessons'],
      completedLessons: List<int>.from(json['completedLessons']),
      isCompleted: json['isCompleted'],
      completedAt:
          json['completedAt'] != null
              ? DateTime.parse(json['completedAt'])
              : null,
      userRating: json['userRating']?.toDouble(),
      accessCount: json['accessCount'] ?? 0,
      lastLessonUnlockedAt:
          json['lastLessonUnlockedAt'] != null
              ? DateTime.parse(json['lastLessonUnlockedAt'])
              : null,
      totalStudyMinutes: json['totalStudyMinutes'] ?? 0,
    );
  }
}

/// نتيجة تسجيل جلسة تعلم
class LessonSessionResult {
  final int unlockedCount;
  final String message;
  final bool isCompleted;

  const LessonSessionResult({
    required this.unlockedCount,
    required this.message,
    this.isCompleted = false,
  });

  bool get hasNewLessons => unlockedCount > 0;
}

enum LessonCheckResult {
  allowed,        // مسموح
  dailyWarning,   // تجاوز الحد اليومي — أول مرة
  dailyBlocked,   // تجاوز الحد اليومي — ثاني مرة فأكثر
  weeklyWarning,  // تجاوز الحد الأسبوعي — أول مرة
  weeklyBlocked,  // تجاوز الحد الأسبوعي — ثاني مرة فأكثر
}

/// نتيجة تطبيق الاختبار
enum AssessmentOutcome {
  passed, // ≥ 80% نهائية + ≥ 8 أسئلة
  needsReview, // 50-79% نهائية
  weak, // 20-49% نهائية
  cheating, // < 20% نهائية
  incomplete, // أجاب على أقل من 8 أسئلة — بيانات غير كافية
  maxAttemptsReached, // استنفد 3 محاولات
  waitRequired, // في فترة انتظار بين المحاولات
  error, // خطأ تقني
}