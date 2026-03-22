// ============================================================
// cv_controller.dart
// GetX Controller — إدارة حالة نظام السيرة الذاتية
// ============================================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../models/cv_model.dart';
import '../services/cv_firestore_service.dart';
import '../services/cv_pdf_service.dart';
// navigatorKey مُعرَّف في router.dart ويُستخدم للوصول لـ context
// من خارج الـ widget tree بأمان
import '../../router.dart' show navigatorKey;

class CVController extends GetxController {
  // ── Dependencies ──────────────────────────────────────────
  final CVFirestoreService _firestoreService = CVFirestoreService();
  final CVPdfService _pdfService = CVPdfService();
  final _uuid = const Uuid();

  // ── State ─────────────────────────────────────────────────
  final Rx<CVModel?> cvModel = Rx<CVModel?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxBool isGeneratingPdf = false.obs;
  final RxBool isDownloadingPdf = false.obs;

  // Wizard step (0-7)
  final RxInt currentStep = 0.obs;

  // Current user id — set from AuthController
  String userId = '';

  // ── Lifecycle ─────────────────────────────────────────────
  Future<void> init(String uid) async {
    userId = uid;
    await loadCV();
  }

  // ── Load / Save ───────────────────────────────────────────
  Future<void> loadCV() async {
    isLoading.value = true;
    try {
      final loaded = await _firestoreService.fetchCV(userId);
      if (loaded != null) {
        cvModel.value = loaded;
      } else {
        cvModel.value = CVModel(userId: userId);
      }
    } catch (e) {
      _showError('حدث خطأ أثناء تحميل السيرة الذاتية');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveCV() async {
    if (cvModel.value == null) return;
    isSaving.value = true;
    try {
      await _firestoreService.saveCV(cvModel.value!);
      _showSuccess('تم الحفظ بنجاح ✓');
    } catch (e) {
      _showError('فشل الحفظ، حاول مرة أخرى');
    } finally {
      isSaving.value = false;
    }
  }

  // حفظ صامت بدون Snackbar — يُستخدم من زر "حفظ وإنهاء"
  // لتجنب تعارض GetX Snackbar مع GoRouter navigation
  Future<bool> saveCVSilent() async {
    if (cvModel.value == null) return false;
    isSaving.value = true;
    try {
      await _firestoreService.saveCV(cvModel.value!);
      return true;
    } catch (e) {
      debugPrint('saveCVSilent error: $e');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  // ── Language ──────────────────────────────────────────────
  void setLanguage(CVLanguage lang) {
    cvModel.value = cvModel.value?.copyWith(language: lang);
    cvModel.refresh();
  }

  // ── Personal Info ─────────────────────────────────────────
  void updatePersonalInfo(CVPersonalInfo info) {
    cvModel.value = cvModel.value?.copyWith(personalInfo: info);
    cvModel.refresh();
  }

  // ── Experience ────────────────────────────────────────────
  void addExperience() {
    final exp = CVExperience(id: _uuid.v4());
    final updated = List<CVExperience>.from(cvModel.value?.experiences ?? [])
      ..add(exp);
    cvModel.value = cvModel.value?.copyWith(experiences: updated);
    cvModel.refresh();
  }

  void updateExperience(CVExperience exp) {
    final updated = cvModel.value?.experiences
            .map((e) => e.id == exp.id ? exp : e)
            .toList() ??
        [];
    cvModel.value = cvModel.value?.copyWith(experiences: updated);
    cvModel.refresh();
  }

  void removeExperience(String id) {
    final updated =
        cvModel.value?.experiences.where((e) => e.id != id).toList() ?? [];
    cvModel.value = cvModel.value?.copyWith(experiences: updated);
    cvModel.refresh();
  }

  void reorderExperiences(int oldIndex, int newIndex) {
    final list = List<CVExperience>.from(cvModel.value?.experiences ?? []);
    if (newIndex > oldIndex) newIndex--;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    cvModel.value = cvModel.value?.copyWith(experiences: list);
    cvModel.refresh();
  }

  // ── Education ─────────────────────────────────────────────
  void addEducation() {
    final edu = CVEducation(id: _uuid.v4());
    final updated = List<CVEducation>.from(cvModel.value?.educations ?? [])
      ..add(edu);
    cvModel.value = cvModel.value?.copyWith(educations: updated);
    cvModel.refresh();
  }

  void updateEducation(CVEducation edu) {
    final updated = cvModel.value?.educations
            .map((e) => e.id == edu.id ? edu : e)
            .toList() ??
        [];
    cvModel.value = cvModel.value?.copyWith(educations: updated);
    cvModel.refresh();
  }

  void removeEducation(String id) {
    final updated =
        cvModel.value?.educations.where((e) => e.id != id).toList() ?? [];
    cvModel.value = cvModel.value?.copyWith(educations: updated);
    cvModel.refresh();
  }

  // ── Skills ────────────────────────────────────────────────
  void addSkill() {
    final skill = CVSkill(id: _uuid.v4());
    final updated = List<CVSkill>.from(cvModel.value?.skills ?? [])
      ..add(skill);
    cvModel.value = cvModel.value?.copyWith(skills: updated);
    cvModel.refresh();
  }

  void updateSkill(CVSkill skill) {
    final updated = cvModel.value?.skills
            .map((s) => s.id == skill.id ? skill : s)
            .toList() ??
        [];
    cvModel.value = cvModel.value?.copyWith(skills: updated);
    cvModel.refresh();
  }

  void removeSkill(String id) {
    final updated =
        cvModel.value?.skills.where((s) => s.id != id).toList() ?? [];
    cvModel.value = cvModel.value?.copyWith(skills: updated);
    cvModel.refresh();
  }

  // ── Projects ──────────────────────────────────────────────
  void addProject() {
    final project = CVProject(id: _uuid.v4());
    final updated = List<CVProject>.from(cvModel.value?.projects ?? [])
      ..add(project);
    cvModel.value = cvModel.value?.copyWith(projects: updated);
    cvModel.refresh();
  }

  void updateProject(CVProject project) {
    final updated = cvModel.value?.projects
            .map((p) => p.id == project.id ? project : p)
            .toList() ??
        [];
    cvModel.value = cvModel.value?.copyWith(projects: updated);
    cvModel.refresh();
  }

  void removeProject(String id) {
    final updated =
        cvModel.value?.projects.where((p) => p.id != id).toList() ?? [];
    cvModel.value = cvModel.value?.copyWith(projects: updated);
    cvModel.refresh();
  }

  // ── Certificates ──────────────────────────────────────────
  void addCertificate() {
    final cert = CVCertificate(id: _uuid.v4());
    final updated = List<CVCertificate>.from(cvModel.value?.certificates ?? [])
      ..add(cert);
    cvModel.value = cvModel.value?.copyWith(certificates: updated);
    cvModel.refresh();
  }

  void updateCertificate(CVCertificate cert) {
    final updated = cvModel.value?.certificates
            .map((c) => c.id == cert.id ? cert : c)
            .toList() ??
        [];
    cvModel.value = cvModel.value?.copyWith(certificates: updated);
    cvModel.refresh();
  }

  void removeCertificate(String id) {
    final updated =
        cvModel.value?.certificates.where((c) => c.id != id).toList() ?? [];
    cvModel.value = cvModel.value?.copyWith(certificates: updated);
    cvModel.refresh();
  }

  // ── Languages ─────────────────────────────────────────────
  void addLanguage() {
    final lang = CVLanguageEntry(id: _uuid.v4());
    final updated = List<CVLanguageEntry>.from(cvModel.value?.languages ?? [])
      ..add(lang);
    cvModel.value = cvModel.value?.copyWith(languages: updated);
    cvModel.refresh();
  }

  void updateLanguage(CVLanguageEntry lang) {
    final updated = cvModel.value?.languages
            .map((l) => l.id == lang.id ? lang : l)
            .toList() ??
        [];
    cvModel.value = cvModel.value?.copyWith(languages: updated);
    cvModel.refresh();
  }

  void removeLanguage(String id) {
    final updated =
        cvModel.value?.languages.where((l) => l.id != id).toList() ?? [];
    cvModel.value = cvModel.value?.copyWith(languages: updated);
    cvModel.refresh();
  }

  // ── PDF Generation ────────────────────────────────────────

  // مشاركة فقط — بدون تحميل على الهاتف
  Future<void> generateAndSharePdf() async {
    final cv = cvModel.value;
    if (cv == null || cv.personalInfo.fullName.isEmpty) {
      _showError('يرجى إدخال الاسم الكامل على الأقل');
      return;
    }
    isGeneratingPdf.value = true;
    try {
      await _pdfService.generateAndShare(cv);
    } catch (e, stack) {
      debugPrint('[CVController] generateAndSharePdf error: $e');
      debugPrint('[CVController] Stack: $stack');
      _showError('فشل المشاركة: $e');
    } finally {
      isGeneratingPdf.value = false;
    }
  }

  // تحميل مباشر على الهاتف — بدون share sheet
  Future<void> downloadPdf() async {
    final cv = cvModel.value;
    if (cv == null || cv.personalInfo.fullName.isEmpty) {
      _showError('يرجى إدخال الاسم الكامل على الأقل');
      return;
    }
    isDownloadingPdf.value = true;
    try {
      final path = await _pdfService.saveToDevice(cv);
      if (path != null) {
        _showSuccess('تم حفظ الملف في: $path');
      } else {
        _showError('فشل حفظ الملف على الجهاز');
      }
    } catch (e, stack) {
      debugPrint('[CVController] downloadPdf error: $e');
      debugPrint('[CVController] Stack: $stack');
      _showError('فشل التحميل: $e');
    } finally {
      isDownloadingPdf.value = false;
    }
  }

  // ── Wizard Navigation ─────────────────────────────────────
  void goToStep(int step) => currentStep.value = step;
  void nextStep() {
    if (currentStep.value < 7) currentStep.value++;
  }
  void prevStep() {
    if (currentStep.value > 0) currentStep.value--;
  }

  // ── Helpers ───────────────────────────────────────────────
  // نستخدم ScaffoldMessenger بدل Get.snackbar لأن التطبيق يستخدم
  // MaterialApp.router من GoRouter بدون GetMaterialApp
  void _showSuccess(String msg) {
    final context = _navigatorContext;
    if (context == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  void _showError(String msg) {
    final context = _navigatorContext;
    if (context == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  // جلب الـ context من navigatorKey الموجود في router.dart
  BuildContext? get _navigatorContext {
    try {
      return navigatorKey.currentContext;
    } catch (_) {
      return null;
    }
  }

  // Completion percentage for display
  double get completionPercentage {
    final cv = cvModel.value;
    if (cv == null) return 0;
    int filled = 0;
    const total = 8;
    if (cv.personalInfo.fullName.isNotEmpty) filled++;
    if (cv.personalInfo.summary?.isNotEmpty == true) filled++;
    if (cv.experiences.isNotEmpty) filled++;
    if (cv.educations.isNotEmpty) filled++;
    if (cv.skills.isNotEmpty) filled++;
    if (cv.projects.isNotEmpty) filled++;
    if (cv.certificates.isNotEmpty) filled++;
    if (cv.languages.isNotEmpty) filled++;
    return filled / total;
  }
}