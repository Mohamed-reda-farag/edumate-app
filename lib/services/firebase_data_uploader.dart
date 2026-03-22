import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;


class FirebaseDataUploader {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  Future<void> uploadSingleField({
    required String fieldId,
    required String jsonPath,
  }) async {
    try {
      print('📤 جاري رفع المجال: $fieldId...');

      // قراءة ملف JSON
      final jsonString = await rootBundle.loadString(jsonPath);
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      // استخراج بيانات المجال
      final fieldData = jsonData['engineering_fields'][fieldId];

      if (fieldData == null) {
        throw Exception('المجال $fieldId غير موجود في الملف');
      }

      // رفع إلى Firestore
      await _firestore
          .collection('engineering_fields')
          .doc(fieldId)
          .set(fieldData);

      print('✅ تم رفع المجال: $fieldId بنجاح');
    } catch (e) {
      print('❌ خطأ في رفع المجال $fieldId: $e');
      rethrow;
    }
  }

  Future<void> uploadMultipleFields({
    required String jsonPath,
    List<String>? fieldIds, // null = كل المجالات
  }) async {
    try {
      print('📤 جاري رفع المجالات...');

      // قراءة ملف JSON
      final jsonString = await rootBundle.loadString(jsonPath);
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      final fieldsData = jsonData['engineering_fields'] as Map<String, dynamic>;

      // تحديد المجالات المراد رفعها
      final targetFields = fieldIds ?? fieldsData.keys.toList();

      // استخدام Batch للأداء الأفضل
      final batch = _firestore.batch();

      for (var fieldId in targetFields) {
        final fieldData = fieldsData[fieldId];
        if (fieldData == null) {
          print('⚠️ تخطي المجال $fieldId - غير موجود');
          continue;
        }

        final docRef = _firestore
            .collection('engineering_fields')
            .doc(fieldId);

        batch.set(docRef, fieldData);
      }

      // تنفيذ Batch
      await batch.commit();

      print('✅ تم رفع ${targetFields.length} مجالات بنجاح');
    } catch (e) {
      print('❌ خطأ في رفع المجالات: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // تحديث مجال موجود
  // ═══════════════════════════════════════════════════════════════════════

  /// تحديث جزء من بيانات مجال
  /// 
  /// مثال:
  /// ```dart
  /// await uploader.updateField(
  ///   fieldId: 'web_development',
  ///   updates: {
  ///     'demandLevel': 98,
  ///     'description': 'وصف جديد...',
  ///   },
  /// );
  /// ```
  Future<void> updateField({
    required String fieldId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      print('🔄 جاري تحديث المجال: $fieldId...');

      await _firestore
          .collection('engineering_fields')
          .doc(fieldId)
          .update(updates);

      print('✅ تم تحديث المجال: $fieldId');
    } catch (e) {
      print('❌ خطأ في تحديث المجال $fieldId: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // إضافة مهارة جديدة لمجال
  // ═══════════════════════════════════════════════════════════════════════

  /// إضافة مهارة جديدة لمجال موجود
  /// 
  /// مثال:
  /// ```dart
  /// await uploader.addSkillToField(
  ///   fieldId: 'web_development',
  ///   skillId: 'typescript',
  ///   skillData: {
  ///     'name': 'TypeScript',
  ///     'level': 'intermediate',
  ///     // ... باقي البيانات
  ///   },
  /// );
  /// ```
  Future<void> addSkillToField({
    required String fieldId,
    required String skillId,
    required Map<String, dynamic> skillData,
  }) async {
    try {
      print('➕ جاري إضافة المهارة $skillId للمجال $fieldId...');

      await _firestore
          .collection('engineering_fields')
          .doc(fieldId)
          .update({
        'skills.$skillId': skillData,
      });

      print('✅ تم إضافة المهارة بنجاح');
    } catch (e) {
      print('❌ خطأ في إضافة المهارة: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // حذف مجال (احذر!)
  // ═══════════════════════════════════════════════════════════════════════

  /// حذف مجال من Firestore
  /// ⚠️ تحذير: هذه العملية لا يمكن التراجع عنها!
  Future<void> deleteField(String fieldId) async {
    try {
      print('🗑️ جاري حذف المجال: $fieldId...');

      await _firestore
          .collection('engineering_fields')
          .doc(fieldId)
          .delete();

      print('✅ تم حذف المجال: $fieldId');
    } catch (e) {
      print('❌ خطأ في حذف المجال $fieldId: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // التحقق من البيانات
  // ═══════════════════════════════════════════════════════════════════════

  /// التحقق من وجود المجال
  Future<bool> fieldExists(String fieldId) async {
    try {
      final doc = await _firestore
          .collection('engineering_fields')
          .doc(fieldId)
          .get();

      return doc.exists;
    } catch (e) {
      print('❌ خطأ في التحقق من المجال: $e');
      return false;
    }
  }

  /// الحصول على قائمة بكل المجالات الموجودة
  Future<List<String>> getAllFieldIds() async {
    try {
      final snapshot = await _firestore
          .collection('engineering_fields')
          .get();

      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print('❌ خطأ في جلب المجالات: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // مثال على الاستخدام الكامل
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> initialDataSetup() async {
    try {
      print('🚀 بدء إعداد البيانات الأولية...\n');

      // رفع جميع المجالات من ملف واحد
      await uploadMultipleFields(
        jsonPath: 'assets/data/Engineering_Fields.json',
      );

      // 3. التحقق من النجاح
      final existingFields = await getAllFieldIds();
      print('\n📊 المجالات الموجودة حالياً:');
      for (var field in existingFields) {
        print('   ✓ $field');
      }

      print('\n✅ تم إعداد البيانات بنجاح!');
    } catch (e) {
      print('\n❌ فشل إعداد البيانات: $e');
      rethrow;
    }
  }
}