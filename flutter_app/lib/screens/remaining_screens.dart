import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/history_entry.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav.dart';

String _nowTime() {
  final t = DateTime.now();
  final h = t.hour > 12 ? t.hour - 12 : (t.hour == 0 ? 12 : t.hour);
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m ${t.hour >= 12 ? "PM" : "AM"}';
}

// ── History ──────────────────────────────────────────────────────────────────

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final entries = app.history.where((e) {
      if (_filter == 'Mood') return e.type == EntryType.mood;
      if (_filter == 'Assessments') return e.type == EntryType.assessment;
      return true;
    }).toList();

    final today = entries.where((e) => e.isToday).toList();
    final yesterday = entries.where((e) => !e.isToday).toList();

    return Scaffold(
      body: SafeArea(
          child: Column(children: [
        Container(
          color: AppColors.mint,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(children: [
            IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 18),
                onPressed: () => app.navigate(AppScreen.home)),
            const Expanded(
                child: Center(
                    child: Text('History',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w600)))),
            const SizedBox(width: 48),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
              children: ['All', 'Mood', 'Assessments']
                  .map((f) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _filter = f),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: _filter == f
                                  ? AppColors.primary
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: _filter == f
                                      ? AppColors.primary
                                      : AppColors.border
                                          .withValues(alpha: 0.4)),
                            ),
                            child: Text(f,
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: _filter == f
                                        ? Colors.white
                                        : AppColors.textMid)),
                          ),
                        ),
                      ))
                  .toList()),
        ),
        Expanded(
          child: entries.isEmpty
              ? const Center(
                  child: Text('No entries yet.',
                      style: TextStyle(color: AppColors.textMid)))
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                      if (today.isNotEmpty) ...[
                        const Text('Today',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark)),
                        const SizedBox(height: 8),
                        ...today.map((e) => _EntryCard(entry: e)),
                      ],
                      if (yesterday.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text('Yesterday',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark)),
                        const SizedBox(height: 8),
                        ...yesterday.map((e) => _EntryCard(entry: e)),
                      ],
                    ]),
        ),
        AidhdBottomNav(active: AppScreen.history, onTap: app.navigate),
      ])),
    );
  }
}

class _EntryCard extends StatefulWidget {
  final HistoryEntry entry;
  const _EntryCard({required this.entry});
  @override
  State<_EntryCard> createState() => _EntryCardState();
}

class _EntryCardState extends State<_EntryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final hasNote = entry.note != null && entry.note!.isNotEmpty;

    return GestureDetector(
      onTap: hasNote ? () => setState(() => _expanded = !_expanded) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.3))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: entry.type == EntryType.mood
                    ? const Color(0xFFCEEACB)
                    : const Color(0xFFE8DCFF),
                shape: BoxShape.circle,
              ),
              child: Center(
                  child: Text(
                      entry.type == EntryType.mood
                          ? (entry.mood?.emoji ?? '😊')
                          : '📋',
                      style: const TextStyle(fontSize: 20))),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(entry.label,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textDark)),
                  Text(entry.timestamp,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textLight)),
                  if (entry.type == EntryType.assessment && entry.score != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                            color: AppColors.mint.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(10)),
                        child: Text('Score: ${entry.score}',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary)),
                      ),
                    ),
                ])),
            if (hasNote)
              Icon(
                _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                size: 18,
                color: AppColors.textMid,
              ),
          ]),
          if (hasNote) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: const Color(0xFFF2F4F2),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(
                entry.note!,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textMid, height: 1.55),
                maxLines: _expanded ? null : 2,
                overflow:
                    _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

// ── Mood Check-in ─────────────────────────────────────────────────────────────

class MoodCheckinScreen extends StatefulWidget {
  const MoodCheckinScreen({super.key});
  @override
  State<MoodCheckinScreen> createState() => _MoodCheckinScreenState();
}

