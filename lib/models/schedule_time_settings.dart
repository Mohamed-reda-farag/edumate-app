import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ScheduleTimeSlot {
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;

  const ScheduleTimeSlot({
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
  });
  String get label =>
      '${_fmt(startHour, startMinute)}-${_fmt(endHour, endMinute)}';

  int get durationMinutes =>
      (endHour * 60 + endMinute) - (startHour * 60 + startMinute);

  static String _fmt(int h, int m) =>
      '$h:${m.toString().padLeft(2, '0')}';

  ScheduleTimeSlot copyWith({
    int? startHour, int? startMinute, int? endHour, int? endMinute,
  }) =>
      ScheduleTimeSlot(
        startHour:   startHour   ?? this.startHour,
        startMinute: startMinute ?? this.startMinute,
        endHour:     endHour     ?? this.endHour,
        endMinute:   endMinute   ?? this.endMinute,
      );

  Map<String, dynamic> toJson() =>
      {'sh': startHour, 'sm': startMinute, 'eh': endHour, 'em': endMinute};

  factory ScheduleTimeSlot.fromJson(Map<String, dynamic> j) =>
      ScheduleTimeSlot(
        startHour:   (j['sh'] as num).toInt(),
        startMinute: (j['sm'] as num).toInt(),
        endHour:     (j['eh'] as num).toInt(),
        endMinute:   (j['em'] as num).toInt(),
      );

  @override
  bool operator ==(Object other) =>
      other is ScheduleTimeSlot &&
      startHour == other.startHour && startMinute == other.startMinute &&
      endHour   == other.endHour   && endMinute   == other.endMinute;

  @override
  int get hashCode => Object.hash(startHour, startMinute, endHour, endMinute);

  @override
  String toString() => 'ScheduleTimeSlot($label, ${durationMinutes}min)';
}

const List<ScheduleTimeSlot> kDefaultTimeSlots = [
  ScheduleTimeSlot(startHour: 8,  startMinute: 0,  endHour: 10, endMinute: 0),
  ScheduleTimeSlot(startHour: 10, startMinute: 0,  endHour: 12, endMinute: 0),
  ScheduleTimeSlot(startHour: 12, startMinute: 0,  endHour: 14, endMinute: 0),
  ScheduleTimeSlot(startHour: 14, startMinute: 0,  endHour: 16, endMinute: 0),
  ScheduleTimeSlot(startHour: 16, startMinute: 0,  endHour: 18, endMinute: 0),
  ScheduleTimeSlot(startHour: 18, startMinute: 0,  endHour: 20, endMinute: 0),
];

class ScheduleTimeSettings {
  ScheduleTimeSettings._();
  static final ScheduleTimeSettings instance = ScheduleTimeSettings._();
  static const _kKey = 'sch_time_slots_v1_';

  Future<List<ScheduleTimeSlot>> load(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString('$_kKey$userId');
    if (raw == null) return List.from(kDefaultTimeSlots);
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => ScheduleTimeSlot.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return List.from(kDefaultTimeSlots);
    }
  }

  Future<void> save(String userId, List<ScheduleTimeSlot> slots) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        '$_kKey$userId', jsonEncode(slots.map((s) => s.toJson()).toList()));
  }

  Future<void> reset(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_kKey$userId');
  }
}