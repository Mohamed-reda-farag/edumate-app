import 'dart:async';

import 'package:flutter/material.dart';

import '../models/gamification_model.dart';
import '../repositories/attendance_repository.dart';

class GamificationController extends ChangeNotifier {
  GamificationController({
    required AttendanceRepository attendanceRepo,
  }) : _attendanceRepo = attendanceRepo;

  final AttendanceRepository _attendanceRepo;

  // ── State ─────────────────────────────────────────────────────────────────

  GamificationData? _data;
  List<Achievement> _newlyUnlocked = [];
  bool _isLoading = false;
  String? _error;

  StreamSubscription<GamificationData?>? _gamificationSub;

  /// IDs الإنجازات التي كانت مفتوحة عند بداية الجلسة
  Set<String> _unlockedAtStart = {};
  bool _initialized = false;

  // ── Public Getters ────────────────────────────────────────────────────────

  GamificationData? get data          => _data;
  List<Achievement> get newlyUnlocked => List.unmodifiable(_newlyUnlocked);
  bool              get isLoading     => _isLoading;
  String?           get error         => _error;
  bool              get isInitialized => _initialized;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _data = await _attendanceRepo.getGamification();
      _unlockedAtStart = Set.from(_data?.unlockedAchievements ?? []);
    } catch (e) {
      _error = e.toString();
      _initialized = false;
      _isLoading = false;
      notifyListeners();
      return;
    } finally {
      if (_initialized) {
        _isLoading = false;
        notifyListeners();
      }
    }

    _startListening();
  }

  Future<void> reset() async {
    await _cancelSubscriptions();

    _initialized = false;
    _data = null;
    _newlyUnlocked = [];
    _unlockedAtStart = {};
    _isLoading = false;
    _error = null;

    notifyListeners();
  }

  // ── Methods ───────────────────────────────────────────────────────────────

  void clearNewlyUnlocked() {
    if (_newlyUnlocked.isEmpty) return;
    _unlockedAtStart.addAll(_newlyUnlocked.map((a) => a.id));
    _newlyUnlocked = [];
    notifyListeners();
  }

  void resetSemesterBaseline() {
    _unlockedAtStart = Set.from(_data?.unlockedAchievements ?? []);
    _newlyUnlocked = [];
    notifyListeners();
  }

  // ── Private ───────────────────────────────────────────────────────────────

  void _startListening() {
    _gamificationSub?.cancel();

    _gamificationSub = _attendanceRepo.watchGamification().listen(
      (incoming) {
        if (incoming == null) {
          _data = null;
          notifyListeners();
          return;
        }

        final freshIds = incoming.unlockedAchievements
            .where((id) => !_unlockedAtStart.contains(id))
            .toList();

        if (freshIds.isNotEmpty) {
          final freshAchievements = freshIds
              .map(Achievement.findById)
              .whereType<Achievement>()
              .toList();

          final existing = _newlyUnlocked.map((a) => a.id).toSet();
          final deduped = freshAchievements
              .where((a) => !existing.contains(a.id))
              .toList();

          _newlyUnlocked = [..._newlyUnlocked, ...deduped];
        }

        _data = incoming;
        notifyListeners();
      },
      onError: (Object e) {
        _error = e.toString();
        notifyListeners();
      },
    );
  }

  Future<void> _cancelSubscriptions() async {
    await _gamificationSub?.cancel();
    _gamificationSub = null;
  }

  @override
  void dispose() {
    _gamificationSub?.cancel();
    super.dispose();
  }
}