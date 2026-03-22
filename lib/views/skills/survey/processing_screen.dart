import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../controllers/global_learning_state.dart';

class ProcessingScreen extends StatefulWidget {
  final Map<String, dynamic> surveyData;

  const ProcessingScreen({
    super.key,
    required this.surveyData,
  });

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  int _currentStep = 0;
  bool _hasError = false;
  String? _errorMessage;

  final List<String> _steps = [
    'تحليل اهتماماتك',
    'إنشاء خطة التعلم',
    'تجهيز المحتوى المناسب',
    'تهيئة حسابك',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _processData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _processData() async {
    try {
      final globalState = context.read<GlobalLearningState>();
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('المستخدم غير مسجل الدخول');
      }

      // Step 1: Analyzing interests
      setState(() => _currentStep = 0);
      await Future.delayed(const Duration(milliseconds: 1000));

      // Step 2: Creating learning plan
      setState(() => _currentStep = 1);
      await Future.delayed(const Duration(milliseconds: 1000));

      // Step 3: Preparing content
      setState(() => _currentStep = 2);
      await Future.delayed(const Duration(milliseconds: 1000));

      // Step 4: Creating user profile with basic info
      setState(() => _currentStep = 3);

      // إنشاء البروفايل الأساسي
      await globalState.createUserProfile(
        userId: user.uid,
        primaryFieldId: widget.surveyData['primaryFieldId'],
        secondaryFieldId: widget.surveyData['secondaryFieldId'],
      );

      // حفظ باقي بيانات الاستبيان في preferences
      await _saveUserPreferences(user.uid);

      // ✅ تعليم الاستبيان كمكتمل
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('survey_completed', true);
      debugPrint('✅ Survey marked as completed');

      await Future.delayed(const Duration(milliseconds: 500));

      // Success - Navigate to home
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  /// حفظ تفضيلات المستخدم من الاستبيان
  Future<void> _saveUserPreferences(String userId) async {
    try {
      final preferences = {
        'skillLevels': widget.surveyData['skillLevels'] ?? {},
        'schedule': widget.surveyData['schedule'] ?? {},
        'sessionDuration': widget.surveyData['sessionDuration'],
        'goals': widget.surveyData['goals'] ?? {},
        'surveyCompletedAt': DateTime.now().toIso8601String(),
      };

      // حفظ في Firestore
      await FirebaseFirestore.instance
          .collection('user_profiles')
          .doc(userId)
          .update({
        'preferences': preferences,
      });

      debugPrint('✅ User preferences saved');
    } catch (e) {
      debugPrint('⚠️ Error saving preferences: $e');
      // لا نرمي الخطأ هنا لأن البروفايل الأساسي تم إنشاؤه
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_hasError) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 80,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 24),
                Text(
                  'حدث خطأ',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage ?? 'فشل في إنشاء الحساب',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: () => _processData(),
                    child: const Text('إعادة المحاولة'),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () => context.go('/survey'),
                    child: const Text('العودة للاستبيان'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated logo
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.school_rounded,
                    size: 60,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // Title
              Text(
                'جارٍ تخصيص رحلتك التعليمية',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // Steps
              ..._steps.asMap().entries.map((entry) {
                final index = entry.key;
                final step = entry.value;
                final isCompleted = _currentStep > index;
                final isActive = _currentStep == index;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Row(
                    children: [
                      // Step indicator
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? theme.colorScheme.primary
                              : isActive
                                  ? theme.colorScheme.primaryContainer
                                  : theme.colorScheme.surfaceContainerHighest,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isActive
                                ? theme.colorScheme.primary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: isCompleted
                              ? Icon(
                                  Icons.check,
                                  size: 18,
                                  color: theme.colorScheme.onPrimary,
                                )
                              : isActive
                                  ? SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: theme.colorScheme.primary,
                                      ),
                                    )
                                  : Text(
                                      '${index + 1}',
                                      style: theme.textTheme.bodySmall,
                                    ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Step text
                      Expanded(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 300),
                          style: theme.textTheme.bodyLarge!.copyWith(
                            color: isActive || isCompleted
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: isActive
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          child: Text(step),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 32),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (_currentStep + 1) / _steps.length,
                  minHeight: 8,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Progress text
              Text(
                '${((_currentStep + 1) / _steps.length * 100).toInt()}% مكتمل',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}