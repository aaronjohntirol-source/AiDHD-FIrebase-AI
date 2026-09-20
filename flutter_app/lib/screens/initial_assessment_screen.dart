import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

const _questions = [
  'How often do you have trouble keeping your attention on tasks that take a long time?',
  'How often do you make careless mistakes or overlook details in your work or daily activities?',
  'How often do you struggle to stay organized with tasks, belongings, or schedules?',
  'How often do you avoid or delay starting tasks that require a lot of thinking or mental effort?',
  'How often do you lose things you need (e.g., keys, phone, wallet, school items)?',
  'How often do you get easily distracted by things happening around you or unrelated thoughts?',
  'How often do you forget things — even important ones — like appointments or chores?',
  'How often do you feel restless, fidgety, or have trouble sitting still for long periods?',
  'How often do you feel like your thoughts are moving too fast or jumping from one thing to another?',
  'How often do you say or do things impulsively without fully thinking them through?',
];

const _options = ['Never', 'Rarely', 'Sometimes', 'Often', 'Very Often'];

Map<String, dynamic> _getResult(int score) {
  if (score <= 13) {
    return {
      'label': 'Low Likelihood',
      'color': 0xFF22C55E,
      'desc':
          'Your responses suggest fewer ADHD-related traits at this time. Everyone experiences some of these challenges occasionally — that\'s completely normal.'
    };
  }
  if (score <= 25) {
    return {
      'label': 'Moderate Likelihood',
      'color': 0xFFF59E0B,
      'desc':
          'Your responses suggest some ADHD-related traits that are worth being aware of. Many people with these patterns benefit from support strategies and routines.'
    };
  }
  return {
    'label': 'High Likelihood',
    'color': 0xFFEF4444,
    'desc':
        'Your responses suggest notable ADHD-related traits. This does not mean you have ADHD — only a qualified professional can determine that — but exploring further support may be helpful.'
  };
}

class InitialAssessmentScreen extends StatefulWidget {
  const InitialAssessmentScreen({super.key});

  @override
  State<InitialAssessmentScreen> createState() =>
      _InitialAssessmentScreenState();
}

class _InitialAssessmentScreenState extends State<InitialAssessmentScreen> {
  int _step = 0; // 0=intro, 1=questions, 2=result
  int _current = 0;
  final List<int> _answers = [];
  bool _saving = false;

  int get _score => _answers.fold(0, (a, b) => a + b);

  Future<void> _answer(int value, AppProvider app) async {
    if (_saving) return;
    _answers.add(value);
    if (_current + 1 < _questions.length) {
      setState(() => _current++);
    } else {
      final res = _getResult(_score);
      setState(() => _saving = true);
      try {
        await app.saveInitialAssessment(_score, res['label'] as String);
        if (mounted) setState(() => _step = 2);
      } catch (_) {
        _answers.removeLast();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('Unable to save your screening. Please try again.')),
          );
        }
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppProvider>();
    if (_step == 0) return _buildIntro(app);
    if (_step == 2) return _buildResult(app);
    return _buildQuestion(app);
  }

  Widget _buildIntro(AppProvider app) => Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              const SizedBox(height: 20),
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                    color: AppColors.mint, shape: BoxShape.circle),
                child: ClipOval(
                    child: Image.asset('assets/brain_logo.png',
                        fit: BoxFit.cover)),
              ),
              const SizedBox(height: 20),
              const Text('ADHD Likelihood Screening',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark),
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              const Text(
                  'Before you get started, let\'s learn a little about your experience. This short screening takes about 2 minutes and helps personalize your AIDHD journey.',
                  style: TextStyle(
                      fontSize: 14, color: AppColors.textMid, height: 1.6),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.3))),
                child: Column(children: [
                  for (final item in [
                    ('📋', '10 quick questions about your everyday experience'),
                    ('⏱️', 'Takes about 2 minutes to complete'),
                    (
                      '🔒',
                      'Your answers are private and stored securely with your account'
                    ),
                  ])
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(children: [
                        Text(item.$1, style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text(item.$2,
                                style: const TextStyle(
                                    fontSize: 14, color: AppColors.textMid))),
                      ]),
                    ),
                ]),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E6),
                    border: Border.all(color: const Color(0xFFF59E0B)),
                    borderRadius: BorderRadius.circular(12)),
                child: const Text(
                    'Important: This is not a diagnostic tool. Results indicate likelihood only and cannot replace a professional evaluation.',
                    style: TextStyle(
                        fontSize: 12, color: Color(0xFF92400E), height: 1.5)),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                  onPressed: () => setState(() => _step = 1),
                  child: const Text('Begin Screening',
                      style: TextStyle(fontSize: 17))),
            ]),
          ),
        ),
      );

  Widget _buildQuestion(AppProvider app) {
    final progress = _current / _questions.length;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Question ${_current + 1} of ${_questions.length}',
                  style:
                      const TextStyle(fontSize: 13, color: AppColors.textMid)),
              Text('${(progress * 100).round()}%',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary)),
            ]),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: const Color(0xFFE0E8E4),
                  color: AppColors.primary),
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.3))),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                          color: AppColors.mint, shape: BoxShape.circle),
                      child: ClipOval(
                          child: Image.asset('assets/brain_logo.png',
                              fit: BoxFit.cover)),
                    ),
                    const SizedBox(height: 16),
                    Text(_questions[_current],
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                            height: 1.4)),
                  ]),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                itemCount: _options.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => _answer(i, app),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.border.withValues(alpha: 0.4),
                          width: 2),
                    ),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_options[i],
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textDark)),
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.border, width: 2)),
                          ),
                        ]),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
                'Answer based on your general experience over the past 6 months.',
                style: TextStyle(fontSize: 11, color: AppColors.textMid),
                textAlign: TextAlign.center),
          ]),
        ),
      ),
    );
  }

  Widget _buildResult(AppProvider app) {
    final res = _getResult(_score);
    final color = Color(res['color'] as int);
    final total = _questions.length * 4;
    final pct = _score / total;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            const SizedBox(height: 20),
            const Text('SCREENING COMPLETE',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: AppColors.textMid)),
            const SizedBox(height: 24),
            SizedBox(
              width: 140,
              height: 140,
              child: Stack(alignment: Alignment.center, children: [
                SizedBox.expand(
                    child: CircularProgressIndicator(
                        value: pct,
                        strokeWidth: 10,
                        backgroundColor: const Color(0xFFE0E8E4),
                        color: color,
                        strokeCap: StrokeCap.round)),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('$_score',
                      style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark)),
                  Text('of $total',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMid)),
                ]),
              ]),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(res['label'] as String,
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold, color: color)),
            ),
            const SizedBox(height: 16),
            Text(res['desc'] as String,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textMid, height: 1.6),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E6),
                  border: Border.all(color: const Color(0xFFF59E0B)),
                  borderRadius: BorderRadius.circular(12)),
              child: const Text(
                  'Reminder: This screening is not a diagnosis. Only a licensed healthcare professional can diagnose ADHD. Use these results as a starting point for self-awareness, not as a medical conclusion.',
                  style: TextStyle(
                      fontSize: 12, color: Color(0xFF92400E), height: 1.5)),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
                onPressed: () => app.navigate(AppScreen.home),
                child:
                    const Text('Go to Home', style: TextStyle(fontSize: 17))),
          ]),
        ),
      ),
    );
  }
}
