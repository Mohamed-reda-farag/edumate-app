// ============================================================
// step1_personal.dart  — الخطوة 1: البيانات الشخصية
// ============================================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/cv_controller.dart';
import '../../../models/cv_model.dart';
import '../../../widgets/cv_field.dart';

class Step1Personal extends StatefulWidget {
  const Step1Personal({super.key});

  @override
  State<Step1Personal> createState() => _Step1PersonalState();
}

class _Step1PersonalState extends State<Step1Personal> {
  late final CVController _ctrl;
  late final TextEditingController _name;
  late final TextEditingController _jobTitle;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _city;
  late final TextEditingController _country;
  late final TextEditingController _linkedIn;
  late final TextEditingController _github;
  late final TextEditingController _portfolio;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<CVController>();
    final info = _ctrl.cvModel.value?.personalInfo ?? CVPersonalInfo();
    _name      = TextEditingController(text: info.fullName);
    _jobTitle  = TextEditingController(text: info.jobTitle);
    _email     = TextEditingController(text: info.email);
    _phone     = TextEditingController(text: info.phone);
    _city      = TextEditingController(text: info.city);
    _country   = TextEditingController(text: info.country);
    _linkedIn  = TextEditingController(text: info.linkedIn ?? '');
    _github    = TextEditingController(text: info.github ?? '');
    _portfolio = TextEditingController(text: info.portfolio ?? '');
  }

  void _save() {
    _ctrl.updatePersonalInfo(CVPersonalInfo(
      fullName: _name.text.trim(),
      jobTitle: _jobTitle.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      city: _city.text.trim(),
      country: _country.text.trim(),
      linkedIn: _linkedIn.text.trim().isEmpty ? null : _linkedIn.text.trim(),
      github: _github.text.trim().isEmpty ? null : _github.text.trim(),
      portfolio: _portfolio.text.trim().isEmpty ? null : _portfolio.text.trim(),
      summary: _ctrl.cvModel.value?.personalInfo.summary,
    ));
  }

  @override
  void dispose() {
    _save();
    _name.dispose(); _jobTitle.dispose(); _email.dispose();
    _phone.dispose(); _city.dispose(); _country.dispose();
    _linkedIn.dispose(); _github.dispose(); _portfolio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic =
        _ctrl.cvModel.value?.language == CVLanguage.arabic;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(context, isArabic ? 'البيانات الشخصية' : 'Personal Information', Icons.person_outline),
          const SizedBox(height: 16),

          CVField(
            ctrl: _name,
            label: isArabic ? 'الاسم الكامل *' : 'Full Name *',
            hint: isArabic ? 'مثال: أحمد محمد علي' : 'e.g. John Smith',
            icon: Icons.badge_outlined,
            onChanged: (_) => _save(),
          ),
          const SizedBox(height: 12),

          CVField(
            ctrl: _jobTitle,
            label: isArabic ? 'المسمى الوظيفي *' : 'Job Title *',
            hint: isArabic ? 'مثال: مطور Flutter' : 'e.g. Flutter Developer',
            icon: Icons.work_outline,
            onChanged: (_) => _save(),
          ),
          const SizedBox(height: 20),

          _sectionHeader(context, isArabic ? 'بيانات التواصل' : 'Contact', Icons.contact_phone_outlined),
          const SizedBox(height: 16),

          CVField(
            ctrl: _email,
            label: isArabic ? 'البريد الإلكتروني *' : 'Email *',
            hint: 'example@email.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) => _save(),
          ),
          const SizedBox(height: 12),

          CVField(
            ctrl: _phone,
            label: isArabic ? 'رقم الهاتف *' : 'Phone *',
            hint: '+20 10 XXXX XXXX',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            onChanged: (_) => _save(),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: CVField(
                  ctrl: _city,
                  label: isArabic ? 'المدينة' : 'City',
                  hint: isArabic ? 'القاهرة' : 'Cairo',
                  icon: Icons.location_city_outlined,
                  onChanged: (_) => _save(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CVField(
                  ctrl: _country,
                  label: isArabic ? 'الدولة' : 'Country',
                  hint: isArabic ? 'مصر' : 'Egypt',
                  icon: Icons.flag_outlined,
                  onChanged: (_) => _save(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _sectionHeader(context, isArabic ? 'روابط احترافية' : 'Professional Links', Icons.link),
          const SizedBox(height: 4),
          Text(
            isArabic ? 'اختياري — تزيد فرصك بنسبة 40%' : 'Optional — increases your chances by 40%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.green.shade600,
                ),
          ),
          const SizedBox(height: 16),

          CVField(
            ctrl: _linkedIn,
            label: 'LinkedIn',
            hint: 'linkedin.com/in/username',
            icon: Icons.business_center_outlined,
            keyboardType: TextInputType.url,
            onChanged: (_) => _save(),
          ),
          const SizedBox(height: 12),

          CVField(
            ctrl: _github,
            label: 'GitHub',
            hint: 'github.com/username',
            icon: Icons.code_outlined,
            keyboardType: TextInputType.url,
            onChanged: (_) => _save(),
          ),
          const SizedBox(height: 12),

          CVField(
            ctrl: _portfolio,
            label: isArabic ? 'Portfolio / الموقع الشخصي' : 'Portfolio / Website',
            hint: 'myportfolio.com',
            icon: Icons.language_outlined,
            keyboardType: TextInputType.url,
            onChanged: (_) => _save(),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      ],
    );
  }
}