class _MoodCheckinScreenState extends State<MoodCheckinScreen> {
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final mood = app.selectedMood;
    if (mood == null) {
      app.navigate(AppScreen.home);
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.mint,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 18),
            onPressed: () => app.navigate(AppScreen.home)),
        title: const Text('Mood Check-in'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: AppColors.border.withValues(alpha: 0.3))),
            child: Column(children: [
              Text(mood.emoji, style: const TextStyle(fontSize: 64)),
              const SizedBox(height: 8),
              Text('You feel ${mood.displayName}',
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark)),
              Text(DateTime.now().toString().substring(0, 16),
                  style:
                      const TextStyle(fontSize: 13, color: AppColors.textMid)),
            ]),
          ),
          const SizedBox(height: 20),
          const Align(
              alignment: Alignment.centerLeft,
              child: Text('Add a note (optional)',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark))),
          const SizedBox(height: 8),
          TextField(
            controller: _noteCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "What's on your mind?",
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                      color: AppColors.border.withValues(alpha: 0.4))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                      color: AppColors.border.withValues(alpha: 0.4))),
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: () {
              final entry = HistoryEntry(
                id: 'mood_${DateTime.now().millisecondsSinceEpoch}',
                type: EntryType.mood,
                label: 'You felt ${mood.displayName}',
                timestamp: _nowTime(),
                isToday: true,
                mood: mood,
                note: _noteCtrl.text.trim().isEmpty
                    ? null
                    : _noteCtrl.text.trim(),
                activities: [],
              );
              app.addHistoryEntry(entry);
              app.navigate(AppScreen.home);
            },
            child: const Text('Save Check-in'),
          ),
        ]),
      ),
    );
  }
}

// ── Assessment ────────────────────────────────────────────────────────────────

const _assessmentQuestions = [
  'How often do you have difficulty sustaining attention in tasks or activities?',
  'How often do you find yourself easily distracted by external stimuli?',
  'How often do you forget to complete daily tasks or responsibilities?',
  'How often do you have trouble organizing tasks and activities?',
  'How often do you avoid or feel reluctant to engage in tasks requiring sustained effort?',
  'How often do you fidget or feel restless when required to stay still?',
  'How often do you interrupt or intrude on others in conversations?',
  'How often do you have difficulty waiting your turn?',
  'How often do you rush through tasks without careful attention to detail?',
  'How often do you lose things necessary for tasks or activities?',
];

const _assessmentOptions = [
  'Never',
  'Rarely',
  'Sometimes',
  'Often',
  'Very Often'
];

String _getCategory(int score) {
  if (score <= 10) return 'Minimal';
  if (score <= 20) return 'Mild';
  if (score <= 30) return 'Moderate';
  return 'Severe';
}

class AssessmentScreen extends StatefulWidget {
  const AssessmentScreen({super.key});
  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  int _current = 0;
  final List<int> _answers = [];

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppProvider>();
    final progress = _current / _assessmentQuestions.length;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => app.navigate(AppScreen.home)),
              Text('Question ${_current + 1}/${_assessmentQuestions.length}',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMid)),
              Text('${(progress * 100).round()}%',
                  style: const TextStyle(
                      fontSize: 14,
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
                    color: AppColors.primary)),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.3))),
              child: Text(_assessmentQuestions[_current],
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                      height: 1.4)),
            ),
            const SizedBox(height: 20),
            Expanded(
                child: ListView.separated(
              itemCount: _assessmentOptions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => GestureDetector(
                onTap: () {
                  final newAnswers = [..._answers, i];
                  if (_current + 1 < _assessmentQuestions.length) {
                    setState(() {
                      _answers.add(i);
                      _current++;
                    });
                  } else {
                    final total = newAnswers.fold(0, (a, b) => a + b);
                    final cat = _getCategory(total);
                    app.setAssessmentResult(total, cat);
                    final entry = HistoryEntry(
                      id: 'assess_${DateTime.now().millisecondsSinceEpoch}',
                      type: EntryType.assessment,
                      label: 'Daily Assessment completed',
                      timestamp: _nowTime(),
                      isToday: true,
                      score: total,
                      category: cat,
                    );
                    app.addHistoryEntry(entry);
                    app.navigate(AppScreen.assessmentResult);
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.border.withValues(alpha: 0.4),
                          width: 2)),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_assessmentOptions[i],
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
                                    color: AppColors.border, width: 2))),
                      ]),
                ),
              ),
            )),
          ]),
        ),
      ),
    );
  }
}

