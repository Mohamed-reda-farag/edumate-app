import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/notification_controller.dart';
import '../../models/notification_history_model.dart';

// ══════════════════════════════════════════════════════════════════════════════
// NotificationHistoryScreen
// ══════════════════════════════════════════════════════════════════════════════

class NotificationHistoryScreen extends StatefulWidget {
  const NotificationHistoryScreen({super.key});

  @override
  State<NotificationHistoryScreen> createState() =>
      _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState
    extends State<NotificationHistoryScreen> {
  // null = الكل
  NotificationCategory? _selectedFilter;

  @override
  void initState() {
    super.initState();
    // تحديث السجل عند فتح الشاشة بدون حجب الـ UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationController>().refreshHistory();
    });
  }

  List<NotificationHistoryItem> _filteredHistory(
      List<NotificationHistoryItem> history) {
    if (_selectedFilter == null) return history;
    return history
        .where((item) => item.category == _selectedFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل الإشعارات'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          Consumer<NotificationController>(
            builder: (context, controller, _) {
              if (controller.history.isEmpty) return const SizedBox();
              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) async {
                  if (value == 'read_all') {
                    await controller.markAllAsRead();
                  } else if (value == 'clear') {
                    await _confirmClear(controller);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'read_all',
                    child: Row(
                      children: [
                        Icon(Icons.done_all_rounded, size: 20),
                        SizedBox(width: 10),
                        Text('تحديد الكل كمقروء'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'clear',
                    child: Row(
                      children: [
                        Icon(Icons.delete_sweep_rounded,
                            size: 20, color: Colors.red),
                        SizedBox(width: 10),
                        Text('مسح السجل',
                            style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationController>(
        builder: (context, controller, _) {
          if (controller.isLoading && controller.history.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final filtered = _filteredHistory(controller.history);

          return Column(
            children: [
              // مؤشر تحميل خفيف غير حاجب عند التحديث مع بيانات موجودة
              if (controller.isLoading)
                const LinearProgressIndicator(minHeight: 2),

              // Filter Chips
              _buildFilterBar(),
              const Divider(height: 1),

              // القائمة
              Expanded(
                child: filtered.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, indent: 72),
                        itemBuilder: (context, index) {
                          return _buildHistoryItem(
                            controller, filtered[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Filter Bar ────────────────────────────────────────────────────────────

  Widget _buildFilterBar() {
    final filters = <NotificationCategory?>[
      null, // الكل
      ...NotificationCategory.values,
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          final label = filter == null ? 'الكل' : filter.label;
          final icon = filter == null ? '🔔' : filter.icon;

          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: FilterChip(
              label: Text('$icon $label'),
              selected: isSelected,
              onSelected: (_) {
                setState(() => _selectedFilter = filter);
              },
              selectedColor:
                  Theme.of(context).colorScheme.primaryContainer,
              checkmarkColor: Theme.of(context).colorScheme.primary,
              labelStyle: TextStyle(
                fontSize: 13,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── History Item ──────────────────────────────────────────────────────────

  Widget _buildHistoryItem(
    NotificationController controller,
    NotificationHistoryItem item,
  ) {
    final isUnread = !item.wasRead;

    return InkWell(
      onTap: () async {
        if (isUnread) {
          await controller.markAsRead(item.id);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // أيقونة النوع
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _categoryColor(item.category)
                    .withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  item.category.icon,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // المحتوى
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isUnread
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsetsDirectional.only(start: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.body,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _categoryColor(item.category)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.category.label,
                          style: TextStyle(
                            fontSize: 11,
                            color: _categoryColor(item.category),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.relativeTime,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty State ───────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🔔', style: TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _selectedFilter == null
                  ? 'لا توجد إشعارات بعد'
                  : 'لا توجد إشعارات في هذا القسم',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedFilter == null
                  ? 'ستظهر هنا إشعاراتك حين تصلك'
                  : 'جرب تصفية مختلفة',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Confirm Clear Dialog ──────────────────────────────────────────────────

  Future<void> _confirmClear(NotificationController controller) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('مسح السجل'),
        content: const Text('هل أنت متأكد من حذف كل سجل الإشعارات؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await controller.clearHistory();
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Color _categoryColor(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.tasks:
        return Colors.blue;
      case NotificationCategory.motivational:
        return Colors.orange;
      case NotificationCategory.achievements:
        return Colors.amber.shade700;
      case NotificationCategory.summaries:
        return Colors.teal;
    }
  }
}