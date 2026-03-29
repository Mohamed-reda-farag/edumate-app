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
import 'field_settings_screen.dart';
import 'learning_preferences_screen.dart';
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
                // إدارة المجالات — زر للانتقال لشاشة منفصلة
                _buildNavigationTile(
                  icon: Icons.dashboard_rounded,
                  title: 'مجالاتي',
                  subtitle: 'إدارة المجال الأساسي والثانوي',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FieldSettingsScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // تفضيلات التعلم والأهداف — زر للانتقال لشاشة منفصلة
                _buildNavigationTile(
                  icon: Icons.tune_rounded,
                  title: 'تفضيلات التعلم والأهداف',
                  subtitle: 'الأوقات، أيام الأسبوع، مدة الجلسة، والأهداف',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LearningPreferencesScreen(),
                    ),
                  ),
                ),
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

  /// زر انتقال لشاشة كاملة — يُستخدم لقسم المجالات
  Widget _buildNavigationTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_left,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Helpers
  // ═══════════════════════════════════════════════════════════════════════════

  // ═══════════════════════════════════════════════════════════════════════════
  // Actions
  // ═══════════════════════════════════════════════════════════════════════════

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