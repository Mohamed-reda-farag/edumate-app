import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/notification_controller.dart';
import '../../models/notification_settings_model.dart';

// ══════════════════════════════════════════════════════════════════════════════
// NotificationSettingsScreen
// ══════════════════════════════════════════════════════════════════════════════

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  // Local copy للتعديل قبل الحفظ
  late NotificationSettings _local;
  bool _hasChanges = false;
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    _local = context.read<NotificationController>().settings;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasChanges) {
      final incoming = context.read<NotificationController>().settings;
      if (incoming != _local || _isFirstLoad) {
        _local = incoming;
        _isFirstLoad = false;
      }
    }
  }

  void _update(NotificationSettings Function(NotificationSettings) updater) {
    setState(() {
      _local = updater(_local);
      _hasChanges = true;
    });
  }

  Future<void> _save() async {
    final controller = context.read<NotificationController>();
    await controller.updateSettings(_local);

    if (!mounted) return;

    final error = controller.error;
    if (error != null) {
      // [FIX #9] عند فشل الحفظ: نعكس الـ rollback في _local ليتطابق مع
      // الحالة الحقيقية في الـ controller (التي رجعت للقيمة القديمة).
      // بدون هذا، يظهر للمستخدم إعدادات وهمية لم تُحفظ فعلاً.
      // نُبقي _hasChanges = true لإتاحة المحاولة مجدداً.
      setState(() {
        _local = controller.settings;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('فشل الحفظ، تحقق من الاتصال وأعد المحاولة'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      setState(() => _hasChanges = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ إعدادات الإشعارات'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NotificationController>();

    final isSaving = controller.isSaving;

    // [FIX #15] PopScope: تحذير عند الخروج بتغييرات غير محفوظة
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldDiscard = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('تغييرات غير محفوظة'),
            content: const Text(
                'لديك تغييرات لم تُحفظ بعد. هل تريد تجاهلها والخروج؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('البقاء'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('تجاهل والخروج'),
              ),
            ],
          ),
        );
        if (shouldDiscard == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إعدادات الإشعارات'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          actions: [
            if (_hasChanges)
              isSaving
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  : TextButton(
                      onPressed: _save,
                      child: const Text(
                        'حفظ',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 1. تفعيل عام
              _buildMasterToggle(controller),
              const SizedBox(height: 16),

              // المحتوى الباقي يُعطَّل إذا كانت الإشعارات مُوقفة
              AnimatedOpacity(
                opacity: _local.isEnabled ? 1.0 : 0.4,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: !_local.isEnabled,
                  child: Column(
                    children: [
                      // 2. أنواع الإشعارات
                      _buildSection(
                        title: 'أنواع الإشعارات',
                        icon: Icons.notifications_rounded,
                        children: [
                          _buildSwitch(
                            label: 'تذكير بالمهام',
                            subtitle: 'محاضرات، مذاكرة، كورسات',
                            icon: Icons.task_alt_rounded,
                            value: _local.taskReminders,
                            onChanged: (v) =>
                                _update((s) => s.copyWith(taskReminders: v)),
                          ),
                          _buildSwitch(
                            label: 'تحفيزية',
                            subtitle: 'Streak، تقدم المهارة، هدف اليوم',
                            icon: Icons.local_fire_department_rounded,
                            value: _local.motivational,
                            onChanged: (v) =>
                                _update((s) => s.copyWith(motivational: v)),
                          ),
                          _buildSwitch(
                            label: 'الإنجازات',
                            subtitle: 'عند فتح إنجاز جديد',
                            icon: Icons.emoji_events_rounded,
                            value: _local.achievements,
                            onChanged: (v) =>
                                _update((s) => s.copyWith(achievements: v)),
                          ),
                          _buildSwitch(
                            label: 'الملخصات',
                            subtitle: 'ملخص يومي وأسبوعي',
                            icon: Icons.summarize_rounded,
                            value: _local.summaries,
                            onChanged: (v) =>
                                _update((s) => s.copyWith(summaries: v)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 3. التوقيت المفضل
                      _buildSection(
                        title: 'التوقيت المفضل',
                        icon: Icons.access_time_rounded,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: Text(
                              'متى تفضل تلقي الإشعارات التحفيزية؟',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          _buildTimeChips(),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 4. أيام التعلم المفضلة
                      _buildSection(
                        title: 'أيام التعلم المفضلة',
                        icon: Icons.calendar_month_rounded,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: Text(
                              'الأيام التي تريد تذكيراً بالتعلم فيها',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          _buildDayPicker(),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 5. إعدادات المهام
                      _buildSection(
                        title: 'إعدادات المهام',
                        icon: Icons.tune_rounded,
                        children: [
                          _buildLectureReminderSlider(),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 6. إعدادات الملخصات
                      _buildSection(
                        title: 'إعدادات الملخصات',
                        icon: Icons.schedule_rounded,
                        children: [
                          _buildTimePicker(
                            label: 'الملخص الصباحي',
                            time: _local.morningDigestTime,
                            onTap: () => _pickTime(
                              current: _local.morningDigestTime,
                              onPicked: (t) => _update(
                                  (s) => s.copyWith(morningDigestTime: t)),
                            ),
                          ),
                          const Divider(height: 1),
                          _buildTimePicker(
                            label: 'الملخص المسائي',
                            time: _local.eveningDigestTime,
                            onTap: () => _pickTime(
                              current: _local.eveningDigestTime,
                              onPicked: (t) => _update(
                                  (s) => s.copyWith(eveningDigestTime: t)),
                            ),
                          ),
                          const Divider(height: 1),
                          _buildWeeklyDigestPicker(),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 7. الصوت والاهتزاز
                      _buildSection(
                        title: 'الصوت والاهتزاز',
                        icon: Icons.volume_up_rounded,
                        children: [
                          _buildSwitch(
                            label: 'الصوت',
                            icon: Icons.music_note_rounded,
                            value: _local.sound,
                            onChanged: (v) =>
                                _update((s) => s.copyWith(sound: v)),
                          ),
                          _buildSwitch(
                            label: 'الاهتزاز',
                            icon: Icons.vibration_rounded,
                            value: _local.vibrate,
                            onChanged: (v) =>
                                _update((s) => s.copyWith(vibrate: v)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  Widgets
  // ══════════════════════════════════════════════════════════════════════════

  /// [FIX #3] _buildMasterToggle يستقبل الـ controller مباشرةً لاستدعاء
  /// toggleEnabled() فوراً بدلاً من تعديل _local فقط.
  ///
  /// المشكلة القديمة: عند إيقاف الإشعارات، كان يتغير _local.isEnabled فقط
  /// في الذاكرة ولا تُلغى الإشعارات المجدولة إلا عند الضغط على "حفظ".
  /// إذا خرج المستخدم بدون حفظ، تظل الإشعارات نشطة رغم الإيقاف الظاهري.
  ///
  /// الحل: toggleEnabled() يستدعي cancelAll() فوراً قبل الحفظ، ثم نعكس
  /// النتيجة في _local من controller.settings لضمان التزامن.
  Widget _buildMasterToggle(NotificationController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: _local.isEnabled
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _local.isEnabled
              ? Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.4)
              : Theme.of(context)
                  .colorScheme
                  .outline
                  .withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _local.isEnabled
                ? Icons.notifications_active_rounded
                : Icons.notifications_off_rounded,
            color: _local.isEnabled
                ? Theme.of(context).colorScheme.primary
                : Colors.grey,
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'الإشعارات',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _local.isEnabled ? 'مُفعَّلة' : 'مُوقفة',
                  style: TextStyle(
                    fontSize: 13,
                    color: _local.isEnabled
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _local.isEnabled,
            // [FIX #3] استدعاء toggleEnabled() فوراً بدلاً من _update فقط
            onChanged: (v) async {
              // تحديث الـ UI فوراً (optimistic) قبل انتظار toggleEnabled
              setState(() {
                _local = _local.copyWith(isEnabled: v);
              });

              // toggleEnabled يستدعي cancelAll() إذا v==false، ثم يحفظ في Firestore
              await controller.toggleEnabled(v);

              if (!mounted) return;

              // عكس النتيجة الحقيقية من الـ controller بعد الحفظ
              // (قد يختلف عن v إذا فشل الحفظ والـ controller عمل rollback)
              setState(() {
                _local = controller.settings;
                // لا نضع _hasChanges = true لأن toggleEnabled حفظ في Firestore مباشرةً
                _hasChanges = false;
              });
            },
            activeColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .outline
              .withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon,
                    color: Theme.of(context).colorScheme.primary, size: 20),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitch({
    required String label,
    String? subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
              icon,
              color: value
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
              size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w500),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style:
                        const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeChips() {
    // [FIX #14] استخدام named records بدلاً من anonymous tuples
    // لتحسين قراءة الكود ووضوح الوصول لكل حقل
    final times = [
      (
        option: _TimeOption('morning', '☀️ صباحاً', '9:00 ص'),
        isSelected: _local.preferMorning,
        onTap: (bool v) => _update((s) => s.copyWith(preferMorning: v)),
      ),
      (
        option: _TimeOption('afternoon', '🌤️ ظهراً', '1:00 م'),
        isSelected: _local.preferAfternoon,
        onTap: (bool v) => _update((s) => s.copyWith(preferAfternoon: v)),
      ),
      (
        option: _TimeOption('evening', '🌙 مساءً', '7:00 م'),
        isSelected: _local.preferEvening,
        onTap: (bool v) => _update((s) => s.copyWith(preferEvening: v)),
      ),
      (
        option: _TimeOption('night', '🌃 ليلاً', '10:00 م'),
        isSelected: _local.preferNight,
        onTap: (bool v) => _update((s) => s.copyWith(preferNight: v)),
      ),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: times.map((entry) {
        return FilterChip(
          label: Column(
            children: [
              Text(entry.option.label,
                  style: const TextStyle(fontSize: 14)),
              Text(entry.option.timeStr,
                  style:
                      const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          selected: entry.isSelected,
          onSelected: (v) {
            if (!v) {
              final selectedCount = [
                _local.preferMorning,
                _local.preferAfternoon,
                _local.preferEvening,
                _local.preferNight,
              ].where((b) => b).length;

              if (selectedCount <= 1) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('يجب اختيار وقت مفضل واحد على الأقل'),
                    duration: Duration(seconds: 2),
                  ),
                );
                return;
              }
            }
            entry.onTap(v);
          },
          selectedColor:
              Theme.of(context).colorScheme.primaryContainer,
          checkmarkColor: Theme.of(context).colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        );
      }).toList(),
    );
  }

  Widget _buildDayPicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (i) {
        final isSelected = _local.preferredDays.contains(i);
        // [FIX #14] InkWell بدل GestureDetector للحصول على ripple effect
        // يتوافق مع Material 3 design language
        return InkWell(
          onTap: () {
            if (isSelected && _local.preferredDays.length <= 1) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('يجب اختيار يوم واحد على الأقل للتعلم'),
                  duration: Duration(seconds: 2),
                ),
              );
              return;
            }
            _update((s) {
              final days = List<int>.from(s.preferredDays);
              if (isSelected) {
                days.remove(i);
              } else {
                days.add(i);
                days.sort();
              }
              return s.copyWith(preferredDays: days);
            });
          },
          borderRadius: BorderRadius.circular(19),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.3),
              ),
            ),
            child: Center(
              child: Text(
                // [FIX #14] استخدام dayShortName() من الـ model مباشرةً
                NotificationSettings.dayShortName(i),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildLectureReminderSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'التذكير قبل المحاضرة',
              style:
                  TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_local.lectureReminderMinutes} دقيقة',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        // النطاق 15-60 يتوافق مع clamp في NotificationSettings.fromJson
        Slider(
          value: _local.lectureReminderMinutes.toDouble(),
          min: 15,
          max: 60,
          divisions: 9, // كل 5 دقائق: 15,20,25,30,35,40,45,50,55,60
          label: '${_local.lectureReminderMinutes} دقيقة',
          onChanged: (v) =>
              _update((s) => s.copyWith(lectureReminderMinutes: v.round())),
          activeColor: Theme.of(context).colorScheme.primary,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('15 د',
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
              Text('60 د',
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimePicker({
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      title: Text(label,
          style:
              const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      trailing: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          _formatTime(time),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyDigestPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 8, bottom: 8),
          child: Text(
            'الملخص الأسبوعي',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ),
        Row(
          children: [
            // اختيار اليوم
            // [FIX #14] استخدام NotificationSettings.dayName() بدلاً
            // من hardcoded dayNames list — مصدر واحد للحقيقة
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _local.weeklyDigestDay,
                decoration: InputDecoration(
                  labelText: 'اليوم',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  isDense: true,
                ),
                items: List.generate(7, (i) {
                  return DropdownMenuItem(
                    value: i,
                    child: Text(
                      NotificationSettings.dayName(i),
                      style: const TextStyle(fontSize: 13),
                    ),
                  );
                }),
                onChanged: (v) {
                  if (v != null) {
                    _update((s) => s.copyWith(weeklyDigestDay: v));
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            // اختيار الوقت
            GestureDetector(
              onTap: () => _pickTime(
                current: _local.weeklyDigestTime,
                onPicked: (t) =>
                    _update((s) => s.copyWith(weeklyDigestTime: t)),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  _formatTime(_local.weeklyDigestTime),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<void> _pickTime({
    required TimeOfDay current,
    required void Function(TimeOfDay) onPicked,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
    );
    if (picked != null) onPicked(picked);
  }

  String _formatTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ── Helper model ──────────────────────────────────────────────────────────────

class _TimeOption {
  final String id;
  final String label;
  final String timeStr;
  const _TimeOption(this.id, this.label, this.timeStr);
}