// ── Assessment Result ─────────────────────────────────────────────────────────

class AssessmentResultScreen extends StatelessWidget {
  const AssessmentResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final score = app.assessmentScore ?? 0;
    final category = app.assessmentCategory ?? 'Unknown';
    final total = _assessmentQuestions.length * 4;
    final pct = score / total;
    final color = {
          'Minimal': const Color(0xFF22C55E),
          'Mild': const Color(0xFF3B82F6),
          'Moderate': const Color(0xFFF59E0B),
          'Severe': const Color(0xFFEF4444)
        }[category] ??
        AppColors.primary;

    return Scaffold(
      appBar: AppBar(
          backgroundColor: AppColors.mint,
          title: const Text('Assessment Result'),
          automaticallyImplyLeading: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          const SizedBox(height: 16),
          SizedBox(
              width: 160,
              height: 160,
              child: Stack(alignment: Alignment.center, children: [
                SizedBox.expand(
                    child: CircularProgressIndicator(
                        value: pct,
                        strokeWidth: 12,
                        backgroundColor: const Color(0xFFE0E8E4),
                        color: color,
                        strokeCap: StrokeCap.round)),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('$score',
                      style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark)),
                  Text('of $total',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMid)),
                ]),
              ])),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(20)),
            child: Text(category,
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          ),
          const SizedBox(height: 16),
          const Text(
              'This is a snapshot of your ADHD-related challenges today. It is not a clinical diagnosis — it is a self-awareness tool to help you track patterns over time.',
              style: TextStyle(
                  fontSize: 14, color: AppColors.textMid, height: 1.6),
              textAlign: TextAlign.center),
          const SizedBox(height: 32),
          ElevatedButton(
              onPressed: () => app.navigate(AppScreen.home),
              child: const Text('Back to Home')),
        ]),
      ),
    );
  }
}

// ── Learn ─────────────────────────────────────────────────────────────────────

