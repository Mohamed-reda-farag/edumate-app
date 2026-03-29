import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../models/field_model.dart';
import '../models/skill_model.dart';
import '../models/course_model.dart';

/// خدمة Firebase للتعامل مع Firestore مع دعم Cache و Streams
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // Firebase & Hive instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Box<String> _cacheBox;
  bool _isInitialized = false;

  // Stream controllers
  final Map<String, StreamController<FieldModel>> _fieldStreamControllers = {};
  final Map<String, StreamSubscription<DocumentSnapshot>> _firestoreSubscriptions = {};

  // Cache timing
  static const Duration _cacheExpiration = Duration(hours: 24);
  final Map<String, DateTime> _cacheTimestamps = {};

  // ═══════════════════════════════════════════════════════════════════════
  // التهيئة (Initialization)
  // ═══════════════════════════════════════════════════════════════════════

  /// تهيئة الخدمة - يجب استدعائها قبل الاستخدام
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // فتح الـ box مباشرة — Hive مهيأ بالفعل من main.dart
      if (Hive.isBoxOpen('fields_cache')) {
        _cacheBox = Hive.box<String>('fields_cache');
      } else {
        _cacheBox = await Hive.openBox<String>('fields_cache');
      }
      
      // تفعيل Offline Persistence في Firestore
      _firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      _isInitialized = true;
      debugPrint('✅ FirebaseService initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing FirebaseService: $e');
      rethrow;
    }
  }

  /// التأكد من التهيئة
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('FirebaseService not initialized. Call initialize() first.');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // جلب البيانات (Fetch Operations)
  // ═══════════════════════════════════════════════════════════════════════

  /// جلب مجال واحد مع Cache
  Future<FieldModel?> getField(String fieldId) async {
    _ensureInitialized();

    try {
      // محاولة جلب من Cache أولاً
      final cachedData = _getCachedField(fieldId);
      if (cachedData != null && !_isCacheExpired(fieldId)) {
        debugPrint('📦 Loaded $fieldId from cache');
        return cachedData;
      }

      // جلب من Firestore
      debugPrint('☁️ Fetching $fieldId from Firestore...');
      final doc = await _firestore
          .collection('engineering_fields')
          .doc(fieldId)
          .get();

      if (!doc.exists) {
        debugPrint('⚠️ Field $fieldId not found');
        return null;
      }

      final fieldData = doc.data()!;
      final fieldModel = _parseFieldData(fieldId, fieldData);

      // حفظ في Cache
      await _cacheField(fieldId, fieldModel);
      
      debugPrint('✅ Field $fieldId fetched successfully');
      return fieldModel;
    } catch (e) {
      debugPrint('❌ Error fetching field $fieldId: $e');
      
      // محاولة الرجوع للـ Cache حتى لو منتهي
      final cachedData = _getCachedField(fieldId);
      if (cachedData != null) {
        debugPrint('📦 Returning expired cache for $fieldId');
        return cachedData;
      }
      
      rethrow;
    }
  }

  /// جلب جميع المجالات
  /// [forceRefresh] — إذا كان true يتجاهل الـ cache الصالح ويجلب كل المجالات
  /// من Firestore مباشرة. يُستخدم عندما يكون عدد المجالات في الـ cache أقل
  /// من الحد المتوقع (مثلاً عند إضافة مجال ثانوي بعد تخطيه في الاستبيان).
  Future<Map<String, FieldModel>> getAllFields({bool forceRefresh = false}) async {
    _ensureInitialized();

    try {
      // ── تحديد المجالات المنتهية والصالحة من Cache ────────────────────────
      final cachedFields = _getAllCachedFields();
      final expiredIds = cachedFields.values
          .where((field) => _isCacheExpired(field.id))
          .map((field) => field.id)
          .toList();

      // كل المجالات صالحة وlا يوجد إجبار على الإعادة — أرجعها من Cache مباشرةً
      if (cachedFields.isNotEmpty && expiredIds.isEmpty && !forceRefresh) {
        debugPrint('📦 Loaded ${cachedFields.length} fields from cache');
        return cachedFields;
      }

      // ── جلب المنتهية فقط من Firestore (أو كلها إذا كان Cache فارغاً أو forceRefresh) ──
      final idsToFetch = (expiredIds.isNotEmpty && !forceRefresh) ? expiredIds : null;
      debugPrint('☁️ Fetching ${idsToFetch?.length ?? 'all'} fields from Firestore...');

      final Map<String, FieldModel> freshFields = {};

      if (idsToFetch != null) {
        // fetch المنتهية فقط بالتوازي
        final results = await Future.wait(
          idsToFetch.map((id) async {
            final doc = await _firestore
                .collection('engineering_fields')
                .doc(id)
                .get();
            if (doc.exists) {
              try {
                return MapEntry(id, _parseFieldData(id, doc.data()!));
              } catch (e) {
                debugPrint('⚠️ Error parsing field $id: $e');
              }
            }
            return null;
          }),
        );
        for (final entry in results.whereType<MapEntry<String, FieldModel>>()) {
          freshFields[entry.key] = entry.value;
        }
      } else {
        // Cache فارغ — جلب الكل
        final snapshot = await _firestore
            .collection('engineering_fields')
            .get();
        for (var doc in snapshot.docs) {
          try {
            freshFields[doc.id] = _parseFieldData(doc.id, doc.data());
          } catch (e) {
            debugPrint('⚠️ Error parsing field ${doc.id}: $e');
          }
        }
      }

      // حفظ الجديدة في Cache
      await Future.wait(
        freshFields.entries.map((e) => _cacheField(e.key, e.value)),
      );

      // دمج الصالحة من Cache مع الجديدة من Firestore
      final result = {...cachedFields, ...freshFields};
      debugPrint('✅ Fetched ${freshFields.length} fields, total: ${result.length}');
      return result;
    } catch (e) {
      debugPrint('❌ Error fetching all fields: $e');
      return _getAllCachedFields();
    }
  }

  /// جلب مجالات محددة (Batch)
  Future<Map<String, FieldModel>> getFieldsBatch(List<String> fieldIds) async {
    _ensureInitialized();

    if (fieldIds.isEmpty) return {};

    final Map<String, FieldModel> fields = {};
    
    // جلب البيانات بشكل متوازي
    final results = await Future.wait(
      fieldIds.map((id) => getField(id)),
    );

    for (int i = 0; i < fieldIds.length; i++) {
      if (results[i] != null) {
        fields[fieldIds[i]] = results[i]!;
      }
    }

    return fields;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Streams للتحديثات الفورية
  // ═══════════════════════════════════════════════════════════════════════

  /// الاستماع للتحديثات على مجال معين
  Stream<FieldModel> watchField(String fieldId) {
    _ensureInitialized();

    // إذا كان الـ controller موجوداً لكن مغلقاً → أنشئ واحداً جديداً
    final existing = _fieldStreamControllers[fieldId];
    if (existing == null || existing.isClosed) {
      final controller = StreamController<FieldModel>.broadcast(
        onListen: () => _startWatchingField(fieldId),
        onCancel: () => _stopWatchingField(fieldId),
      );
      _fieldStreamControllers[fieldId] = controller;
    }

    return _fieldStreamControllers[fieldId]!.stream;
  }

  /// بدء الاستماع لمجال
  void _startWatchingField(String fieldId) {
    if (_firestoreSubscriptions.containsKey(fieldId)) return;

    debugPrint('👁️ Started watching field: $fieldId');

    // ── إرسال القيمة الـ cached فوراً كـ seed (بدون انتظار الشبكة) ──────────
    final cached = _getCachedField(fieldId);
    if (cached != null) {
      debugPrint('📦 Seeding stream with cached data for $fieldId');
      _fieldStreamControllers[fieldId]?.add(cached);
    }

    // ── الاستماع للتحديثات من Firestore ──────────────────────────────────────
    final subscription = _firestore
        .collection('engineering_fields')
        .doc(fieldId)
        .snapshots()
        .listen(
          (snapshot) {
            if (snapshot.exists) {
              try {
                final fieldModel = _parseFieldData(fieldId, snapshot.data()!);
                _cacheField(fieldId, fieldModel);
                _fieldStreamControllers[fieldId]?.add(fieldModel);
              } catch (e) {
                debugPrint('❌ Error parsing field snapshot $fieldId: $e');
                _fieldStreamControllers[fieldId]?.addError(e);
              }
            }
          },
          onError: (error) {
            debugPrint('❌ Error watching field $fieldId: $error');
            _fieldStreamControllers[fieldId]?.addError(error);
          },
        );

    _firestoreSubscriptions[fieldId] = subscription;
  }

  /// إيقاف الاستماع لمجال
  void _stopWatchingField(String fieldId) {
    debugPrint('👁️‍🗨️ Stopped watching field: $fieldId');

    _firestoreSubscriptions[fieldId]?.cancel();
    _firestoreSubscriptions.remove(fieldId);

    // إغلاق الـ StreamController وإزالته لمنع تراكم الموارد
    _fieldStreamControllers[fieldId]?.close();
    _fieldStreamControllers.remove(fieldId);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Cache Management
  // ═══════════════════════════════════════════════════════════════════════

  /// حفظ مجال في Cache
  Future<void> _cacheField(String fieldId, FieldModel field) async {
    try {
      final jsonData = json.encode(field.toJson());
      await _cacheBox.put('field_$fieldId', jsonData);
      // ✅ حفظ الـ timestamp في Hive بدلاً من الذاكرة فقط
      await _cacheBox.put('field_${fieldId}_ts', DateTime.now().toIso8601String());
      _cacheTimestamps[fieldId] = DateTime.now();
    } catch (e) {
      debugPrint('⚠️ Error caching field $fieldId: $e');
    }
  }

  /// جلب مجال من Cache
  FieldModel? _getCachedField(String fieldId) {
    try {
      final cachedJson = _cacheBox.get('field_$fieldId');
      if (cachedJson == null) return null;

      final jsonData = json.decode(cachedJson) as Map<String, dynamic>;
      return _parseFieldData(fieldId, jsonData);
    } catch (e) {
      debugPrint('⚠️ Error reading cached field $fieldId: $e');
      return null;
    }
  }

  /// جلب جميع المجالات من Cache
  Map<String, FieldModel> _getAllCachedFields() {
    final Map<String, FieldModel> fields = {};
    
    try {
      for (var key in _cacheBox.keys) {
        final keyStr = key.toString();
        // تجاهل مفاتيح الـ timestamps (field_xxx_ts) — فقط مفاتيح البيانات (field_xxx)
        if (keyStr.startsWith('field_') && !keyStr.endsWith('_ts')) {
          final fieldId = keyStr.substring(6); // Remove 'field_' prefix
          final field = _getCachedField(fieldId);
          if (field != null) {
            fields[fieldId] = field;
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error reading cached fields: $e');
    }

    return fields;
  }

  /// التحقق من انتهاء صلاحية Cache
  bool _isCacheExpired(String fieldId) {
    // أولاً: تحقق من الذاكرة
    final memoryTimestamp = _cacheTimestamps[fieldId];
    if (memoryTimestamp != null) {
      return DateTime.now().difference(memoryTimestamp) > _cacheExpiration;
    }
    // ثانياً: تحقق من Hive (بعد إعادة التشغيل)
    final storedTs = _cacheBox.get('field_${fieldId}_ts');
    if (storedTs == null) return true;
    try {
      final saved = DateTime.parse(storedTs);
      _cacheTimestamps[fieldId] = saved; // استعادة في الذاكرة
      return DateTime.now().difference(saved) > _cacheExpiration;
    } catch (_) {
      return true;
    }
  }

  /// مسح Cache لمجال معين
  Future<void> clearFieldCache(String fieldId) async {
    await _cacheBox.delete('field_$fieldId');
    await _cacheBox.delete('field_${fieldId}_ts');
    _cacheTimestamps.remove(fieldId);
    debugPrint('🗑️ Cleared cache for field: $fieldId');
  }

  /// مسح جميع Cache
  Future<void> clearAllCache() async {
    await _cacheBox.clear();
    _cacheTimestamps.clear();
    debugPrint('🗑️ Cleared all cache');
  }

  // ═══════════════════════════════════════════════════════════════════════
  // تحليل البيانات (Data Parsing)
  // ═══════════════════════════════════════════════════════════════════════

  /// تحويل بيانات Firestore إلى FieldModel
  FieldModel _parseFieldData(String fieldId, Map<String, dynamic> data) {
    // تحليل المهارات
    final Map<String, SkillModel> skills = {};
    if (data['skills'] != null) {
      final skillsData = data['skills'] as Map<String, dynamic>;
      
      for (var entry in skillsData.entries) {
        try {
          skills[entry.key] = _parseSkillData(entry.value);
        } catch (e) {
          debugPrint('⚠️ Error parsing skill ${entry.key}: $e');
        }
      }
    }

    return FieldModel(
      id: fieldId,
      name: data['name'] ?? '',
      nameEn: data['nameEn'] ?? '',
      description: data['description'] ?? '',
      icon: data['icon'] ?? 'code',
      category: data['category'] ?? '',
      careerPaths: List<String>.from(data['careerPaths'] ?? []),
      egyptianCompanies: List<String>.from(data['egyptianCompanies'] ?? []),
      globalCompanies: List<String>.from(data['globalCompanies'] ?? []),
      salaryRange: _parseSalaryRange(data['salaryRange']),
      demandLevel: data['demandLevel'] ?? 0,
      estimatedDuration: data['estimatedDuration'] ?? '',
      totalSkills: data['totalSkills'] ?? 0,
      roadmap: _parseRoadmapData(data['roadmap']),
      skills: skills,
    );
  }

  /// تحليل بيانات المهارة
  SkillModel _parseSkillData(Map<String, dynamic> data) {
    // تحليل الكورسات
    final List<CourseModel> courses = [];
    if (data['courses'] != null) {
      for (var courseData in data['courses']) {
        try {
          courses.add(_parseCourseData(courseData));
        } catch (e) {
          debugPrint('⚠️ Error parsing course: $e');
        }
      }
    }

    return SkillModel(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      nameEn: data['nameEn'] ?? '',
      description: data['description'] ?? '',
      icon: data['icon'] ?? '',
      level: data['level'] ?? 'foundation',
      difficulty: data['difficulty'] ?? 'medium',
      fieldId: data['fieldId'] ?? '', 
      importance: data['importance'] ?? 0,
      isMandatory: data['isMandatory'] ?? false,
      prerequisites: List<String>.from(data['prerequisites'] ?? []),
      estimatedDuration: data['estimatedDuration'] ?? '',
      whatYouWillLearn: List<String>.from(data['whatYouWillLearn'] ?? []),
      realWorldApplications: List<String>.from(data['realWorldApplications'] ?? []),
      courses: courses,
      learningPaths: _parseLearningPaths(data['learningPaths']),
      practiceProjects: _parseProjectIdeas(data['practiceProjects']),
    );
  }

  /// تحليل بيانات الكورس
  CourseModel _parseCourseData(Map<String, dynamic> data) {
    // priceAmount قد يأتي كـ String مثل "$12.99" أو كـ num أو null
    double parsedPriceAmount = 0.0;
    final rawPrice = data['priceAmount'];
    if (rawPrice != null) {
      if (rawPrice is num) {
        parsedPriceAmount = rawPrice.toDouble();
      } else if (rawPrice is String) {
        // إزالة الرموز غير الرقمية مثل "$" ثم التحويل
        final cleaned = rawPrice.replaceAll(RegExp(r'[^\d.]'), '');
        parsedPriceAmount = double.tryParse(cleaned) ?? 0.0;
      }
    }

    return CourseModel(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      platform: data['platform'] ?? '',
      language: data['language'] ?? '',
      level: data['level'] ?? '',
      price: data['price'] ?? 'free',
      priceAmount: parsedPriceAmount,
      duration: data['duration'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      enrollments: data['enrollments'] ?? 0,
      link: data['link'] ?? '',
      instructor: data['instructor'] ?? '',
      lastUpdated: data['lastUpdated'] ?? '',
      hasSubtitles: data['hasSubtitles'] ?? false,
      subtitleLanguages: List<String>.from(data['subtitleLanguages'] ?? []),
      hasCertificate: data['hasCertificate'] ?? false,
      thumbnailUrl: data['thumbnailUrl'],
      skillId: data['skillId'] ?? '',
      lessons: _parseLessons(data['lessons']),
    );
  }

  /// تحليل نطاق الراتب
  SalaryRange _parseSalaryRange(dynamic data) {
    if (data == null) {
      return const SalaryRange(
        beginner: '',
        intermediate: '',
        expert: '',
      );
    }

    return SalaryRange(
      beginner: data['beginner'] ?? '',
      intermediate: data['intermediate'] ?? '',
      expert: data['expert'] ?? '',
    );
  }

  /// تحليل بيانات خريطة الطريق
  RoadmapData _parseRoadmapData(dynamic data) {
    if (data == null) {
      return const RoadmapData(nodes: [], edges: []);
    }

    final nodes = <RoadmapNode>[];
    if (data['nodes'] != null) {
      for (var nodeData in data['nodes']) {
        nodes.add(RoadmapNode(
          skillId: nodeData['skillId'] ?? '',
          skillName: nodeData['skillName'] ?? '',
          level: nodeData['level'] ?? '',
          position: NodePosition(
            x: (nodeData['position']?['x'] ?? 0).toDouble(),
            y: (nodeData['position']?['y'] ?? 0).toDouble(),
          ),
          order: nodeData['order'] ?? 0,
        ));
      }
    }

    final edges = <RoadmapEdge>[];
    if (data['edges'] != null) {
      for (var edgeData in data['edges']) {
        edges.add(RoadmapEdge(
          from: edgeData['from'] ?? '',
          to: edgeData['to'] ?? '',
          type: edgeData['type'] ?? 'required',
        ));
      }
    }

    return RoadmapData(nodes: nodes, edges: edges);
  }

  /// تحليل مسارات التعلم
  List<LearningPath> _parseLearningPaths(dynamic data) {
    if (data == null) return [];

    final List<LearningPath> paths = [];
    for (var pathData in data) {
      paths.add(LearningPath(
        order: pathData['order'] ?? 0,
        title: pathData['title'] ?? '',
        description: pathData['description'] ?? '',
        topics: List<String>.from(pathData['topics'] ?? []),
        estimatedDuration: pathData['estimatedDuration'] ?? '',
      ));
    }

    return paths;
  }

  /// تحليل أفكار المشاريع
  List<ProjectIdea> _parseProjectIdeas(dynamic data) {
    if (data == null) return [];

    final List<ProjectIdea> projects = [];
    for (var projectData in data) {
      projects.add(ProjectIdea(
        title: projectData['title'] ?? '',
        description: projectData['description'] ?? '',
        difficulty: projectData['difficulty'] ?? '',
        estimatedTime: projectData['estimatedTime'] ?? '',
        skillsUsed: List<String>.from(projectData['skillsUsed'] ?? []),
        steps: List<String>.from(projectData['steps'] ?? []),
      ));
    }

    return projects;
  }

  /// تحليل قائمة الدروس
  List<LessonModel> _parseLessons(dynamic data) {
    if (data == null) return [];
    final List<LessonModel> lessons = [];
    for (var lessonData in data) {
      try {
        lessons.add(LessonModel(
          id: lessonData['id'] ?? '',
          title: lessonData['title'] ?? '',
          order: lessonData['order'] ?? 0,
          duration: lessonData['duration'] ?? '',
          description: lessonData['description'] ?? '',
        ));
      } catch (e) {
        debugPrint('⚠️ Error parsing lesson: $e');
      }
    }
    return lessons;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // تنظيف الموارد (Cleanup)
  // ═══════════════════════════════════════════════════════════════════════

  /// إغلاق جميع الاتصالات
  Future<void> dispose() async {
    // إلغاء جميع الاشتراكات
    for (var subscription in _firestoreSubscriptions.values) {
      await subscription.cancel();
    }
    _firestoreSubscriptions.clear();

    // إغلاق StreamControllers
    for (var controller in _fieldStreamControllers.values) {
      await controller.close();
    }
    _fieldStreamControllers.clear();

    // إعادة تعيين حالة التهيئة حتى يمكن إعادة initialize() بأمان
    _isInitialized = false;

    debugPrint('🔌 FirebaseService disposed');
  }
}