import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/global_learning_state.dart';
import '../../models/user_model.dart';
import '../../router.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Consumer2<AuthController, GlobalLearningState>(
        builder: (context, auth, globalState, _) {
          final user = auth.currentUser;

          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return CustomScrollView(
            slivers: [
              _buildAppBar(context, user),
              SliverPadding(
                padding: const EdgeInsets.all(24.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          children: [
                            // بانر تحقق البريد (يظهر فقط إذا لم يُتحقق)
                            if (!auth.isEmailVerified)
                              _buildEmailVerificationBanner(auth),

                            _buildProfileHeader(context, user, auth),

                            // المجالات — تظهر فقط بعد اكتمال الاستبيان
                            if (globalState.hasUserProfile) ...[
                              const SizedBox(height: 24),
                              _buildFieldsSection(globalState),
                            ],

                            // ── زر بناء السيرة الذاتية ──────────────────
                            const SizedBox(height: 20),
                            _buildCVBuilderButton(context, user),

                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AppBar
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildAppBar(BuildContext context, UserModel user) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      backgroundColor: Theme.of(context).colorScheme.primary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => context.go('/home'),
      ),
      title: Text(
        'الملف الشخصي',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.white),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
          tooltip: 'الإعدادات',
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withOpacity(0.8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Email Verification Banner
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildEmailVerificationBanner(AuthController auth) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.amber.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'البريد الإلكتروني غير محقق',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'يُرجى التحقق من بريدك لتفعيل حسابك بالكامل',
                  style: TextStyle(
                      fontSize: 12, color: Colors.amber.shade800),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              await auth.sendEmailVerification();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(auth.errorMessage ?? 'تم إرسال البريد'),
                  backgroundColor:
                      auth.isSuccess ? Colors.green : Colors.red,
                ),
              );
              await auth.reloadUser();
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              foregroundColor: Colors.amber.shade900,
            ),
            child: const Text('إرسال مرة أخرى'),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Profile Header
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildProfileHeader(
      BuildContext context, UserModel user, AuthController auth) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // الصورة الشخصية
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  Theme.of(context).colorScheme.secondary,
                ],
              ),
            ),
            child: user.hasPhoto
                ? ClipOval(
                    child: Image.network(
                      user.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Text(
                          user.initials,
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      user.initials,
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 16),

          // الاسم — قابل للضغط للتعديل
          GestureDetector(
            onTap: () =>
                _showEditNameDialog(context, auth, user.displayName),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  user.displayName,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.edit,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // البريد + أيقونة التحقق
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.email, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                user.email,
                style:
                    TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              if (auth.isEmailVerified) ...[
                const SizedBox(width: 8),
                const Icon(Icons.verified, size: 16, color: Colors.green),
              ],
            ],
          ),

          if (user.bio != null && user.bio!.isNotEmpty) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _showEditBioDialog(context, auth, user.bio ?? ''),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      user.bio!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 14, color: Colors.grey.shade700),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.edit, size: 14,
                      color: Theme.of(context).colorScheme.primary),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _showEditBioDialog(context, auth, ''),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_circle_outline,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    'أضف نبذة عنك',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Edit Name Dialog — يتطلب تأكيد كلمة المرور
  // ═══════════════════════════════════════════════════════════════════════════

  void _showEditNameDialog(
      BuildContext context, AuthController auth, String currentName) {
    final nameCtrl = TextEditingController(text: currentName);
    final passCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscure = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.person_outline),
              SizedBox(width: 8),
              Text('تعديل الاسم'),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'الاسم الجديد',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: nameCtrl,
                  maxLength: 50,
                  decoration: InputDecoration(
                    hintText: 'أدخل الاسم الجديد',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length < 2) {
                      return 'الاسم قصير جداً';
                    }
                    if (v.length > 50) return 'الاسم طويل جداً';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                const Text(
                  'كلمة المرور الحالية (للتأكيد)',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: passCtrl,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    hintText: 'أدخل كلمة مرورك الحالية',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    suffixIcon: IconButton(
                      icon: Icon(obscure
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () =>
                          setDialogState(() => obscure = !obscure),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'كلمة المرور مطلوبة للتأكيد';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            Consumer<AuthController>(
              builder: (_, a, __) => ElevatedButton(
                onPressed: a.isLoading
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;

                        final success = await auth.updateDisplayName(
                          newName: nameCtrl.text.trim(),
                          currentPassword: passCtrl.text,
                        );

                        if (!mounted) return;
                        Navigator.pop(ctx);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'تم تحديث الاسم بنجاح ✅'
                                  : (auth.errorMessage ?? 'فشل التحديث'),
                            ),
                            backgroundColor:
                                success ? Colors.green : Colors.red,
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: a.isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('حفظ'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Edit Bio Dialog
  // ═══════════════════════════════════════════════════════════════════════════

  void _showEditBioDialog(
      BuildContext context, AuthController auth, String currentBio) {
    final bioCtrl = TextEditingController(text: currentBio);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.info_outline),
            SizedBox(width: 8),
            Text('النبذة الشخصية'),
          ],
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: bioCtrl,
            maxLength: 150,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'اكتب نبذة قصيرة عنك...',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              filled: true,
            ),
            validator: (v) {
              if (v != null && v.length > 150) {
                return 'النبذة طويلة جداً (الحد الأقصى 150 حرف)';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          Consumer<AuthController>(
            builder: (_, a, __) => ElevatedButton(
              onPressed: a.isLoading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      await auth.updateBio(bioCtrl.text.trim());
                      if (!mounted) return;
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            auth.isSuccess
                                ? 'تم تحديث النبذة بنجاح ✅'
                                : (auth.errorMessage ?? 'فشل التحديث'),
                          ),
                          backgroundColor:
                              auth.isSuccess ? Colors.green : Colors.red,
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: a.isLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child:
                          CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('حفظ'),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CV Builder Button
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCVBuilderButton(BuildContext context, UserModel user) {
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.secondary;

    return GestureDetector(
      onTap: () => AppNavigation.goToCVBuilder(user.uid),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primary, secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: primary.withOpacity(0.30),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // أيقونة
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.description_outlined,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),

            // النص
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'بناء السيرة الذاتية',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'متوافق مع نظام ATS  •  PDF احترافي  •  مشاركة فورية',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),

            // سهم
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.20),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Fields Section
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildFieldsSection(GlobalLearningState globalState) {
    final primaryFieldId = globalState.primaryField;
    final secondaryFieldId = globalState.secondaryField;

    final primaryField = primaryFieldId != null
        ? globalState.getFieldData(primaryFieldId)
        : null;
    final secondaryField = secondaryFieldId != null
        ? globalState.getFieldData(secondaryFieldId)
        : null;

    if (primaryField == null) return const SizedBox.shrink();

    final primaryProgress = globalState
            .userProfile?.fieldProgress[primaryFieldId]?.overallProgress ??
        0;
    final secondaryProgress = secondaryFieldId != null
        ? (globalState.userProfile
                ?.fieldProgress[secondaryFieldId]?.overallProgress ??
            0)
        : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.dashboard,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              const Text(
                'مجالاتي',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildFieldProgressCard(
            fieldName: primaryField.name,
            fieldIcon: primaryField.icon,
            progress: primaryProgress,
            isPrimary: true,
          ),

          if (secondaryField != null) ...[
            const SizedBox(height: 12),
            _buildFieldProgressCard(
              fieldName: secondaryField.name,
              fieldIcon: secondaryField.icon,
              progress: secondaryProgress,
              isPrimary: false,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFieldProgressCard({
    required String fieldName,
    required String fieldIcon,
    required int progress,
    required bool isPrimary,
  }) {
    final badgeColor = isPrimary ? Colors.purple : Colors.teal;
    final badgeLabel = isPrimary ? 'أساسي' : 'ثانوي';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(fieldIcon, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        fieldName,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badgeLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: badgeColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$progress%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress / 100,
              minHeight: 8,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                isPrimary
                    ? Theme.of(context).colorScheme.primary
                    : Colors.teal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}