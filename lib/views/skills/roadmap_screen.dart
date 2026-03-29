import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../controllers/global_learning_state.dart';
import '../../models/field_model.dart';
import '../../models/skill_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Enums
// ─────────────────────────────────────────────────────────────────────────────
enum SkillState { locked, active, completed }

// ─────────────────────────────────────────────────────────────────────────────
// RoadmapScreen
// ─────────────────────────────────────────────────────────────────────────────
class RoadmapScreen extends StatefulWidget {
  final String fieldId;
  const RoadmapScreen({super.key, required this.fieldId});

  @override
  State<RoadmapScreen> createState() => _RoadmapScreenState();
}

class _RoadmapScreenState extends State<RoadmapScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final TransformationController _transformController =
      TransformationController();
  String? _selectedSkillId;

  // ── نتائج حساب الـ layout — تُحسب مرة واحدة عند تغيّر البيانات ──────────
  List<RoadmapNode> _cachedNodes = [];
  Map<String, SkillState> _cachedSkillStates = {};
  double _cachedCanvasWidth = 0;
  double _cachedCanvasHeight = 0;
  List<int> _cachedSortedLevelIndices = [];
  String? _cachedFieldId; // لرصد تغيّر المجال

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadField());
  }

  Future<void> _loadField() async {
    final state = context.read<GlobalLearningState>();
    if (state.getFieldData(widget.fieldId) == null) {
      await state.loadField(widget.fieldId);
    }
  }

  void _computeLayout(FieldModel field, GlobalLearningState state) {
    // إذا لم يتغير المجال — نُعيد حساب skillStates فقط (خفيف) دون إعادة حساب layout كامل
    if (_cachedFieldId == field.id && _cachedNodes.isNotEmpty) {
      _cachedSkillStates = {
        for (final node in _cachedNodes)
          node.skillId: _getSkillState(
              node.skillId, field.roadmap.edges, state, field.skills),
      };
      return;
    }

    const nodeWidth = 140.0;
    const nodeHeight = 60.0;
    const horizontalGap = 20.0;
    const verticalGap = 100.0;
    const topPadding = 60.0;
    const minSidePadding = 20.0;

    const levelOrder = {
      'foundation': 0,
      'intermediate': 1,
      'advanced': 2,
      'expert': 3,
    };

    final Map<String, RoadmapNode> nodeMap = {
      for (final n in field.roadmap.nodes) n.skillId: n,
    };

    int missingOrder = (nodeMap.values.isNotEmpty
            ? nodeMap.values.map((n) => n.order).reduce((a, b) => a > b ? a : b)
            : 0) +
        1;

    for (final entry in field.skills.entries) {
      if (!nodeMap.containsKey(entry.key)) {
        final skill = entry.value;
        final lvl = skill.level.isNotEmpty ? skill.level : 'foundation';
        nodeMap[entry.key] = RoadmapNode(
          skillId: entry.key,
          skillName: skill.name,
          level: lvl,
          position: const NodePosition(x: 0, y: 0),
          order: missingOrder++,
        );
      }
    }

    final Map<int, List<RoadmapNode>> levelGroups = {};
    for (final node in nodeMap.values) {
      final lvlIdx = levelOrder[node.level] ?? 0;
      (levelGroups[lvlIdx] ??= []).add(node);
    }

    for (final group in levelGroups.values) {
      group.sort((a, b) => a.order.compareTo(b.order));
    }

    int maxNodesInLevel = 1;
    for (final group in levelGroups.values) {
      if (group.length > maxNodesInLevel) maxNodesInLevel = group.length;
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final canvasWidth = max(
      screenWidth,
      minSidePadding * 2 +
          maxNodesInLevel * nodeWidth +
          (maxNodesInLevel - 1) * horizontalGap,
    );

    final Map<String, RoadmapNode> repositionedNodes = {};
    final sortedLevelIndices = levelGroups.keys.toList()..sort();

    for (final lvlIdx in sortedLevelIndices) {
      final group = levelGroups[lvlIdx]!;
      final rowY =
          topPadding + lvlIdx * (nodeHeight + verticalGap) + nodeHeight / 2;
      final totalRowWidth =
          group.length * nodeWidth + (group.length - 1) * horizontalGap;
      final startX = (canvasWidth - totalRowWidth) / 2 + nodeWidth / 2;

      for (int i = 0; i < group.length; i++) {
        final node = group[i];
        final newX = startX + i * (nodeWidth + horizontalGap);
        repositionedNodes[node.skillId] = RoadmapNode(
          skillId: node.skillId,
          skillName: node.skillName,
          level: node.level,
          order: node.order,
          position: NodePosition(x: newX, y: rowY),
        );
      }
    }

    final nodes = repositionedNodes.values.toList()
      ..sort((a, b) {
        final lvlA = levelOrder[a.level] ?? 0;
        final lvlB = levelOrder[b.level] ?? 0;
        if (lvlA != lvlB) return lvlA.compareTo(lvlB);
        return a.order.compareTo(b.order);
      });

    final levelsCount = levelGroups.length;
    final canvasHeight = topPadding +
        levelsCount * nodeHeight +
        (levelsCount - 1) * verticalGap +
        topPadding;

    // حساب skillStates مرة واحدة
    final skillStates = <String, SkillState>{
      for (final node in nodes)
        node.skillId:
            _getSkillState(node.skillId, field.roadmap.edges, state, field.skills),
    };

    // تخزين النتائج
    _cachedNodes = nodes;
    _cachedSkillStates = skillStates;
    _cachedCanvasWidth = canvasWidth;
    _cachedCanvasHeight = canvasHeight;
    _cachedSortedLevelIndices = sortedLevelIndices;
    _cachedFieldId = field.id;
  }

  /// يُستدعى عند أي تغيير في بيانات التقدم لإجبار إعادة الحساب
  void _invalidateCache() {
    _cachedFieldId = null;
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _transformController.dispose();
    super.dispose();
  }

  SkillState _getSkillState(
    String skillId,
    List<RoadmapEdge> edges,
    GlobalLearningState state,
    Map<String, SkillModel> allSkills,
  ) {
    final progress = state.userProfile
            ?.fieldProgress[widget.fieldId]
            ?.skillsProgress[skillId]
            ?.progressPercentage ??
        0;

    if (progress >= 80) return SkillState.completed;

    // تحديد مستوى المهارة ومستوى المستخدم الحالي
    const levelOrder = ['foundation', 'intermediate', 'advanced', 'expert'];
    final skillLevel = allSkills[skillId]?.level ?? 'foundation';
    final userLevel = state.userProfile
            ?.fieldProgress[widget.fieldId]
            ?.currentLevel ??
        'foundation';

    final skillLevelIndex = levelOrder.indexOf(skillLevel);
    final userLevelIndex = levelOrder.indexOf(userLevel);

    // المهارة مقفولة إذا كان مستواها يتجاوز مستوى المستخدم بأكثر من درجة واحدة
    if (skillLevelIndex > userLevelIndex + 1) return SkillState.locked;

    return SkillState.active;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Consumer<GlobalLearningState>(
        builder: (context, state, _) {
          final field = state.getFieldData(widget.fieldId);

          return Scaffold(
            backgroundColor: const Color(0xFF0F0F1E),
            appBar: _buildAppBar(context, field),
            body: Column(
              children: [
                if (field != null) _LegendBar(),
                Expanded(
                  child: state.isLoadingStaticData && field == null
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF6C63FF)),
                        )
                      : field == null
                          ? _buildError()
                          : _buildRoadmap(context, field, state),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, FieldModel? field) {
    return AppBar(
      backgroundColor: const Color(0xFF1A1A2E),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      title: Text(
        field != null ? 'خريطة ${field.name}' : 'خريطة التعلم',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 17,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.zoom_out_map, color: Colors.white70),
          onPressed: () {
            _transformController.value = Matrix4.identity();
          },
          tooltip: 'إعادة الضبط',
        ),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text('فشل تحميل خريطة التعلم',
              style: TextStyle(color: Colors.white, fontSize: 16)),
          const SizedBox(height: 16),
          ElevatedButton(
              onPressed: _loadField, child: const Text('إعادة المحاولة')),
        ],
      ),
    );
  }

Widget _buildRoadmap(
      BuildContext context, FieldModel field, GlobalLearningState state) {

    // حساب الـ layout مرة واحدة فقط (يتجاهل إذا لم تتغير البيانات)
    _computeLayout(field, state);

    const levelLabels = {
      0: 'الأساسيات',
      1: 'المتوسط',
      2: 'المتقدم',
      3: 'الخبير',
    };

    return InteractiveViewer(
      transformationController: _transformController,
      boundaryMargin: const EdgeInsets.all(100),
      minScale: 0.4,
      maxScale: 2.5,
      constrained: false,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, _) {
          return SizedBox(
            width: _cachedCanvasWidth,
            height: _cachedCanvasHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // تسميات المستويات
                for (final lvlIdx in _cachedSortedLevelIndices)
                  Positioned(
                    left: 0,
                    top: 60.0 + lvlIdx * (60.0 + 100.0) - 22,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        levelLabels[lvlIdx] ?? '',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.35),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                // رسم الروابط أولاً (تحت العقد)
                CustomPaint(
                  size: Size(_cachedCanvasWidth, _cachedCanvasHeight),
                  painter: _EdgePainter(
                    nodes: _cachedNodes,
                    edges: field.roadmap.edges,
                    skillStates: _cachedSkillStates,
                  ),
                ),
                // رسم العقد
                for (final node in _cachedNodes)
                  Positioned(
                    left: node.position.x - 140.0 / 2,
                    top: node.position.y - 60.0 / 2,
                    child: _SkillNode(
                      node: node,
                      skillState:
                          _cachedSkillStates[node.skillId] ?? SkillState.locked,
                      isSelected: _selectedSkillId == node.skillId,
                      pulseValue: _pulseController.value,
                      onTap: () {
                        setState(() => _selectedSkillId = node.skillId);
                        _showSkillPopup(
                          context,
                          node,
                          _cachedSkillStates[node.skillId]!,
                          state,
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSkillPopup(
    BuildContext context,
    RoadmapNode node,
    SkillState skillState,
    GlobalLearningState state,
  ) {
    final skillData = state.getSkillData(widget.fieldId, node.skillId);
    final skillProgress = state.userProfile
        ?.fieldProgress[widget.fieldId]
        ?.skillsProgress[node.skillId];
    final progressPct = skillProgress?.progressPercentage ?? 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A2E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // اسم المهارة + مستواها
              Text(
                node.skillName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              if (skillData != null)
                Text(
                  skillData.nameEn,
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              const SizedBox(height: 16),
              // شريط التقدم
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progressPct / 100,
                        minHeight: 8,
                        backgroundColor: Colors.white12,
                        valueColor: AlwaysStoppedAnimation(
                          skillState == SkillState.completed
                              ? const Color(0xFF2ECC71)
                              : const Color(0xFF6C63FF),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$progressPct%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // الأزرار
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        context.push(
                            '/skill-details/${widget.fieldId}/${node.skillId}');
                      },
                      icon: const Icon(Icons.info_outline, size: 18),
                      label: const Text('التفاصيل'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        // للمهارة النشطة: اذهب لأول كورس متاح مباشرةً
                        // للمهارة المكتملة: اذهب لتفاصيل المهارة للمراجعة
                        context.push(
                            '/skill-details/${widget.fieldId}/${node.skillId}');
                      },
                      icon: Icon(
                        skillState == SkillState.completed
                            ? Icons.replay
                            : Icons.play_arrow,
                        size: 18,
                      ),
                      label: Text(
                        skillState == SkillState.completed
                            ? 'مراجعة'
                            : 'ابدأ التعلم',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: skillState == SkillState.completed
                            ? const Color(0xFF2ECC71)
                            : const Color(0xFF6C63FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      // إعادة حساب skillStates عند العودة (قد تغيّر تقدم المستخدم)
      _invalidateCache();
      if (mounted) setState(() {});
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Edge Painter
// ─────────────────────────────────────────────────────────────────────────────
class _EdgePainter extends CustomPainter {
  final List<RoadmapNode> nodes;
  final List<RoadmapEdge> edges;
  final Map<String, SkillState> skillStates;

  const _EdgePainter({
    required this.nodes,
    required this.edges,
    required this.skillStates,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Map<String, Offset> positions = {
      for (final node in nodes)
        node.skillId: Offset(node.position.x, node.position.y),
    };

    for (final edge in edges) {
      final fromPos = positions[edge.from];
      final toPos = positions[edge.to];
      if (fromPos == null || toPos == null) continue;

      final fromState = skillStates[edge.from] ?? SkillState.locked;
      final toState = skillStates[edge.to] ?? SkillState.locked;

      Color lineColor;
      double strokeWidth;
      if (fromState == SkillState.completed &&
          toState == SkillState.completed) {
        lineColor = const Color(0xFF2ECC71);
        strokeWidth = 2.5;
      } else if (fromState == SkillState.completed) {
        lineColor = const Color(0xFF6C63FF);
        strokeWidth = 2.0;
      } else {
        lineColor = Colors.white24;
        strokeWidth = 1.5;
      }

      final paint = Paint()
        ..color = lineColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      // Draw curved edge
      final path = Path();
      path.moveTo(fromPos.dx, fromPos.dy);
      final cp1 = Offset(
        fromPos.dx + (toPos.dx - fromPos.dx) * 0.5,
        fromPos.dy,
      );
      final cp2 = Offset(
        fromPos.dx + (toPos.dx - fromPos.dx) * 0.5,
        toPos.dy,
      );
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, toPos.dx, toPos.dy);
      canvas.drawPath(path, paint);

      // Draw arrowhead
      final arrowPaint = Paint()
        ..color = lineColor
        ..strokeWidth = 2
        ..style = PaintingStyle.fill;

      final angle = atan2(toPos.dy - cp2.dy, toPos.dx - cp2.dx);
      const arrowSize = 8.0;
      final arrowPath = Path();
      arrowPath.moveTo(toPos.dx, toPos.dy);
      arrowPath.lineTo(
        toPos.dx - arrowSize * cos(angle - pi / 6),
        toPos.dy - arrowSize * sin(angle - pi / 6),
      );
      arrowPath.lineTo(
        toPos.dx - arrowSize * cos(angle + pi / 6),
        toPos.dy - arrowSize * sin(angle + pi / 6),
      );
      arrowPath.close();
      canvas.drawPath(arrowPath, arrowPaint);
    }
  }

  @override
  bool shouldRepaint(_EdgePainter oldDelegate) =>
      !mapEquals(oldDelegate.skillStates, skillStates) ||
      !listEquals(oldDelegate.edges, edges) ||
      !listEquals(oldDelegate.nodes, nodes);
}

// ─────────────────────────────────────────────────────────────────────────────
// Skill Node Widget
// ─────────────────────────────────────────────────────────────────────────────
class _SkillNode extends StatelessWidget {
  final RoadmapNode node;
  final SkillState skillState;
  final bool isSelected;
  final double pulseValue;
  final VoidCallback onTap;

  const _SkillNode({
    required this.node,
    required this.skillState,
    required this.isSelected,
    required this.pulseValue,
    required this.onTap,
  });

  Color get _nodeColor {
    switch (skillState) {
      case SkillState.completed:
        return const Color(0xFF2ECC71);
      case SkillState.active:
        return const Color(0xFF6C63FF);
      case SkillState.locked:
        return const Color(0xFF555566);
    }
  }

  Color get _glowColor {
    switch (skillState) {
      case SkillState.completed:
        return const Color(0xFF2ECC71).withOpacity(0.4);
      case SkillState.active:
        return const Color(0xFF6C63FF).withOpacity(0.5);
      case SkillState.locked:
        return Colors.transparent;
    }
  }

  IconData get _icon {
    switch (skillState) {
      case SkillState.completed:
        return Icons.check_circle;
      case SkillState.active:
        return Icons.play_circle;
      case SkillState.locked:
        return Icons.lock;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = skillState == SkillState.active
        ? 1.0 + pulseValue * 0.04
        : 1.0;

    return GestureDetector(
      onTap: skillState != SkillState.locked ? onTap : null,
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: 140,
          height: 60,
          decoration: BoxDecoration(
            color: _nodeColor.withOpacity(skillState == SkillState.locked ? 0.5 : 1.0),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.white : _nodeColor.withOpacity(0.6),
              width: isSelected ? 2.5 : 1.5,
            ),
            boxShadow: skillState != SkillState.locked
                ? [
                    BoxShadow(
                      color: _glowColor,
                      blurRadius: 12 + pulseValue * 8,
                      spreadRadius: 1,
                    )
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Icon(_icon, color: Colors.white, size: 18),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    node.skillName,
                    style: TextStyle(
                      color: Colors.white.withOpacity(
                          skillState == SkillState.locked ? 0.5 : 1.0),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Legend Bar
// ─────────────────────────────────────────────────────────────────────────────
class _LegendBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A2E),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: const [
          _LegendItem(color: Color(0xFF2ECC71), label: 'مكتملة'),
          _LegendItem(color: Color(0xFF6C63FF), label: 'نشطة'),
          _LegendItem(color: Color(0xFF555566), label: 'مقفلة'),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}