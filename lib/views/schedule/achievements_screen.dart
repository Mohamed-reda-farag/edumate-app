import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/gamification_controller.dart';
import '../../models/gamification_model.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ctrl = context.read<GamificationController>();
      await ctrl.init();
      if (mounted && ctrl.newlyUnlocked.isNotEmpty) {
        _showNewAchievementsDialog(ctrl.newlyUnlocked);
      }
    });
  }

  void _showNewAchievementsDialog(List<Achievement> achievements) {
    showDialog(
      context: context,
      builder: (_) => _NewAchievementsDialog(
        achievements: achievements,
        onDismiss: () {
          Navigator.pop(context);
          context.read<GamificationController>().clearNewlyUnlocked();
        },
      ),
    );
  }

  IconData _iconForName(String iconName) {
    const map = {
      'school': Icons.school,
      'event_available': Icons.event_available,
      'military_tech': Icons.military_tech,
      'stars': Icons.stars,
      'menu_book': Icons.menu_book,
      'auto_stories': Icons.auto_stories,
      'local_fire_department': Icons.local_fire_department,
      'whatshot': Icons.whatshot,
      'emoji_events': Icons.emoji_events,
      'psychology': Icons.psychology,
      'balance': Icons.balance,
    };
    // [FIX S6th-4] كان يُعيد Icons.star صامتاً عند اسم غير معروف مما يُخفي
    // أخطاء التهجئة في Achievement.iconName أثناء التطوير.
    // assert يُوقف التطبيق في debug mode فقط → يجبر المطور على إضافة الأيقونة.
    assert(
      map.containsKey(iconName),
      'Achievement icon "$iconName" not found in _iconForName map. '
      'Add it to the map or fix the iconName in the Achievement definition.',
    );
    return map[iconName] ?? Icons.star;
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<GamificationController>();
    final cs = Theme.of(context).colorScheme;

    if (ctrl.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final data = ctrl.data;
    final unlockedIds = data?.unlockedAchievements.toSet() ?? {};
    final allAchievements = Achievement.all;

    return Scaffold(
      appBar: AppBar(title: const Text('الإنجازات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Level card
          if (data != null) ...[
            Card(
              color: cs.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: cs.primary,
                          child: Text(
                            '${data.level}',
                            style: TextStyle(
                              color: cs.onPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('المستوى ${data.level}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold)),
                              Text('${data.totalPoints} نقطة إجمالية'),
                              Text(
                                'تبقى ${data.pointsToNextLevel} نقطة للمستوى التالي',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: data.levelProgress,
                      borderRadius: BorderRadius.circular(4),
                      minHeight: 8,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Streak card
            Card(
              child: ListTile(
                leading: const Text('🔥', style: TextStyle(fontSize: 28)),
                title: Text('${data.currentStreak} أيام متتالية',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('أطول streak: ${data.longestStreak} يوم'),
                trailing: Chip(
                  label: Text('${data.weeklyPoints} هذا الأسبوع'),
                  backgroundColor: cs.secondaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Achievements grid
          Text('الإنجازات',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  )),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.1,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: allAchievements.length,
            itemBuilder: (ctx, i) {
              final a = allAchievements[i];
              final unlocked = unlockedIds.contains(a.id);
              return _AchievementCard(
                achievement: a,
                unlocked: unlocked,
                icon: _iconForName(a.iconName),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({
    required this.achievement,
    required this.unlocked,
    required this.icon,
  });

  final Achievement achievement;
  final bool unlocked;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      color: unlocked ? cs.tertiaryContainer : cs.surfaceVariant.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: unlocked ? cs.tertiary : Colors.grey,
            ),
            const SizedBox(height: 6),
            Text(
              achievement.titleAr,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: unlocked ? cs.onTertiaryContainer : Colors.grey,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              unlocked
                  ? '+${achievement.pointsReward} نقطة'
                  : achievement.descriptionAr,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: unlocked ? cs.tertiary : Colors.grey[600],
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _NewAchievementsDialog extends StatelessWidget {
  const _NewAchievementsDialog({
    required this.achievements,
    required this.onDismiss,
  });

  final List<Achievement> achievements;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Row(
        children: [
          Text('🎉 إنجاز جديد!', style: TextStyle(fontSize: 18)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: achievements
            .map((a) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: cs.tertiaryContainer,
                    child: Icon(Icons.emoji_events, color: cs.tertiary),
                  ),
                  title: Text(a.titleAr, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(a.descriptionAr),
                  trailing: Text('+${a.pointsReward}',
                      style: TextStyle(
                          color: cs.tertiary, fontWeight: FontWeight.bold)),
                ))
            .toList(),
      ),
      actions: [
        FilledButton(
          onPressed: onDismiss,
          child: const Text('رائع!'),
        ),
      ],
    );
  }
}