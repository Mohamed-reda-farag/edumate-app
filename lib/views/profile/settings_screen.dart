import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../controllers/global_learning_state.dart';
import '../../controllers/notification_controller.dart';
import '../../services/auth_service.dart';
import '../policy/about_app_screen.dart';
import '../policy/privacy_policy_screen.dart';
import '../policy/terms_of_service_screen.dart';
import '../notifications/notification_settings_screen.dart';
import 'field_selector_screen.dart';
import 'confirmation_dialogs.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<GlobalLearningState>(
        builder: (context, globalState, child) {
          if (globalState.isLoadingUserProfile) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // إدارة المجالات
                _buildFieldManagementSection(globalState),
                const SizedBox(height: 24),

                // تفضيلات التعلم
                _buildLearningPreferencesSection(globalState),
                const SizedBox(height: 24),

                // الأهداف والالتزام
                _buildGoalsSection(globalState),
                const SizedBox(height: 24),

                // الإشعارات
                _buildNotificationsSection(),
                const SizedBox(height: 24),

                // حول التطبيق
                _buildAboutSection(),
                const SizedBox(height: 24),

                // الحساب
                _buildAccountSection(),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // إدارة المجالات
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildFieldManagementSection(GlobalLearningState globalState) {
    final primaryFieldId = globalState.primaryField;
    final secondaryFieldId = globalState.secondaryField;
    final primaryField =
        primaryFieldId != null
            ? globalState.getFieldData(primaryFieldId)
            : null;
    final secondaryField =
        secondaryFieldId != null
            ? globalState.getFieldData(secondaryFieldId)
            : null;

    return _buildSection(
      title: 'مجالاتي',
      icon: Icons.dashboard_rounded,
      children: [
        _buildFieldCard(
          title: 'المجال الأساسي',
          fieldName: primaryField?.name ?? 'غير محدد',
          fieldIcon: primaryField?.icon ?? '📚',
          isPrimary: true,
          onChangeTap: () => _changePrimaryField(globalState),
        ),
        const SizedBox(height: 12),
        if (secondaryField != null)
          _buildFieldCard(
            title: 'المجال الثانوي',
            fieldName: secondaryField.name,
            fieldIcon: secondaryField.icon,
            isPrimary: false,
            onChangeTap: () => _changeSecondaryField(globalState),
            onDeleteTap: () => _removeSecondaryField(globalState),
          )
        else
          _buildAddSecondaryFieldCard(globalState),
      ],
    );
  }

  Widget _buildFieldCard({
    required String title,
    required String fieldName,
    required String fieldIcon,
    required bool isPrimary,
    required VoidCallback onChangeTap,
    VoidCallback? onDeleteTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(fieldIcon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  fieldName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: onChangeTap,
                tooltip: 'تغيير',
              ),
              if (onDeleteTap != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: onDeleteTap,
                  tooltip: 'حذف',
                  color: Colors.red,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddSecondaryFieldCard(GlobalLearningState globalState) {
    return InkWell(
      onTap: () => _addSecondaryField(globalState),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.primaryContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            style: BorderStyle.solid,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.add_circle_outline,
              color: Theme.of(context).colorScheme.primary,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'إضافة مجال ثانوي',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'وسّع معرفتك في مجال إضافي',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // تفضيلات التعلم
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildLearningPreferencesSection(GlobalLearningState globalState) {
    final preferences = globalState.userProfile?.preferences ?? {};
    final preferredTimesRaw = preferences['preferredTimes'];
    final List<String> preferredTimes;
    if (preferredTimesRaw is List) {
      preferredTimes = preferredTimesRaw.map((e) => e.toString()).toList();
    } else {
      preferredTimes = ['morning'];
    }
    final weekDaysCount =
        (preferences['weekDaysCount'] is int)
            ? preferences['weekDaysCount'] as int
            : int.tryParse(preferences['weekDaysCount']?.toString() ?? '') ?? 3;
    final sessionDuration =
        preferences['sessionDuration']?.toString() ?? 'medium';

    return _buildSection(
      title: 'تفضيلات التعلم',
      icon: Icons.access_time_rounded,
      children: [
        const Text(
          'الأوقات المفضلة',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _buildTimeChip('صباحاً', 'morning', preferredTimes, globalState),
            _buildTimeChip('ظهراً', 'afternoon', preferredTimes, globalState),
            _buildTimeChip('مساءً', 'evening', preferredTimes, globalState),
            _buildTimeChip('ليلاً', 'night', preferredTimes, globalState),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'أيام الأسبوع',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: weekDaysCount.toDouble(),
                min: 1,
                max: 7,
                divisions: 6,
                label: '$weekDaysCount أيام',
                onChanged: (value) {
                  _updatePreference(
                    globalState,
                    'weekDaysCount',
                    value.toInt(),
                  );
                },
              ),
            ),
            Text(
              '$weekDaysCount',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(width: 8),
            Text('أيام', style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'مدة الجلسة',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildDurationOption(
              'short',
              'قصيرة\n15-30 دقيقة',
              sessionDuration,
              globalState,
            ),
            const SizedBox(width: 8),
            _buildDurationOption(
              'medium',
              'متوسطة\n30-60 دقيقة',
              sessionDuration,
              globalState,
            ),
            const SizedBox(width: 8),
            _buildDurationOption(
              'long',
              'طويلة\n60+ دقيقة',
              sessionDuration,
              globalState,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeChip(
    String label,
    String value,
    List<String> selectedTimes,
    GlobalLearningState globalState,
  ) {
    final isSelected = selectedTimes.contains(value);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) async {
        List<String> newTimes = List.from(selectedTimes);
        if (selected) {
          newTimes.add(value);
        } else {
          if (newTimes.length > 1) newTimes.remove(value);
        }
        await _updatePreference(globalState, 'preferredTimes', newTimes);
      },
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
    );
  }

  Widget _buildDurationOption(
    String value,
    String label,
    String currentValue,
    GlobalLearningState globalState,
  ) {
    final isSelected = currentValue == value;
    return Expanded(
      child: InkWell(
        onTap: () => _updatePreference(globalState, 'sessionDuration', value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
              width: 2,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // الأهداف والالتزام
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildGoalsSection(GlobalLearningState globalState) {
    final preferences = globalState.userProfile?.preferences ?? {};
    final goalsRaw = preferences['goals'];
    final List<String> goals;
    if (goalsRaw is List) {
      goals = goalsRaw.map((e) => e.toString()).toList();
    } else {
      goals = ['professional'];
    }
    final commitmentLevel =
        preferences['commitmentLevel']?.toString() ?? 'medium';

    return _buildSection(
      title: 'أهدافك',
      icon: Icons.flag_rounded,
      children: [
        const Text(
          'ماذا تريد أن تحقق؟',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildGoalChip(
              'professional',
              '💼 المهارات المهنية',
              goals,
              globalState,
            ),
            _buildGoalChip('certificate', '🎓 الشهادات', goals, globalState),
            _buildGoalChip(
              'side_project',
              '🚀 مشروع جانبي',
              goals,
              globalState,
            ),
            _buildGoalChip(
              'career_change',
              '🔄 تغيير المسار',
              goals,
              globalState,
            ),
            _buildGoalChip('personal', '✨ التطوير الشخصي', goals, globalState),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'مستوى الالتزام',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        _buildCommitmentSelector(commitmentLevel, globalState),
      ],
    );
  }

  Widget _buildGoalChip(
    String value,
    String label,
    List<String> selectedGoals,
    GlobalLearningState globalState,
  ) {
    final isSelected = selectedGoals.contains(value);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        List<String> newGoals = List.from(selectedGoals);
        if (selected) {
          newGoals.add(value);
        } else {
          if (newGoals.length > 1) newGoals.remove(value);
        }
        _updatePreference(globalState, 'goals', newGoals);
      },
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
    );
  }

  Widget _buildCommitmentSelector(
    String currentValue,
    GlobalLearningState globalState,
  ) {
    return Row(
      children: [
        _buildCommitmentOption('light', 'خفيف', currentValue, globalState),
        const SizedBox(width: 8),
        _buildCommitmentOption('medium', 'متوسط', currentValue, globalState),
        const SizedBox(width: 8),
        _buildCommitmentOption('high', 'عالي', currentValue, globalState),
      ],
    );
  }

  Widget _buildCommitmentOption(
    String value,
    String label,
    String currentValue,
    GlobalLearningState globalState,
  ) {
    final isSelected = currentValue == value;
    return Expanded(
      child: InkWell(
        onTap: () => _updatePreference(globalState, 'commitmentLevel', value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
              width: 2,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // الإشعارات
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildNotificationsSection() {
    return Consumer<NotificationController>(
      builder: (context, notifController, _) {
        final isEnabled = notifController.settings.isEnabled;

        return _buildSection(
          title: 'الإشعارات',
          icon: Icons.notifications_rounded,
          children: [
            // تفعيل / إيقاف سريع
            Row(
              children: [
                Icon(
                  isEnabled
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_off_rounded,
                  color:
                      isEnabled
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isEnabled ? 'الإشعارات مُفعَّلة' : 'الإشعارات مُوقفة',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Switch(
                  value: isEnabled,
                  onChanged: (v) => notifController.toggleEnabled(v),
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
            const Divider(height: 24),

            // إعدادات الإشعارات المفصّلة
            _buildListTile(
              icon: Icons.tune_rounded,
              title: 'إعدادات الإشعارات',
              subtitle: 'أوقات التذكير، الملخصات، الصوت',
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationSettingsScreen(),
                    ),
                  ),
            ),
          ],
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // حول التطبيق
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildAboutSection() {
    return _buildSection(
      title: 'حول التطبيق',
      icon: Icons.info_rounded,
      children: [
        // ── جديد: حول التطبيق كشاشة كاملة ──
        _buildListTile(
          icon: Icons.apps_rounded,
          title: 'حول EduMate',
          subtitle: 'ما هو التطبيق وما الذي يقدمه',
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutAppScreen()),
              ),
        ),
        const Divider(height: 8),
        _buildListTile(
          icon: Icons.assignment,
          title: 'سياسة الخصوصية',
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
              ),
        ),
        _buildListTile(
          icon: Icons.description,
          title: 'شروط الاستخدام',
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()),
              ),
        ),
        _buildListTile(
          icon: Icons.email,
          title: 'تواصل معنا',
          subtitle: 'edumatesupport@gmail.com',
          onTap: () async {
            final Uri emailUri = Uri(
              scheme: 'mailto',
              path: 'edumatesupport@gmail.com',
              queryParameters: {
                'subject': 'استفسار من تطبيق EDUMATE',
              },
            );
            if (await canLaunchUrl(emailUri)) {
              await launchUrl(emailUri);
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('لم يتم العثور على تطبيق بريد إلكتروني'),
                  ),
                );
              }
            }
          },
        ),
        _buildListTile(
          icon: Icons.star_rate,
          title: 'قيّم التطبيق',
          subtitle: 'امنحنا نجمة على GitHub ⭐',
          onTap: () async {
            final Uri githubUri = Uri.parse(
              'https://github.com/Mohamed-reda-farag/edumate-app/stargazers',
            );
            if (await canLaunchUrl(githubUri)) {
              await launchUrl(githubUri, mode: LaunchMode.externalApplication);
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تعذّر فتح الرابط')),
                );
              }
            }
          },
        ),
        _buildListTile(
          icon: Icons.info_outline,
          title: 'الإصدار',
          trailing: const Text('1.0.0', style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // الحساب
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildAccountSection() {
    return _buildSection(
      title: 'الحساب',
      icon: Icons.person_rounded,
      children: [
        _buildListTile(
          icon: Icons.logout,
          title: 'تسجيل الخروج',
          titleColor: Colors.orange,
          iconColor: Colors.orange,
          onTap: _handleSignOut,
        ),
        _buildListTile(
          icon: Icons.delete_forever,
          title: 'حذف الحساب',
          titleColor: Colors.red,
          iconColor: Colors.red,
          onTap: _handleDeleteAccount,
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // مساعدات UI
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? iconColor,
    Color? titleColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: TextStyle(color: titleColor)),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing:
          trailing ?? (onTap != null ? const Icon(Icons.chevron_left) : null),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Helpers
  // ═══════════════════════════════════════════════════════════════════════════

  // ═══════════════════════════════════════════════════════════════════════════
  // Actions
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _changePrimaryField(GlobalLearningState globalState) async {
    final confirmed = await ConfirmationDialogs.showChangeFieldWarning(
      context,
      isPrimary: true,
    );
    if (!confirmed) return;

    final newFieldId = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder:
            (context) => FieldSelectorScreen(
              isPrimary: true,
              excludeFields: globalState.selectedFields,
            ),
      ),
    );
    if (newFieldId == null) return;

    try {
      await globalState.changeField(isPrimary: true, newFieldId: newFieldId);
      if (mounted) {
        ConfirmationDialogs.showSuccessSnackBar(
          context,
          'تم تغيير المجال الأساسي بنجاح',
        );
      }
    } catch (e) {
      if (mounted) {
        ConfirmationDialogs.showErrorSnackBar(
          context,
          'فشل تغيير المجال: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _changeSecondaryField(GlobalLearningState globalState) async {
    final confirmed = await ConfirmationDialogs.showChangeFieldWarning(
      context,
      isPrimary: false,
    );
    if (!confirmed) return;

    final newFieldId = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder:
            (context) => FieldSelectorScreen(
              isPrimary: false,
              excludeFields: globalState.selectedFields,
            ),
      ),
    );
    if (newFieldId == null) return;

    try {
      await globalState.changeField(isPrimary: false, newFieldId: newFieldId);
      if (mounted) {
        ConfirmationDialogs.showSuccessSnackBar(
          context,
          'تم تغيير المجال الثانوي بنجاح',
        );
      }
    } catch (e) {
      if (mounted) {
        ConfirmationDialogs.showErrorSnackBar(
          context,
          'فشل تغيير المجال: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _addSecondaryField(GlobalLearningState globalState) async {
    final newFieldId = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder:
            (context) => FieldSelectorScreen(
              isPrimary: false,
              excludeFields: globalState.selectedFields,
            ),
      ),
    );
    if (newFieldId == null) return;

    try {
      await globalState.addSecondaryField(newFieldId);
      if (mounted) {
        ConfirmationDialogs.showSuccessSnackBar(
          context,
          'تم إضافة المجال الثانوي بنجاح',
        );
      }
    } catch (e) {
      if (mounted) {
        ConfirmationDialogs.showErrorSnackBar(
          context,
          'فشل إضافة المجال: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _removeSecondaryField(GlobalLearningState globalState) async {
    final confirmed = await ConfirmationDialogs.showRemoveSecondaryFieldWarning(
      context,
    );
    if (!confirmed) return;

    try {
      await globalState.removeSecondaryField();
      if (mounted) {
        ConfirmationDialogs.showSuccessSnackBar(
          context,
          'تم حذف المجال الثانوي',
        );
      }
    } catch (e) {
      if (mounted) {
        ConfirmationDialogs.showErrorSnackBar(
          context,
          'فشل حذف المجال: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _updatePreference(
    GlobalLearningState globalState,
    String key,
    dynamic value,
  ) async {
    try {
      await globalState.updatePreferences({key: value});
    } catch (e) {
      if (mounted) {
        ConfirmationDialogs.showErrorSnackBar(context, 'فشل حفظ التفضيلات');
      }
    }
  }

  Future<void> _handleSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('تسجيل الخروج'),
            content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('تسجيل الخروج'),
              ),
            ],
          ),
    );
    if (confirmed != true) return;

    try {
      final globalState = context.read<GlobalLearningState>();
      await globalState.reset();
      await _authService.signOut();
      if (mounted) context.go('/login');
    } catch (e) {
      if (mounted) {
        ConfirmationDialogs.showErrorSnackBar(
          context,
          'فشل تسجيل الخروج: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _handleDeleteAccount() async {
    // ── الخطوة 1: تحذير وتأكيد بكتابة "حذف" ────────────────────────────
    final confirmed = await ConfirmationDialogs.showDeleteAccountWarning(
      context,
    );
    if (!confirmed) return;

    // ── الخطوة 2: طلب كلمة المرور (إعادة المصادقة) ──────────────────────
    final password = await ConfirmationDialogs.showReauthForDeleteDialog(
      context,
    );
    if (password == null || !mounted) return;

// ── الخطوة 3: حذف الحساب بالترتيب الصحيح ───────────────────────────
    try {
      // 1. التحقق من كلمة المرور وحذف Firebase Auth أولاً
      final result = await _authService.deleteAccount(password: password);

      if (!mounted) return;

      if (!result.isSuccessful) {
        ConfirmationDialogs.showErrorSnackBar(
          context,
          result.error ?? 'فشل حذف الحساب',
        );
        return;
      }

      // 2. حذف بيانات التعلم من Firestore بعد نجاح حذف Firebase Auth
      // نتجاهل الخطأ هنا لأن الحساب اتحذف بنجاح
      try {
        final globalState = context.read<GlobalLearningState>();
        await globalState.deleteUserProfile();
      } catch (e) {
        debugPrint('deleteUserProfile error (non-critical): $e');
      }

      if (!mounted) return;
      context.go('/login');
    } catch (e) {
      if (mounted) {
        ConfirmationDialogs.showErrorSnackBar(
          context,
          'فشل حذف الحساب: ${e.toString()}',
        );
      }
    }
  }
}