const _articles = [
  (
    'What is ADHD?',
    'ADHD (Attention-Deficit/Hyperactivity Disorder) is a neurodevelopmental condition caused by differences in how the brain develops — particularly in areas that regulate attention, impulse control, and executive function. It is not a lack of intelligence, laziness, or willpower.\n\nADHD is diagnosed across three presentations:\n• Predominantly Inattentive — difficulty sustaining focus, frequently losing things, forgetfulness\n• Predominantly Hyperactive-Impulsive — excessive movement, talking, difficulty waiting\n• Combined — a mix of both\n\nADHD affects approximately 5–7% of children and 2.5–4% of adults worldwide, and is highly heritable. Many people with ADHD show remarkable creativity, hyperfocus, and out-of-the-box thinking.\n\nOnly a licensed professional — psychiatrist, psychologist, or GP — can diagnose ADHD.'
  ),
  (
    'Building Routines That Stick',
    'The ADHD brain struggles with "time blindness" — the inability to feel time passing reliably. This makes routines feel almost impossible to maintain without the right scaffolding. The key insight is that willpower alone never works: external structure must replace what neurotypical brains generate internally.\n\nEffective routine-building focuses on reducing daily decisions, using environmental design (keeping things visible), and anchoring new habits to existing ones:\n\n• Anchor habits to triggers — take medication right after brushing teeth\n• Use visual timers to make time feel real\n• Keep items you need visible, not hidden away\n• Prepare the night before — lay out clothes, pre-pack your bag\n• Use a "top 3" rule: identify just 3 tasks each morning that matter most\n• Body doubling (working alongside someone) dramatically boosts consistency\n• Reward yourself immediately after completing tasks'
  ),
  (
    'Emotional Regulation & ADHD',
    'Emotional dysregulation is one of the most impactful but least discussed symptoms of ADHD. Up to 70% of people with ADHD experience Rejection Sensitive Dysphoria (RSD) — an intense emotional response to perceived criticism or failure.\n\nThis is not a character flaw. It is a neurological difference in emotional regulation linked to the same executive function deficits that affect attention.\n\nStrategies that help:\n• Name the emotion before reacting: "I notice I feel angry"\n• Box breathing: inhale 4 counts, hold 4, exhale 4, hold 4\n• 5-4-3-2-1 grounding: name 5 things you see, 4 you can touch, 3 you hear, 2 you smell, 1 you taste\n• Remove yourself from the situation — even 90 seconds can calm the initial wave\n• If emotional dysregulation is severely impacting your life, talk to a therapist about DBT or CBT'
  ),
  (
    'Sleep & ADHD',
    'People with ADHD are significantly more likely to experience sleep problems — including delayed sleep phase syndrome, difficulty falling asleep, and restless sleep. Many ADHD brains become most active right when the body is supposed to wind down, causing that classic "second wind" late at night.\n\nSleep deprivation makes every ADHD symptom measurably worse. Treating sleep is as important as any other ADHD intervention.\n\nWhat helps:\n• Set a hard "screens off" time 60–90 minutes before bed — blue light suppresses melatonin\n• Keep your wake-up time consistent, even on weekends\n• A cool, dark room (around 18°C / 65°F) supports deeper sleep\n• Low-dose melatonin (0.5–1 mg, 2 hours before bed) may help — discuss with your doctor\n• Exercise during the day significantly improves sleep quality\n• Avoid caffeine after 2 pm — ADHD people often metabolise it more slowly'
  ),
  (
    'Focus Strategies That Work',
    'The biggest ADHD focus myth is that people with ADHD cannot focus at all. The real issue is inconsistent, dysregulated focus — unable to focus on demand, but then hyperfocusing for hours on something interesting. The goal is creating conditions where your brain naturally engages.\n\nScience-backed strategies:\n• Pomodoro technique: 25 minutes focused work, 5-minute break, repeat\n• Start rituals: same playlist, same drink, same seat — condition your brain to focus\n• Use noise: lo-fi music, brown noise, or binaural beats can mask distractions\n• Reduce activation energy: open the document before taking a break\n• Temptation bundling: only listen to your favourite podcast while doing a dreaded task\n• Break tasks into the smallest possible steps — "write report" becomes "open a new document"\n• Schedule your most intellectually engaging work during your peak energy hours'
  ),
  (
    'ADHD in Relationships',
    'ADHD affects how people connect, communicate, and maintain relationships. Common challenges include forgetting important dates, zoning out mid-conversation, being late, or saying things impulsively — often misread as not caring.\n\nUnderstanding the difference between inability and unwillingness is the foundation of healthier relationships.\n\nWhat helps:\n• Explain ADHD to people you trust — understanding replaces resentment\n• Use shared digital calendars so both people get reminders\n• Active listening: make eye contact, repeat back what you heard\n• Set alarms for birthdays, anniversaries, and regular check-ins\n• Apologise and repair quickly — recovery matters more than perfection\n• Couples therapy with an ADHD-informed therapist can transform relationship dynamics'
  ),
  (
    'ADHD at Work & School',
    'ADHD can create real challenges in environments built around sustained attention and rigid schedules. However, with the right adaptations, many people with ADHD become highly effective professionals, often excelling in fast-paced or creative roles.\n\nAccommodations are not cheating — they level the playing field.\n\nWhat works:\n• Ask for accommodations: extended time, quiet spaces, flexible deadlines are legitimate\n• Time-block your calendar: assign specific tasks to specific time slots\n• Batch similar tasks — context-switching has a high cost for ADHD brains\n• Communicate proactively with managers or teachers — early conversations prevent bigger problems\n• Standing desks, fidget tools, and walking meetings channel restlessness productively\n• Many successful entrepreneurs and creatives have ADHD — the same traits that cause challenges can be genuine strengths in the right context'
  ),
  (
    'Treatment Options Overview',
    'ADHD treatment is most effective when it combines multiple approaches tailored to the individual. Finding the right combination takes time, but ADHD is one of the most treatable conditions in mental health.\n\nAlways work with a qualified healthcare professional before starting or changing any treatment.\n\nThe full toolkit:\n• Stimulant medication (methylphenidate, amphetamine salts) is the most evidence-based treatment — effective in ~70–80% of people\n• Non-stimulant options (atomoxetine, guanfacine) are available for those who cannot tolerate stimulants\n• Cognitive Behavioural Therapy (CBT) targets executive function skills medication alone does not fully address\n• ADHD coaching focuses on practical systems, accountability, and goal-setting\n• Exercise is one of the most powerful non-medication interventions — 30 minutes of aerobic activity can improve focus for up to 2 hours\n• Protein-rich breakfasts stabilise dopamine; omega-3 supplementation has moderate evidence for symptom support\n• Mindfulness-Based Cognitive Therapy (MBCT) has emerging evidence for improving attention and reducing emotional reactivity'
  ),
];

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});
  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  final _open = <int>{};

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppProvider>();
    return Scaffold(
      body: SafeArea(
          child: Column(children: [
        Container(
          color: AppColors.mint,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(children: [
            IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 18),
                onPressed: () => app.navigate(AppScreen.home)),
            const Expanded(
                child: Center(
                    child: Text('Learn',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w600)))),
            const SizedBox(width: 48),
          ]),
        ),
        Expanded(
            child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _articles.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final (title, body) = _articles[i];
            final isOpen = _open.contains(i);
            return Container(
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.3))),
              child: Column(children: [
                GestureDetector(
                  onTap: () => setState(() {
                    isOpen ? _open.remove(i) : _open.add(i);
                  }),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(children: [
                      Expanded(
                          child: Text(title,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark))),
                      Icon(
                          isOpen
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: AppColors.textMid),
                    ]),
                  ),
                ),
                if (isOpen)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(body,
                        style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textMid,
                            height: 1.65)),
                  ),
              ]),
            );
          },
        )),
        AidhdBottomNav(active: AppScreen.learn, onTap: app.navigate),
      ])),
    );
  }
}

