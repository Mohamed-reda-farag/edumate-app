import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/global_learning_state.dart';
import '../../models/skill_model.dart';


class FieldSkillLevelsScreen extends StatefulWidget {
  /// معرف المجال الذي سيتم تحديد مستويات مهاراته
  final String fieldId;

  /// اسم المجال — يُعرض في الـ AppBar
  final String fieldName;

  const FieldSkillLevelsScreen({
    super.key,
    required this.fieldId,
    required this.fieldName,
  });

  @override
  State<FieldSkillLevelsScreen> createState() => _FieldSkillLevelsScreenState();
}

class _FieldSkillLevelsScreenState extends State<FieldSkillLevelsScreen> {
  /// المستويات المختارة — كلها تبدأ بـ foundation
  final Map<String, String> _skillLevels = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAndInit());
  }

  Future<void> _loadAndInit() async {
    final state = context.read<GlobalLearningState>();

    // تحميل المجال إذا لم يكن محملاً
    if (state.getFieldData(widget.fieldId) == null) {
      await state.loadField(widget.fieldId);
    }

    if (!mounted) return;

    final field = state.getFieldData(widget.fieldId);
    if (field == null) {
      setState(() {
        _isLoading = false;
        _error = 'تعذّر تحميل بيانات المجال. تحقق من اتصالك وأعد المحاولة.';
      });
      return;
    }

    // تهيئة جميع المهارات بـ foundation
    for (final skill in field.skills.values) {
      _skillLevels[skill.id] = 'foundation';
    }

    setState(() => _isLoading = false);
  }

  /// تعيين مستوى واحد لجميع المهارات دفعة واحدة
  void _setAllSkillsLevel(String level) {
    setState(() {
      for (final key in _skillLevels.keys) {
        _skillLevels[key] = level;
      }
    });
  }

  /// حفظ وإرجاع النتيجة
  void _save() {
    Navigator.pop(context, Map<String, String>.from(_skillLevels));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('مستوياتك في ${widget.fieldName}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        // لا يوجد زر رجوع عادي — المستخدم يجب أن يحفظ
        automaticallyImplyLeading: false,
        actions: [
          // زر إلغاء في الـ AppBar
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text(
              'إلغاء',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
      body: _buildBody(),
      // زر الحفظ ثابت في الأسفل
      bottomNavigationBar: _isLoading || _error != null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text(
                    'حفظ وإضافة المجال',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _loadAndInit();
                },
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    return Consumer<GlobalLearningState>(
      builder: (context, state, _) {
        final field = state.getFieldData(widget.fieldId);
        if (field == null) {
          return const Center(child: CircularProgressIndicator());
        }

        // ترتيب المهارات حسب الأهمية
        final skills = field.skills.values.toList()
          ..sort((a, b) => b.importance.compareTo(a.importance));

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────────────
              Text(
                'حدد مستواك في كل مهارة',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'سيُحدد مستواك نقطة انطلاقك في كل مهارة. كن صادقاً — '
                'الاختبار لاحقاً سيُحدد تقدمك الفعلي.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),

              // ── تقييم سريع ───────────────────────────────────────────────
              OutlinedButton.icon(
                onPressed: () => _showQuickAssessmentDialog(context),
                icon: const Icon(Icons.flash_on_rounded, size: 18),
                label: const Text('تعيين مستوى واحد للكل'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── بطاقة تحذير ───────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withOpacity(0.4)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: Colors.amber, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'لا يمكن تعديل المستويات لاحقاً إلا بتغيير المجال.',
                        style: TextStyle(fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── قائمة المهارات ─────────────────────────────────────────────
              ...skills.map(
                (skill) => _SkillLevelCard(
                  skill: skill,
                  selectedLevel: _skillLevels[skill.id] ?? 'foundation',
                  onLevelChanged: (level) {
                    setState(() => _skillLevels[skill.id] = level);
                  },
                ),
              ),

              const SizedBox(height: 80), // مساحة لزر الحفظ
            ],
          ),
        );
      },
    );
  }

  void _showQuickAssessmentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعيين مستوى للجميع'),
        content: const Text('اختر مستوى عام لجميع المهارات:'),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        actionsPadding: const EdgeInsets.all(8),
        actions: [
          _QuickLevelTile(
            label: '🌱 مبتدئ في الجميع',
            onTap: () {
              _setAllSkillsLevel('foundation');
              Navigator.pop(context);
            },
          ),
          _QuickLevelTile(
            label: '📘 متوسط في الجميع',
            onTap: () {
              _setAllSkillsLevel('intermediate');
              Navigator.pop(context);
            },
          ),
          _QuickLevelTile(
            label: '🚀 متقدم في الجميع',
            onTap: () {
              _setAllSkillsLevel('advanced');
              Navigator.pop(context);
            },
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// بطاقة مهارة واحدة مع selector المستوى
// ─────────────────────────────────────────────────────────────────────────────

class _SkillLevelCard extends StatelessWidget {
  final SkillModel skill;
  final String selectedLevel;
  final ValueChanged<String> onLevelChanged;

  const _SkillLevelCard({
    required this.skill,
    required this.selectedLevel,
    required this.onLevelChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header المهارة ──────────────────────────────────────────────
            Row(
              children: [
                Text(skill.icon, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              skill.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (skill.isMandatory)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'إلزامي',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.onErrorContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        skill.nameEn,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Level Chips ─────────────────────────────────────────────────
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _LevelChip(
                  label: 'مبتدئ',
                  value: 'foundation',
                  groupValue: selectedLevel,
                  onSelected: onLevelChanged,
                ),
                _LevelChip(
                  label: 'متوسط',
                  value: 'intermediate',
                  groupValue: selectedLevel,
                  onSelected: onLevelChanged,
                ),
                _LevelChip(
                  label: 'متقدم',
                  value: 'advanced',
                  groupValue: selectedLevel,
                  onSelected: onLevelChanged,
                ),
                _LevelChip(
                  label: 'خبير',
                  value: 'expert',
                  groupValue: selectedLevel,
                  onSelected: onLevelChanged,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chip المستوى
// ─────────────────────────────────────────────────────────────────────────────

class _LevelChip extends StatelessWidget {
  final String label;
  final String value;
  final String groupValue;
  final ValueChanged<String> onSelected;

  const _LevelChip({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = value == groupValue;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(value),
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      selectedColor: theme.colorScheme.primaryContainer,
      checkmarkColor: theme.colorScheme.primary,
      labelStyle: TextStyle(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.onSurface,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// عنصر في Quick Assessment Dialog
// ─────────────────────────────────────────────────────────────────────────────

class _QuickLevelTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickLevelTile({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 15)),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14),
          ],
        ),
      ),
    );
  }
}