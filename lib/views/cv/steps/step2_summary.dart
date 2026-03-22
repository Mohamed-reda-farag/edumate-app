// ============================================================
// step2_summary.dart  — الخطوة 2: الملخص المهني
// ============================================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/cv_controller.dart';
import '../../../models/cv_model.dart';

class Step2Summary extends StatefulWidget {
  const Step2Summary({super.key});

  @override
  State<Step2Summary> createState() => _Step2SummaryState();
}

class _Step2SummaryState extends State<Step2Summary> {
  late final CVController _ctrl;
  late final TextEditingController _summary;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<CVController>();
    _summary = TextEditingController(
      text: _ctrl.cvModel.value?.personalInfo.summary ?? '',
    );
  }

  void _save() {
    final info = _ctrl.cvModel.value?.personalInfo;
    if (info == null) return;
    _ctrl.updatePersonalInfo(
      CVPersonalInfo(
        fullName: info.fullName,
        jobTitle: info.jobTitle,
        email: info.email,
        phone: info.phone,
        city: info.city,
        country: info.country,
        linkedIn: info.linkedIn,
        github: info.github,
        portfolio: info.portfolio,
        summary: _summary.text.trim().isEmpty ? null : _summary.text.trim(),
      ),
    );
  }

  @override
  void dispose() {
    _save();
    _summary.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<CVController>();
    final isArabic = ctrl.cvModel.value?.language == CVLanguage.arabic;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic ? 'الملخص المهني' : 'Professional Summary',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            isArabic
                ? '3-5 جمل تُبرز مهاراتك وخبرتك وأهدافك المهنية. هذا القسم أول ما يقرأه نظام ATS!'
                : '3-5 sentences highlighting your skills, experience, and goals. This is the first section ATS scans!',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 20),

          // Main text field
          TextField(
            controller: _summary,
            maxLines: 7,
            maxLength: 600,
            textDirection:
                isArabic ? TextDirection.rtl : TextDirection.ltr,
            onChanged: (_) => _save(),
            decoration: InputDecoration(
              hintText: isArabic
                  ? 'اكتب ملخصك المهني هنا...'
                  : 'Write your professional summary here...',
              hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Theme.of(context)
                  .colorScheme
                  .surfaceVariant
                  .withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 20),

          // Tips
          _TipsCard(isArabic: isArabic),
        ],
      ),
    );
  }
}

class _TipsCard extends StatelessWidget {
  const _TipsCard({required this.isArabic});
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final tips = isArabic
        ? [
            'ابدأ بالمسمى الوظيفي وسنوات الخبرة',
            'اذكر 2-3 مهارات تقنية رئيسية',
            'أضف إنجازاً أو قيمة تضيفها للشركة',
            'تجنب الكلام العام مثل "شخص مجتهد"',
          ]
        : [
            'Start with your job title and years of experience',
            'Mention 2-3 key technical skills',
            'Include a measurable achievement or value-add',
            'Avoid generic phrases like "hard-working person"',
          ];

    final bgColor = Theme.of(context).colorScheme.secondaryContainer;
    final borderColor = Theme.of(context).colorScheme.secondary.withOpacity(0.4);
    final titleColor = Theme.of(context).colorScheme.onSecondaryContainer;
    final textColor = Theme.of(context).colorScheme.onSecondaryContainer;
    final bulletColor = Theme.of(context).colorScheme.secondary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('✅', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              isArabic ? 'نصائح ATS للملخص' : 'ATS Tips for Summary',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
            ),
          ]),
          const SizedBox(height: 8),
          for (final tip in tips)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: TextStyle(color: bulletColor, fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Text(
                      tip,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: textColor,
                          ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}