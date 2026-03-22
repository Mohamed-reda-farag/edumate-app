// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';

/// شاشة انتظار تأكيد البريد الإلكتروني
class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  Timer? _checkTimer;
  bool _isChecking = false;
  bool _resendCooldown = false;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;

  // ✅ FIX #13: عداد للمحاولات الفاشلة لتجنب polling لا نهائي
  int _failedPollAttempts = 0;
  static const int _maxFailedPollAttempts = 30; // ~2 دقيقة

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    // ✅ إلغاء أي timer سابق قبل إنشاء جديد — يمنع تراكم timers عند rebuild
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) _checkVerification(silent: true);
    });
  }

  Future<void> _checkVerification({bool silent = false}) async {
    if (_isChecking || !mounted) return;
    setState(() => _isChecking = true);

    final auth = context.read<AuthController>();
    final verified = await auth.reloadUser();

    if (!mounted) return;
    setState(() => _isChecking = false);

    if (verified) {
      _checkTimer?.cancel();
      // ✅ لا نحتاج context.go هنا — Firebase سيُطلق onLogin تلقائياً
      // والـ Router سيوجّه للوجهة الصحيحة (/welcome لمستخدم جديد) بعد انتهاء transitioning
    } else {
      // ✅ FIX #13: نوقف الـ polling بعد عدد معين من المحاولات الفاشلة
      _failedPollAttempts++;
      if (_failedPollAttempts >= _maxFailedPollAttempts) {
        _checkTimer?.cancel();
      }

      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لم يتم تأكيد البريد بعد. تحقق من صندوق الوارد'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _resendEmail() async {
    if (_resendCooldown) return;

    final auth = context.read<AuthController>();
    await auth.sendEmailVerification();

    if (!mounted) return;

    // ✅ FIX #7: نتحقق من isSuccess بشكل صحيح
    if (auth.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إرسال رابط التحقق مجدداً'),
          backgroundColor: Colors.green,
        ),
      );
      _startCooldown(60);
      // إعادة تشغيل الـ polling إذا كان متوقفاً
      if (_checkTimer == null || !_checkTimer!.isActive) {
        _failedPollAttempts = 0;
        _startPolling();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.statusMessage ?? 'حدث خطأ أثناء إرسال البريد'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _startCooldown(int seconds) {
    setState(() {
      _resendCooldown = true;
      _cooldownSeconds = seconds;
    });
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _cooldownSeconds--);
      if (_cooldownSeconds <= 0) {
        timer.cancel();
        setState(() => _resendCooldown = false);
      }
    });
  }

  void _skip() {
    _checkTimer?.cancel();
    context.read<AuthController>().completeRegistration();
    // ✅ لا نحتاج context.go هنا — الـ Router سيوجّه تلقائياً بعد completeRegistration
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final email = auth.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              const Spacer(),

              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mark_email_unread_outlined,
                  size: 60,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),

              Text(
                'تأكيد البريد الإلكتروني',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              Text(
                'أرسلنا رابط التحقق إلى',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                email,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'افتح بريدك الإلكتروني واضغط على رابط التحقق\nسيتم الانتقال تلقائياً بعد التأكيد',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              if (_isChecking)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'جاري التحقق...',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),

              // ✅ FIX #13: رسالة عند توقف الـ polling
              if (_failedPollAttempts >= _maxFailedPollAttempts)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'لم يتم اكتشاف التحقق تلقائياً. اضغط "تحقق الآن" بعد فتح الرابط.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isChecking ? null : () => _checkVerification(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('لقد أكدت البريد، تحقق الآن'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: (auth.isLoading || _resendCooldown) ? null : _resendEmail,
                  icon: auth.isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_outlined),
                  label: Text(
                    _resendCooldown
                        ? 'إعادة الإرسال بعد $_cooldownSeconds ثانية'
                        : 'إعادة إرسال رابط التحقق',
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextButton(
                onPressed: _skip,
                child: Text(
                  'تخطي الآن (يمكن التأكيد لاحقاً)',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}