// ── Notification Settings ─────────────────────────────────────────────────────

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});
  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final _toggles = {'assessment': true, 'mood': true, 'chat': true};
  var _sound = true;
  var _vibration = true;

  static const _items = [
    (
      'assessment',
      'Daily Assessment Reminder',
      'Remind me to complete my daily check-in.'
    ),
    ('mood', 'Daily Mood Check-in', 'Remind me to log my mood each day.'),
    ('chat', 'New Chat Messages', 'Notify me of new assistant responses.'),
  ];

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppProvider>();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.mint,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 18),
            onPressed: () => app.navigate(AppScreen.settings)),
        title: const Text('Notifications'),
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Choose which notifications to receive.',
            style: TextStyle(fontSize: 13, color: AppColors.textMid)),
        const SizedBox(height: 12),
        ..._items.map((item) {
          final (key, label, desc) = item;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _NotifCard(
                label: label,
                desc: desc,
                value: _toggles[key]!,
                onToggle: () =>
                    setState(() => _toggles[key] = !_toggles[key]!)),
          );
        }),
        const SizedBox(height: 8),
        const Text('Sound & Vibration',
            style: TextStyle(fontSize: 13, color: AppColors.textMid)),
        const SizedBox(height: 8),
        _NotifCard(
            label: 'Sound',
            desc: '',
            value: _sound,
            onToggle: () => setState(() => _sound = !_sound)),
        const SizedBox(height: 12),
        _NotifCard(
            label: 'Vibration',
            desc: '',
            value: _vibration,
            onToggle: () => setState(() => _vibration = !_vibration)),
      ]),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final String label, desc;
  final bool value;
  final VoidCallback onToggle;
  const _NotifCard(
      {required this.label,
      required this.desc,
      required this.value,
      required this.onToggle});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.3))),
        child: Row(children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark)),
                if (desc.isNotEmpty)
                  Text(desc,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textMid, height: 1.4)),
              ])),
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 50,
              height: 28,
              decoration: BoxDecoration(
                  color: value ? AppColors.primary : const Color(0xFFCCCCCC),
                  borderRadius: BorderRadius.circular(14)),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle))),
              ),
            ),
          ),
        ]),
      );
}

