import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/history_entry.dart';
import '../models/accessibility_settings.dart';
import '../services/auth_service.dart';
import '../services/history_service.dart';
import '../services/accessibility_service.dart';

enum AppScreen {
  login,
  signup,
  initialAssessment,
  home,
  moodCheckin,
  assessment,
  assessmentResult,
  history,
  learn,
  chat,
  profile,
  settings,
  notificationSettings,
  privacyPolicy,
  helpSupport,
}

class AppProvider extends ChangeNotifier {
  final _auth = AuthService();
  final _historyService = HistoryService();
  final _accessibilityService = AccessibilityService();

  AppScreen _screen = AppScreen.login;
  User? _currentUser;
  List<HistoryEntry> _history = [];
  String? _error;
  bool _loading = false;

  // Assessment state
  int? _assessmentScore;
  String? _assessmentCategory;

  // Mood checkin state
  MoodLabel? _selectedMood;

  // Accessibility settings (loaded from storage in init())
  AccessibilitySettings _accessibility = const AccessibilitySettings();

  AppScreen get screen => _screen;
  User? get currentUser => _currentUser;
  List<HistoryEntry> get history => _history;
  String? get error => _error;
  bool get loading => _loading;
  int? get assessmentScore => _assessmentScore;
  String? get assessmentCategory => _assessmentCategory;
  MoodLabel? get selectedMood => _selectedMood;
  AccessibilitySettings get accessibility => _accessibility;

  // Called once from main() before runApp to load persisted settings.
  Future<void> init() async {
    _accessibility = await _accessibilityService.get();
    await _accessibilityService.clearLegacyAccountData();
    // Restore session if user was previously logged in.
    try {
      final sessionUser = await _auth.getSessionUser();
      if (sessionUser != null) {
        _currentUser = sessionUser;
        _history = await _historyService.getHistory(sessionUser.id);
        _screen = sessionUser.initialAssessmentScore == null
            ? AppScreen.initialAssessment
            : AppScreen.home;
      }
    } on FirebaseException {
      // Firebase is the only account/data source; stay signed out if unavailable.
    }
    // No notifyListeners needed — provider isn't attached to a widget tree yet.
  }

  Future<void> updateAccessibility(AccessibilitySettings settings) async {
    _accessibility = settings;
    await _accessibilityService.save(settings);
    notifyListeners();
  }

  void setAssessmentResult(int score, String category) {
    _assessmentScore = score;
    _assessmentCategory = category;
    notifyListeners();
  }

  void setSelectedMood(MoodLabel mood) {
    _selectedMood = mood;
    notifyListeners();
  }

  void navigate(AppScreen screen) {
    _screen = screen;
    _error = null;
    notifyListeners();
  }

  // ── Auth ──

  Future<void> login(String identifier, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    final result = await _auth.login(identifier, password);
    _loading = false;
    if (result.ok) {
      _currentUser = result.user!;
      _history = await _historyService.getHistory(_currentUser!.id);
      _screen = _currentUser!.initialAssessmentScore == null
          ? AppScreen.initialAssessment
          : AppScreen.home;
    } else {
      _error = result.error;
    }
    notifyListeners();
  }

  Future<void> register(
      String name, String email, String username, String password,
      {String age = ''}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    final result = await _auth.register(
        name: name,
        email: email,
        username: username,
        password: password,
        age: age);
    _loading = false;
    if (result.ok) {
      _currentUser = result.user!;
      _history = [];
      _screen = AppScreen.initialAssessment;
    } else {
      _error = result.error;
    }
    notifyListeners();
  }

  Future<void> logout() async {
    await _auth.logout();
    _currentUser = null;
    _history = [];
    _assessmentScore = null;
    _assessmentCategory = null;
    _selectedMood = null;
    _screen = AppScreen.login;
    notifyListeners();
  }

  Future<void> updateProfile(
      {String? name, String? age, String? gender}) async {
    if (_currentUser == null) return;
    final updated = await _auth.updateUser(_currentUser!.id,
        name: name, age: age, gender: gender);
    if (updated != null) {
      _currentUser = updated;
      notifyListeners();
    }
  }

  // Saves initial assessment data without navigating — lets the result screen show first.
  Future<void> saveInitialAssessment(int score, String category) async {
    if (_currentUser == null) return;
    final updated = await _auth.updateUser(
      _currentUser!.id,
      initialAssessmentScore: score,
      initialAssessmentCategory: category,
    );
    if (updated != null) _currentUser = updated;
    notifyListeners();
  }

  // ── History ──

  Future<void> addHistoryEntry(HistoryEntry entry) async {
    _history = [entry, ..._history];
    if (_currentUser != null) {
      await _historyService.addEntry(_currentUser!.id, entry);
    }
    notifyListeners();
  }

  // ── Age helpers ──

  String get ageGroup {
    final a = int.tryParse(_currentUser?.age ?? '');
    if (a == null) return 'adult';
    if (a < 13) return 'under_13';
    if (a < 18) return 'adolescent';
    return 'adult';
  }

  bool get isMinor => ageGroup == 'under_13';

  // ── AI Context ──
  // When a real AI API is integrated, call buildAiContext() to get the payload
  // for the system prompt. This is the single source of truth for user context.
  //
  // AGE-AWARE SYSTEM PROMPT GUIDANCE:
  //   'under_13':   Use simple, kind language. Never give medication advice.
  //                 For any health question: "Talk to a trusted adult like a parent or doctor."
  //   'adolescent': Supportive, non-patronising tone. Encourage professional guidance.
  //   'adult':      Evidence-based strategies. Recommend healthcare professional for clinical decisions.
  Map<String, dynamic> buildAiContext() => {
        'userId': _currentUser?.id,
        'name': _currentUser?.name,
        'age': _currentUser?.age,
        'ageGroup': ageGroup,
        'isMinor': isMinor,
        'gender': _currentUser?.gender,
        'initialAssessmentScore': _currentUser?.initialAssessmentScore,
        'initialAssessmentCategory': _currentUser?.initialAssessmentCategory,
        'latestAssessmentScore': _assessmentScore,
        'latestAssessmentCategory': _assessmentCategory,
        'history': _history.map((e) => e.toJson()).toList(),
      };
}
