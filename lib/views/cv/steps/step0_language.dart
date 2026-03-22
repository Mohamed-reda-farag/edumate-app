// ============================================================
// step0_language.dart  — الخطوة 0: اختيار لغة السيرة الذاتية
// ============================================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/cv_controller.dart';
import '../../../models/cv_model.dart';

class Step0Language extends StatelessWidget {
  const Step0Language({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<CVController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'لغة السيرة الذاتية',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'اختر اللغة التي ستكتب بها سيرتك الذاتية.\nمعظم الشركات الدولية تفضل اللغة الإنجليزية.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 32),
          Obx(() {
            final current = ctrl.cvModel.value?.language ?? CVLanguage.english;
            return Column(
              children: [
                _LanguageCard(
                  icon: '🇬🇧',
                  titleAr: 'اللغة الإنجليزية',
                  titleEn: 'English CV',
                  descAr: 'مثالي للشركات الدولية وفرص العمل في الخارج',
                  isSelected: current == CVLanguage.english,
                  onTap: () => ctrl.setLanguage(CVLanguage.english),
                ),
                const SizedBox(height: 16),
                _LanguageCard(
                  icon: '🇸🇦',
                  titleAr: 'اللغة العربية',
                  titleEn: 'Arabic CV',
                  descAr: 'مناسب للشركات المحلية والحكومية',
                  isSelected: current == CVLanguage.arabic,
                  onTap: () => ctrl.setLanguage(CVLanguage.arabic),
                ),
                const SizedBox(height: 24),
                // ATS Tip card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.tertiary.withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('💡', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'نصيحة ATS',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onTertiaryContainer,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'نظام ATS (Applicant Tracking System) هو برنامج يستخدمه المسؤولون عن التوظيف لفلترة السير الذاتية تلقائياً قبل قراءتها. سيرتك الذاتية في هذا التطبيق مُصممة لتكون متوافقة 100% مع هذه الأنظمة.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onTertiaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.icon,
    required this.titleAr,
    required this.titleEn,
    required this.descAr,
    required this.isSelected,
    required this.onTap,
  });

  final String icon;
  final String titleAr;
  final String titleEn;
  final String descAr;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? primary.withOpacity(0.08)
              : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 36)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titleAr,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? primary : null,
                        ),
                  ),
                  Text(
                    titleEn,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    descAr,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: primary, size: 24),
          ],
        ),
      ),
    );
  }
}