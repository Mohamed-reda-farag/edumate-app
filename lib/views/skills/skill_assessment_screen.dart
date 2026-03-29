import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../controllers/global_learning_state.dart';
import '../../models/skill_model.dart';
import '../../config/api_keys.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data Models
// ─────────────────────────────────────────────────────────────────────────────

enum _MessageRole { user, ai }

class _ChatMessage {
  final _MessageRole role;
  final String text;
  final bool isTyping; // رسالة "..." المؤقتة

  const _ChatMessage({
    required this.role,
    required this.text,
    this.isTyping = false,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// SkillAssessmentScreen
// ─────────────────────────────────────────────────────────────────────────────

class SkillAssessmentScreen extends StatefulWidget {
  final String fieldId;
  final String skillId;
  final SkillModel skill;

  const SkillAssessmentScreen({
    super.key,
    required this.fieldId,
    required this.skillId,
    required this.skill,
  });

  @override
  State<SkillAssessmentScreen> createState() => _SkillAssessmentScreenState();
}

class _SkillAssessmentScreenState extends State<SkillAssessmentScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  // ── State ──────────────────────────────────────────────────────────────────
  final List<_ChatMessage> _messages = [];
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  // تاريخ المحادثة بالصيغة المطلوبة لـ Gemini API (multi-turn)
  final List<Map<String, dynamic>> _conversationHistory = [];

  bool _isLoading = false;
  bool _assessmentComplete = false;
  int _questionCount = 0;
  int _finalScore = 0;
  String _finalSummary = '';

  // ── متغيرات رصد السلوك (جديدة) ────────────────────────────────────────────
  int _exitCount = 0;       // عدد مرات الخروج من التطبيق أثناء الاختبار
  int _pasteCount = 0;      // عدد مرات النسخ/اللصق في الإجابات
  int _lastInputLength = 0; // لرصد اللصق بمقارنة طول النص

  // ── Constants ──────────────────────────────────────────────────────────────
  static const int _maxQuestions = 15;
  static const int _minQuestions = 8; // الحد الأدنى للأسئلة المطلوبة
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models'
      '/gemini-2.5-flash:generateContent';

  // ─────────────────────────────────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startAssessment();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── رصد الخروج من التطبيق أثناء الاختبار ────────────────────────────────
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && !_assessmentComplete) {
      _exitCount++;
      debugPrint('⚠️ Assessment: app paused (exitCount=$_exitCount)');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Assessment Initialization
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _startAssessment() async {
    final systemPrompt = _buildSystemPrompt(widget.skill);

    // بناء تاريخ المحادثة: system prompt كـ user + رد وهمي كـ model
    _conversationHistory.addAll([
      {
        'role': 'user',
        'parts': [{'text': systemPrompt}],
      },
      {
        'role': 'model',
        'parts': [{'text': 'فهمت، سأبدأ الاختبار الآن.'}],
      },
    ]);

    // إضافة رسالة "ابدأ" من المستخدم لتشغيل أول سؤال
    _conversationHistory.add({
      'role': 'user',
      'parts': [{'text': 'ابدأ الاختبار.'}],
    });

    await _fetchAiResponse();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Gemini API
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _fetchAiResponse({int retryCount = 0}) async {
    // إظهار مؤشر التحميل فقط في المحاولة الأولى
    if (retryCount == 0) {
      setState(() {
        _isLoading = true;
        _messages.add(const _ChatMessage(
          role: _MessageRole.ai,
          text: '...',
          isTyping: true,
        ));
      });
      _scrollToBottom();
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?key=${ApiKeys.geminiApiKey}'),
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': ApiKeys.geminiApiKey,
        },
        body: jsonEncode({
          'contents': _conversationHistory,
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 512,
          },
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiText = data['candidates']?[0]?['content']?['parts']?[0]?['text']
                as String? ??
            'لم أتمكن من توليد رد.';

        _conversationHistory.add({
          'role': 'model',
          'parts': [{'text': aiText}],
        });

        setState(() {
          _messages.removeWhere((m) => m.isTyping);
          _messages.add(_ChatMessage(role: _MessageRole.ai, text: aiText));
          _isLoading = false;
        });

        if (_isAssessmentComplete(aiText)) {
          _finalScore = _extractScore(aiText);
          _finalSummary = _extractSummary(aiText);
          setState(() => _assessmentComplete = true);
          await Future.delayed(const Duration(milliseconds: 800));
          if (mounted) await _handleAssessmentComplete();
        } else {
          if (_messages.where((m) => m.role == _MessageRole.user && !m.isTyping).isNotEmpty) {
            _questionCount++;
          }
        }
      } 
      else if (response.statusCode == 429) {
        if (retryCount < 3) { // الحد الأقصى للمحاولات (3 مرات)
          // وقت الانتظار يتضاعف: 2 ثواني، ثم 4، ثم 8
          final int waitTime = (1 << retryCount) * 2; 
          debugPrint('⚠️ خطأ 429: سيتم إعادة المحاولة بعد $waitTime ثوانٍ... (محاولة ${retryCount + 1})');
          
          await Future.delayed(Duration(seconds: waitTime));
          
          // إعادة استدعاء الدالة مع زيادة عداد المحاولات
          if (mounted) {
            return _fetchAiResponse(retryCount: retryCount + 1);
          }
        } else {
          _handleApiError('عذراً، الخادم يواجه ضغطاً حالياً. يرجى الانتظار دقيقة والمحاولة مجدداً.');
        }
      } 
      // معالجة باقي الأخطاء
      else {
        _handleApiError('خطأ في الاتصال: ${response.statusCode}');
      }
    } catch (e) {
      _handleApiError('حدث خطأ: $e');
    }

    if (retryCount == 0) _scrollToBottom();
  }

  void _handleApiError(String message) {
    if (!mounted) return;
    setState(() {
      _messages.removeWhere((m) => m.isTyping);
      _messages.add(_ChatMessage(role: _MessageRole.ai, text: message));
      _isLoading = false;
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // User Input
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _sendMessage() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _isLoading || _assessmentComplete) return;

    _inputCtrl.clear();
    _lastInputLength = 0; // إعادة تصفير بعد الإرسال

    // إضافة رسالة المستخدم للعرض
    setState(() {
      _messages.add(_ChatMessage(role: _MessageRole.user, text: text));
    });

    // إضافة رسالة المستخدم لتاريخ المحادثة
    _conversationHistory.add({
      'role': 'user',
      'parts': [{'text': text}],
    });

    _scrollToBottom();
    await _fetchAiResponse();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Assessment Complete Handler
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _handleAssessmentComplete() async {
    if (!mounted) return;
    final state = context.read<GlobalLearningState>();

    if (_finalScore < 0) {
      _showResultDialog(AssessmentOutcome.error, 0);
      return;
    }

    final skillProgress = state.userProfile
        ?.fieldProgress[widget.fieldId]
        ?.skillsProgress[widget.skillId];

    final outcome = await state.applyAssessmentResult(
      fieldId: widget.fieldId,
      skillId: widget.skillId,
      scorePercent: _finalScore,
      questionsAnswered: _questionCount,
      exitCount: _exitCount,
      pasteCount: _pasteCount,
      initialProgress: skillProgress?.initialProgress ?? 0,
    );

    if (!mounted) return;
    _showResultDialog(outcome, _finalScore);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Result Dialogs
  // ─────────────────────────────────────────────────────────────────────────

  void _showResultDialog(AssessmentOutcome outcome, int score) {
    switch (outcome) {
      case AssessmentOutcome.passed:
        _showPassedDialog();
      case AssessmentOutcome.needsReview:
        _showNeedsReviewDialog(score);
      case AssessmentOutcome.weak:
        _showWeakDialog(score);
      case AssessmentOutcome.cheating:
        _showCheatingDialog();
      case AssessmentOutcome.incomplete:
        _showIncompleteDialog();
      case AssessmentOutcome.maxAttemptsReached:
        _showMaxAttemptsDialog();
      case AssessmentOutcome.waitRequired:
        // نادراً ما يحدث هنا لأن الفحص يتم مسبقاً في CourseDetailsScreen
        // لكن نتعامل معه كـ fallback
        _showWaitRequiredDialog();
      case AssessmentOutcome.error:
        _showErrorDialog();
    }
  }

  void _showPassedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            '🎉 ممتاز!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.workspace_premium,
                  size: 64, color: Colors.amber),
              const SizedBox(height: 16),
              Text(
                'أثبتت إتقانك لمهارة "${widget.skill.name}"',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              _ScoreBadge(score: _finalScore, color: const Color(0xFF2ECC71)),
              _SummaryBox(summary: _finalSummary),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context); // إغلاق الـ Dialog
                  Navigator.pop(context); // العودة لشاشة تفاصيل الكورس
                },
                icon: const Icon(Icons.celebration),
                label: const Text('متابعة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNeedsReviewDialog(int score) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            '🔄 تحتاج مراجعة',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ScoreBadge(score: score, color: Colors.orange),
              _SummaryBox(summary: _finalSummary),
              const SizedBox(height: 16),
              const Text(
                'نتيجتك بين 50% و80%.\n'
                'الكورس الذي أكملته قد لا يكفي وحده.\n\n'
                'ماذا تريد أن تفعل؟',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
            ],
          ),
          actions: [
            // زر إعادة الكورس الحالي
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context); // إغلاق الـ Dialog
                  Navigator.pop(context); // العودة لـ CourseDetailsScreen
                },
                icon: const Icon(Icons.replay),
                label: const Text('إعادة الكورس الحالي'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // زر بدء كورس جديد — pop مرتين للوصول لـ SkillDetailsScreen
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context); // إغلاق الـ Dialog
                  Navigator.pop(context); // إغلاق SkillAssessmentScreen
                  Navigator.pop(context); // العودة لـ SkillDetailsScreen
                },
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('ابدأ كورساً جديداً'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF6C63FF),
                  side: const BorderSide(color: Color(0xFF6C63FF)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWeakDialog(int score) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            '⚠️ مستوى ضعيف',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ScoreBadge(score: score, color: Colors.red.shade400),
              _SummaryBox(summary: _finalSummary),
              const SizedBox(height: 16),
              Text(
                'نتيجتك $score% — تم إعادة تقدمك لنفس النسبة.\n\n'
                'واصل الدراسة وأكمل الكورس من حيث توقفت.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // إغلاق الـ Dialog
                  Navigator.pop(context); // العودة لـ CourseDetailsScreen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('حسناً، سأكمل الدراسة'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCheatingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            '❌ نتيجة منخفضة جداً',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ScoreBadge(score: _finalScore, color: Colors.red.shade700),
              _SummaryBox(summary: _finalSummary),
              const SizedBox(height: 16),
              const Text(
                'يبدو أنك لم تدرس الكورس فعلاً.\n\n'
                'تم إلغاء إكمال الكورس وعليك البدء من جديد.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // إغلاق الـ Dialog
                  Navigator.pop(context); // العودة لـ CourseDetailsScreen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('حسناً، سأبدأ من الصفر'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── dialogs جديدة ────────────────────────────────────────────────────────

  void _showIncompleteDialog() {
    final remainingAttempts = _getRemainingAttempts();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            '📋 أسئلة غير كافية',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.orange.withOpacity(0.4)),
                ),
                child: Text(
                  '$_questionCount / $_minQuestions',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'لم تُجب على العدد الكافي من الأسئلة.\n'
                'مطلوب الإجابة على $_minQuestions أسئلة على الأقل لإتمام التقييم.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
              if (remainingAttempts > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'المحاولات المتبقية: $remainingAttempts',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6C63FF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // إغلاق الـ Dialog
                  Navigator.pop(context); // العودة لـ CourseDetailsScreen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('حسناً'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMaxAttemptsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            '🔒 استُنفدت جميع المحاولات',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 56, color: Colors.grey[500]),
              const SizedBox(height: 16),
              Text(
                'استنفدت جميع محاولاتك الثلاث لاختبار مهارة "${widget.skill.name}".',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: const Text(
                  'يمكنك إعادة الاختبار بعد:\n'
                  '• إعادة الكورس الحالي من الصفر\n'
                  '• أو إكمال كورس جديد في نفس المهارة',
                  style: TextStyle(fontSize: 13, height: 1.6),
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // إغلاق الـ Dialog
                  Navigator.pop(context); // العودة لـ CourseDetailsScreen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('حسناً'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWaitRequiredDialog() {
    final state = context.read<GlobalLearningState>();
    final remainingMinutes = state.getRemainingWaitMinutes(
      fieldId: widget.fieldId,
      skillId: widget.skillId,
    );
    final waitText = _formatWaitTime(remainingMinutes);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            '⏳ يرجى الانتظار',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.schedule, size: 56, color: Colors.orange[400]),
              const SizedBox(height: 16),
              const Text(
                'يجب الانتظار قبل المحاولة التالية.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.orange.withOpacity(0.4)),
                ),
                child: Text(
                  'الوقت المتبقي: $waitText',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'خذ الوقت الكافي لمراجعة المادة قبل المحاولة التالية.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // إغلاق الـ Dialog
                  Navigator.pop(context); // العودة
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('حسناً'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Text('خطأ تقني'),
          content: const Text(
              'حدث خطأ أثناء حفظ نتيجة الاختبار. يرجى المحاولة مرة أخرى.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('حسناً'),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Exit Confirmation Dialog
  // ─────────────────────────────────────────────────────────────────────────

  Future<bool> _showExitConfirmation() async {
    if (_assessmentComplete) return true;

    return await showDialog<bool>(
          context: context,
          builder: (_) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Text('إنهاء الاختبار؟'),
              content: const Text(
                'هل تريد إنهاء الاختبار؟\nلن يُحفظ أي تقدم.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('تراجع',
                      style: TextStyle(color: Colors.grey[600])),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('إنهاء'),
                ),
              ],
            ),
          ),
        ) ??
        false;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  bool _isAssessmentComplete(String response) =>
      response.contains('[ASSESSMENT_COMPLETE]');

  int _extractScore(String response) {
    final match = RegExp(r'النتيجة:\s*(\d+)/100').firstMatch(response);
    if (match == null) {
      debugPrint('⚠️ Could not extract score from response');
      return -1; // قيمة خاصة تدل على فشل الـ parsing وليس نتيجة حقيقية
    }
    return int.parse(match.group(1)!);
  }

  String _extractSummary(String response) {
    final match =
        RegExp(r'الملخص:\s*(.+)', dotAll: true).firstMatch(response);
    return match?.group(1)?.trim() ?? '';
  }

  int _getRemainingAttempts() {
    final state = context.read<GlobalLearningState>();
    final skillProgress = state.userProfile
        ?.fieldProgress[widget.fieldId]
        ?.skillsProgress[widget.skillId];
    final used = skillProgress?.assessmentAttempts ?? 0;
    return (3 - used).clamp(0, 3);
  }

  /// تحويل الدقائق لنص مقروء (ساعات ودقائق)
  String _formatWaitTime(int totalMinutes) {
    if (totalMinutes <= 0) return 'وقت قصير';
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours == 0) return '$minutes دقيقة';
    if (minutes == 0) return '$hours ساعة';
    return '$hours ساعة و$minutes دقيقة';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _buildSystemPrompt(SkillModel skill) {
    final topics = skill.whatYouWillLearn.isNotEmpty
        ? skill.whatYouWillLearn.join('، ')
        : 'المفاهيم الأساسية للمهارة';

    return '''
أنت مختبِر متخصص في مهارة "${skill.name}".
مهمتك اختبار مستوى الطالب عبر محادثة قصيرة باللغة العربية.

القواعد الصارمة:
- اسأل سؤالاً واحداً فقط في كل رسالة
- الأسئلة تكون عملية ومتدرجة من سهل لصعب
- انتظر إجابة الطالب قبل السؤال التالي
- بعد كل إجابة: قيّمها بجملة واحدة قصيرة فقط ثم اسأل التالي مباشرة
- لا تطول في الشرح أو التعليق
- تتبع عدد الأسئلة بنفسك
- بعد السؤال الـ 15 أو إذا رأيت أن لديك تقييم كافٍ مبكراً،
  أنهِ الاختبار بهذا الشكل الحرفي الدقيق ولا تحيد عنه:

[ASSESSMENT_COMPLETE]
النتيجة: XX/100
الملخص: جملتان فقط عن مستوى الطالب

المواضيع التي تختبر فيها:
$topics

ابدأ مباشرة بالسؤال الأول.
''';
  }

  // ── handler موحّد للخروج ─────────────────────────────────────────────────
  Future<void> _handleExitAttempt() async {
    final shouldPop = await _showExitConfirmation();
    if (shouldPop && mounted) Navigator.pop(context);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          await _handleExitAttempt();
        },
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: _buildAppBar(),
          body: Column(
            children: [
              _buildProgressBar(),
              Expanded(child: _buildMessagesList()),
              if (!_assessmentComplete) _buildInputRow(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'اختبار مهارة ${widget.skill.name}',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      centerTitle: true,
      backgroundColor: const Color(0xFF6C63FF),
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: _handleExitAttempt,
      ),
      actions: [
        if (!_assessmentComplete)
          TextButton(
            onPressed: _handleExitAttempt,
            child: const Text(
              'إنهاء',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }

  Widget _buildProgressBar() {
    final progress = _assessmentComplete
        ? 1.0
        : (_questionCount / _maxQuestions).clamp(0.0, 1.0);

    // تحديد لون شريط التقدم: أخضر إذا وصل للحد الأدنى
    final barColor = _questionCount >= _minQuestions
        ? const Color(0xFF2ECC71)
        : const Color(0xFF6C63FF);

    return Container(
      color: const Color(0xFF6C63FF).withOpacity(0.08),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _assessmentComplete
                ? 'مكتمل ✅'
                : 'السؤال $_questionCount من $_maxQuestions',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    if (_messages.isEmpty && _isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
      );
    }

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        return _buildMessageBubble(msg);
      },
    );
  }

  Widget _buildMessageBubble(_ChatMessage msg) {
    final isAi = msg.role == _MessageRole.ai;

    // إخفاء مؤشر [ASSESSMENT_COMPLETE] من الرسالة المعروضة
    final displayText = msg.isTyping
        ? null
        : msg.text.replaceAll('[ASSESSMENT_COMPLETE]', '').trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isAi ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isAi) ...[
            // Avatar الـ AI
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFF6C63FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.psychology,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isAi
                    ? Theme.of(context).colorScheme.surfaceContainerHighest
                    : const Color(0xFF6C63FF),
                borderRadius: BorderRadius.only(
                  topRight: const Radius.circular(16),
                  topLeft: const Radius.circular(16),
                  bottomRight: isAi
                      ? const Radius.circular(16)
                      : const Radius.circular(4),
                  bottomLeft: isAi
                      ? const Radius.circular(4)
                      : const Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: msg.isTyping
                  ? const _TypingIndicator()
                  : Text(
                      displayText ?? '',
                      style: TextStyle(
                        color: isAi
                            ? Theme.of(context).colorScheme.onSurface
                            : Colors.white,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
            ),
          ),
          if (!isAi) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildInputRow() {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputCtrl,
              enabled: !_isLoading && !_assessmentComplete,
              textDirection: TextDirection.rtl,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              // ── رصد النسخ/اللصق ──────────────────────────────────────────
              onChanged: (value) {
                // إذا زاد النص بأكثر من 10 أحرف دفعة واحدة → احتمال لصق
                if (value.length - _lastInputLength > 10) {
                  _pasteCount++;
                  debugPrint(
                      '⚠️ Assessment: paste detected (pasteCount=$_pasteCount)');
                }
                _lastInputLength = value.length;
              },
              decoration: InputDecoration(
                hintText: _isLoading
                    ? 'انتظر رد المختبر...'
                    : 'اكتب إجابتك هنا...',
                hintStyle:
                    TextStyle(color: Colors.grey[400], fontSize: 13),
                filled: true,
                fillColor: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withOpacity(0.6),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(
                      color: Color(0xFF6C63FF), width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Material(
              color: _isLoading || _assessmentComplete
                  ? Colors.grey.shade300
                  : const Color(0xFF6C63FF),
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: _isLoading || _assessmentComplete
                    ? null
                    : _sendMessage,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Color(0xFF6C63FF),
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send,
                          color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Typing Indicator Widget (نقاط متحركة)
// ─────────────────────────────────────────────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
    _anim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i * 0.33;
            final t = ((_anim.value - delay) % 1.0).clamp(0.0, 1.0);
            final opacity =
                (t < 0.5 ? t * 2 : (1 - t) * 2).clamp(0.3, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: Colors.grey[500],
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Score Badge Widget
// ─────────────────────────────────────────────────────────────────────────────

class _ScoreBadge extends StatelessWidget {
  final int score;
  final Color color;

  const _ScoreBadge({required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        '$score / 100',
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Summary Box Widget
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryBox extends StatelessWidget {
  final String summary;

  const _SummaryBox({required this.summary});

  @override
  Widget build(BuildContext context) {
    if (summary.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.notes_outlined, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              summary,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}