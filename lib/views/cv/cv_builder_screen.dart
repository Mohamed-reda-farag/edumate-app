// ============================================================
// cv_builder_screen.dart
// الشاشة الرئيسية لنظام بناء السيرة الذاتية (Wizard متعدد الخطوات)
// ============================================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../controllers/cv_controller.dart';
import '../../models/cv_model.dart';
import 'steps/step0_language.dart';
import 'steps/step1_personal.dart';
import 'steps/step2_summary.dart';
import 'steps/step3_experience.dart';
import 'steps/step4_education.dart';
import 'steps/step5_skills.dart';
import 'steps/step6_projects.dart';
import 'steps/step7_extras.dart';
import '../../widgets/cv_preview_button.dart';

class CVBuilderScreen extends StatelessWidget {
  const CVBuilderScreen({super.key});

  // Step labels
  static const _stepsAr = [
    'اللغة',
    'البيانات الشخصية',
    'الملخص',
    'الخبرات',
    'التعليم',
    'المهارات',
    'المشاريع',
    'إضافات',
  ];

  static const _stepsEn = [
    'Language',
    'Personal',
    'Summary',
    'Experience',
    'Education',
    'Skills',
    'Projects',
    'Extras',
  ];

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<CVController>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('بناء السيرة الذاتية'),
        centerTitle: true,
        actions: [
          // زر المشاركة
          const CVPreviewButton(),
          // زر التحميل المباشر على الهاتف
          Obx(() => ctrl.isDownloadingPdf.value
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.download_outlined),
                  tooltip: 'تحميل PDF على الهاتف',
                  onPressed: ctrl.downloadPdf,
                )),
        ],
      ),
      body: Obx(() {
        if (ctrl.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final cv = ctrl.cvModel.value;
        if (cv == null) return const SizedBox();

        final isArabic = cv.language == CVLanguage.arabic;
        final steps = isArabic ? _stepsAr : _stepsEn;

        return Column(
          children: [
            // ── Completion bar ──────────────────────────────
            _CompletionBanner(ctrl: ctrl),

            // ── Step indicator ──────────────────────────────
            _StepIndicator(
              steps: steps,
              current: ctrl.currentStep.value,
              onTap: ctrl.goToStep,
            ),

            // ── Step content ────────────────────────────────
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _stepWidget(ctrl.currentStep.value),
              ),
            ),

            // ── Bottom nav ──────────────────────────────────
            _BottomNav(
              ctrl: ctrl,
              totalSteps: steps.length,
              isArabic: isArabic,
            ),
          ],
        );
      }),
    );
  }

  Widget _stepWidget(int step) {
    switch (step) {
      case 0: return const Step0Language(key: ValueKey(0));
      case 1: return const Step1Personal(key: ValueKey(1));
      case 2: return const Step2Summary(key: ValueKey(2));
      case 3: return const Step3Experience(key: ValueKey(3));
      case 4: return const Step4Education(key: ValueKey(4));
      case 5: return const Step5Skills(key: ValueKey(5));
      case 6: return const Step6Projects(key: ValueKey(6));
      case 7: return const Step7Extras(key: ValueKey(7));
      default: return const SizedBox();
    }
  }
}

// ─── Completion Banner ────────────────────────────────────────
class _CompletionBanner extends StatelessWidget {
  const _CompletionBanner({required this.ctrl});
  final CVController ctrl;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final pct = ctrl.completionPercentage;
      final isArabic =
          ctrl.cvModel.value?.language == CVLanguage.arabic;

      return Container(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Text(
              isArabic
                  ? 'اكتمال السيرة الذاتية'
                  : 'CV Completion',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 6,
                  backgroundColor:
                      Theme.of(context).colorScheme.outlineVariant,
                  valueColor: AlwaysStoppedAnimation(
                    pct == 1.0
                        ? Colors.green
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${(pct * 100).round()}%',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      );
    });
  }
}

// ─── Step Indicator ───────────────────────────────────────────
class _StepIndicator extends StatelessWidget {
  const _StepIndicator({
    required this.steps,
    required this.current,
    required this.onTap,
  });

  final List<String> steps;
  final int current;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final surfaceVariant = Theme.of(context).colorScheme.surfaceVariant;

    return SizedBox(
      height: 62,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: steps.length,
        separatorBuilder: (_, __) => const SizedBox(width: 4),
        itemBuilder: (context, i) {
          final isActive = i == current;
          final isDone = i < current;
          return GestureDetector(
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isActive
                    ? primary
                    : isDone
                        ? primary.withOpacity(0.12)
                        : surfaceVariant,
                borderRadius: BorderRadius.circular(20),
                border: isDone
                    ? Border.all(color: primary.withOpacity(0.4))
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isDone)
                    Icon(Icons.check_circle,
                        size: 14,
                        color: primary)
                  else
                    Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isActive ? Colors.white : primary,
                      ),
                    ),
                  const SizedBox(width: 5),
                  Text(
                    steps[i],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isActive
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isActive
                          ? Colors.white
                          : isDone
                              ? primary
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Bottom Navigation ────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.ctrl,
    required this.totalSteps,
    required this.isArabic,
  });

  final CVController ctrl;
  final int totalSteps;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final step = ctrl.currentStep.value;
      final isFirst = step == 0;
      final isLast = step == totalSteps - 1;

      return Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Back button
            if (!isFirst)
              OutlinedButton.icon(
                onPressed: ctrl.prevStep,
                icon: const Icon(Icons.arrow_back_ios, size: 14),
                label: Text(isArabic ? 'السابق' : 'Back'),
              )
            else
              const SizedBox(width: 100),

            // Step counter
            Text(
              '${step + 1} / $totalSteps',
              style: Theme.of(context).textTheme.bodySmall,
            ),

            // Next / Finish button
            if (isLast)
              ElevatedButton.icon(
                onPressed: () async {
                  // نحفظ أولاً بدون Snackbar
                  await ctrl.saveCVSilent();
                  // بعد اكتمال الحفظ نرجع عبر GoRouter بدل Get.back()
                  // لتجنب تعارض GetX Snackbar مع navigation
                  if (context.mounted) context.pop();
                },
                icon: const Icon(Icons.check, size: 16),
                label: Text(isArabic ? 'حفظ وإنهاء' : 'Save & Finish'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              )
            else
              FilledButton.icon(
                onPressed: ctrl.nextStep,
                icon: const Icon(Icons.arrow_forward_ios, size: 14),
                label: Text(isArabic ? 'التالي' : 'Next'),
              ),
          ],
        ),
      );
    });
  }
}