// ── Privacy Policy ────────────────────────────────────────────────────────────

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _sections = [
    (
      'Information We Collect',
      'We collect profile information (name, age, gender), assessment responses and scores, mood check-in entries and notes, and activity logs you record.'
    ),
    (
      'How We Use Your Information',
      'Your information is used exclusively to personalize your AIDHD experience, track your progress over time, provide relevant tips and resources, and improve the app. We do not sell your data to third parties.'
    ),
    (
      'Data Storage & Security',
      'Your data is stored securely on your device. You can delete your account and all associated data at any time.'
    ),
    (
      'Your Rights',
      'You have the right to access, correct, or delete your personal data at any time. Use the Profile settings or contact our support team.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppProvider>();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.mint,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 18),
            onPressed: () => app.navigate(AppScreen.settings)),
        title: const Text('Privacy Policy'),
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Last Updated: September 7, 2026',
            style: TextStyle(fontSize: 12, color: AppColors.textMid)),
        const SizedBox(height: 16),
        ..._sections.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.3))),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.$1,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark)),
                      const SizedBox(height: 8),
                      Text(s.$2,
                          style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textMid,
                              height: 1.65)),
                    ]),
              ),
            )),
      ]),
    );
  }
}

// ── Help & Support ────────────────────────────────────────────────────────────

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});
  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final _open = <int>{};

  static const _faqs = [
    (
      'What is AIDHD?',
      'AIDHD is an AI-powered support app designed to help people with ADHD manage their daily routines, track their mood, and access educational resources.'
    ),
    (
      'Is my data private?',
      'Yes. Your data is stored securely on your device and is never sold to third parties. See our Privacy Policy for full details.'
    ),
    (
      'How do I log my mood?',
      'From the Home screen, tap one of the mood emoji buttons. You can add a note and tag activities before saving.'
    ),
    (
      'What does the Daily Assessment measure?',
      'It uses ASRS-style questions to give you a snapshot of your ADHD-related challenges for the day. It is not a clinical diagnosis.'
    ),
    (
      'Can I edit my profile?',
      'Yes! Go to Home → Profile. Tap the edit icon next to your name or age to edit, and tap Gender to pick from the dropdown.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppProvider>();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.mint,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 18),
            onPressed: () => app.navigate(AppScreen.settings)),
        title: const Text('Help & Support'),
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('FREQUENTLY ASKED QUESTIONS',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: AppColors.textMid)),
        const SizedBox(height: 12),
        ..._faqs.asMap().entries.map((e) {
          final isOpen = _open.contains(e.key);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.3))),
              child: Column(children: [
                GestureDetector(
                  onTap: () => setState(() {
                    isOpen ? _open.remove(e.key) : _open.add(e.key);
                  }),
                  child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(children: [
                        Expanded(
                            child: Text(e.value.$1,
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textDark))),
                        Icon(
                            isOpen
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: AppColors.textMid),
                      ])),
                ),
                if (isOpen)
                  Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Text(e.value.$2,
                          style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textMid,
                              height: 1.65))),
              ]),
            ),
          );
        }),
        const SizedBox(height: 16),
        const Text('MORE HELP',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: AppColors.textMid)),
        const SizedBox(height: 12),
        ...['✉️ Contact Support', '💬 Send Feedback', '📖 User Guide']
            .map((label) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.border.withValues(alpha: 0.3))),
                    child: Row(children: [
                      Text(label.split(' ').first,
                          style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(label.split(' ').sublist(1).join(' '),
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark))),
                      const Icon(Icons.chevron_right, color: AppColors.textMid),
                    ]),
                  ),
                )),
      ]),
    );
  }
}
