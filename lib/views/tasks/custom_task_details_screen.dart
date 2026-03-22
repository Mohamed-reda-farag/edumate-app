import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/task_controller.dart';
import '../../models/task_model.dart';

// ══════════════════════════════════════════════════════════════════════════════
// TaskDetailsScreen — مخصصة للمهام المخصصة (custom) فقط
// ══════════════════════════════════════════════════════════════════════════════

class TaskDetailsScreen extends StatelessWidget {
  const TaskDetailsScreen({super.key, required this.task});
  final TaskModel task;

  @override
  Widget build(BuildContext context) {
    // نستمع لـ customTasks مباشرةً من الـ Provider لضمان مزامنة الـ UI مع Stream.
    // إذا حُذفت المهمة (من جهاز آخر أو من نفس الجلسة)، نعود للخلف تلقائياً.
    return Consumer<TaskController>(
      builder: (context, controller, _) {
        final liveTask = controller.customTasks.cast<TaskModel?>().firstWhere(
              (t) => t?.id == task.id,
              orElse: () => null,
            );

        if (liveTask == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) Navigator.of(context).pop();
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final isCompleted = liveTask.status == TaskStatus.completed;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'تفاصيل المهمة',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _openEditSheet(context, liveTask),
                tooltip: 'تعديل',
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ── Header Card ────────────────────────────────────────────────
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.teal.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.push_pin,
                                color: Colors.teal, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  liveTask.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'مهمة مخصصة',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _StatusRow(status: liveTask.status),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── معلومات تفصيلية ────────────────────────────────────────────
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (liveTask.scheduledDate != null)
                        _InfoTile(
                          icon: Icons.calendar_today,
                          label: 'التاريخ',
                          value: _formatDate(liveTask.scheduledDate!),
                        ),
                      if (liveTask.timeSlot != null)
                        _InfoTile(
                          icon: Icons.access_time,
                          label: 'الوقت',
                          value: liveTask.formattedTimeSlot,
                        ),
                      if (liveTask.durationMinutes != null)
                        _InfoTile(
                          icon: Icons.timer_outlined,
                          label: 'المدة',
                          value: _formatDuration(liveTask.durationMinutes!),
                        ),
                      if (liveTask.dueDate != null)
                        _InfoTile(
                          icon: Icons.event,
                          label: 'الموعد النهائي',
                          value: _formatDate(liveTask.dueDate!),
                        ),
                      if (liveTask.description != null &&
                          liveTask.description!.isNotEmpty)
                        _InfoTile(
                          icon: Icons.notes,
                          label: 'الوصف',
                          value: liveTask.description!,
                        ),
                      if (liveTask.isRecurring)
                        const _InfoTile(
                          icon: Icons.repeat,
                          label: 'التكرار',
                          value: 'مهمة متكررة',
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── أزرار الإجراءات ────────────────────────────────────────────
              if (!isCompleted)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _toggleComplete(context, true, liveTask),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('إكمال المهمة'),
                    style: FilledButton.styleFrom(
                        backgroundColor: Colors.green),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _toggleComplete(context, false, liveTask),
                    icon: const Icon(Icons.undo),
                    label: const Text('إلغاء الإكمال'),
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmDelete(context, liveTask),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text('حذف المهمة',
                      style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Future<void> _toggleComplete(
      BuildContext context, bool complete, TaskModel current) async {
    final controller = context.read<TaskController>();
    if (complete) {
      await controller.completeCustomTask(current.id);
    } else {
      await controller.uncompleteCustomTask(current.id);
    }
    if (context.mounted) Navigator.pop(context);
  }

  void _confirmDelete(BuildContext context, TaskModel current) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف المهمة'),
        content: const Text('هل أنت متأكد من حذف هذه المهمة نهائياً؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await context.read<TaskController>().deleteCustomTask(current.id);
              if (context.mounted) {
                Navigator.pop(ctx);
                Navigator.pop(context);
              }
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _openEditSheet(BuildContext context, TaskModel current) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _EditTaskSheet(
        task: current,
        onSave: (updatedTask) async {
          await context.read<TaskController>().updateCustomTask(updatedTask);
          if (ctx.mounted) Navigator.pop(ctx);
        },
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';

  String _formatDuration(int minutes) {
    if (minutes < 60) return '$minutes دقيقة';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return '$h ساعة';
    return '$h ساعة $m دقيقة';
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Edit Task Bottom Sheet
// ══════════════════════════════════════════════════════════════════════════════

class _EditTaskSheet extends StatefulWidget {
  const _EditTaskSheet({required this.task, required this.onSave});
  final TaskModel task;
  final Future<void> Function(TaskModel) onSave;

  @override
  State<_EditTaskSheet> createState() => _EditTaskSheetState();
}

class _EditTaskSheetState extends State<_EditTaskSheet> {
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.task.title);
    _descCtrl = TextEditingController(text: widget.task.description ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20, 20, 20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'تعديل المهمة',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleCtrl,
            decoration: InputDecoration(
              labelText: 'العنوان',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              filled: true,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            decoration: InputDecoration(
              labelText: 'الوصف (اختياري)',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              filled: true,
            ),
            maxLines: 2,
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('حفظ التعديلات'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _isSaving = true);

    final updated = widget.task.copyWith(
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty
          ? null
          : _descCtrl.text.trim(),
      updatedAt: DateTime.now(),
    );

    await widget.onSave(updated);
    if (mounted) setState(() => _isSaving = false);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Shared Sub-widgets
// ══════════════════════════════════════════════════════════════════════════════

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.status});
  final TaskStatus status;

  @override
  Widget build(BuildContext context) {
    late String label;
    late Color color;
    late IconData icon;

    switch (status) {
      case TaskStatus.upcoming:
        label = 'قادمة';       color = Colors.blue;   icon = Icons.upcoming;     break;
      case TaskStatus.ongoing:
        label = 'جارية الآن'; color = Colors.orange; icon = Icons.play_circle;  break;
      case TaskStatus.completed:
        label = 'مكتملة';     color = Colors.green;  icon = Icons.check_circle; break;
      case TaskStatus.missed:
        label = 'فائتة';      color = Colors.red;    icon = Icons.cancel;       break;
    }

    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}