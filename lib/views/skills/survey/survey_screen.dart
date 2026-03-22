import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../controllers/survey_state.dart';
import 'steps/primary_field_step.dart';
import 'steps/secondary_field_step.dart';
import 'steps/skill_levels_step.dart';
import 'steps/learning_schedule_step.dart';
import 'steps/session_duration_step.dart';
import 'steps/goals_step.dart';

class SurveyScreen extends StatelessWidget {
  const SurveyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SurveyState(),
      child: const _SurveyScreenContent(),
    );
  }
}

class _SurveyScreenContent extends StatefulWidget {
  const _SurveyScreenContent();

  @override
  State<_SurveyScreenContent> createState() => _SurveyScreenContentState();
}

class _SurveyScreenContentState extends State<_SurveyScreenContent> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onStepChanged(int step) {
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 200), // أسرع من 300
      curve: Curves.easeOut, // أسرع من easeInOut
    );
  }

  @override
  Widget build(BuildContext context) {
    final surveyState = context.watch<SurveyState>();
    Theme.of(context);

    // استماع لتغييرات الخطوة وتحريك الصفحة تلقائياً
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients && 
          _pageController.page?.round() != surveyState.currentStep) {
        _onStepChanged(surveyState.currentStep);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('إعداد حسابك'),
        centerTitle: true,
        leading: surveyState.canGoPrevious
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  surveyState.previousStep();
                  _onStepChanged(surveyState.currentStep);
                },
              )
            : null,
      ),
      body: Column(
        children: [
          // Progress indicator
          _buildProgressIndicator(context, surveyState),

          // Steps content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                PrimaryFieldStep(),
                SecondaryFieldStep(),
                SkillLevelsStep(),
                LearningScheduleStep(),
                SessionDurationStep(),
                GoalsStep(),
              ],
            ),
          ),

          // Navigation buttons
          _buildNavigationButtons(context, surveyState),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context, SurveyState state) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Step counter
          Text(
            'الخطوة ${state.currentStep + 1} من ${SurveyState.totalSteps}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Progress bar with dots
          Row(
            children: List.generate(
              SurveyState.totalSteps,
              (index) => Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    right: index < SurveyState.totalSteps - 1 ? 8 : 0,
                  ),
                  height: 8,
                  decoration: BoxDecoration(
                    color: index <= state.currentStep
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(BuildContext context, SurveyState state) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Previous button
            if (state.canGoPrevious)
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    state.previousStep();
                    _onStepChanged(state.currentStep);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('السابق'),
                ),
              ),

            if (state.canGoPrevious) const SizedBox(width: 12),

            // Next/Finish button
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: state.canGoNext
                    ? () {
                        if (state.isLastStep) {
                          _handleFinish(context, state);
                        } else {
                          state.nextStep();
                          _onStepChanged(state.currentStep);
                        }
                      }
                    : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  state.isLastStep ? 'إنهاء' : 'التالي',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleFinish(BuildContext context, SurveyState state) {
    final error = state.validate();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    // Navigate to processing screen using go_router
    context.go('/processing', extra: state.getCollectedData());
  }
}