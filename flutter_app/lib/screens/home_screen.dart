import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/history_entry.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav.dart';

const _moods = [
  (MoodLabel.happy, '😊', Color(0xFFCEEACB)),
  (MoodLabel.okay, '🙂', Color(0xFFFEF9C3)),
  (MoodLabel.sad, '😢', Color(0xFFFFDAD6)),
  (MoodLabel.stressed, '😰', Color(0xFFFFEDD5)),
  (MoodLabel.overwhelmed, '😩', Color(0xFFCBE9E0)),
];

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final todayEntries = app.history.where((e) => e.isToday).take(2).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                      child: Row(children: [
                        ClipOval(
                          child: Image.asset('assets/brain_logo.png',
                              width: 64, height: 64, fit: BoxFit.cover),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              const Text('Welcome,',
                                  style: TextStyle(
                                      fontSize: 14, color: AppColors.textMid)),
                              Text('${app.currentUser?.name ?? "there"}!',
                                  style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textDark)),
                            ])),
                        _HeaderIconBtn(
                          icon: Icons.settings_outlined,
                          onTap: () => app.navigate(AppScreen.settings),
                        ),
                      ]),
                    ),

                    // Chat + Assessment cards
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(children: [
                        _ActionCard(
                          icon: Icons.chat_bubble_outline,
                          title: 'Chat',
                          subtitle: 'Talk and get support',
                          onTap: () => app.navigate(AppScreen.chat),
                        ),
                        const SizedBox(width: 12),
                        _ActionCard(
                          icon: Icons.assignment_outlined,
                          title: 'Assessment',
                          subtitle: 'Take your daily assessment',
                          onTap: () => app.navigate(AppScreen.assessment),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 24),

                    // Daily Mood
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(children: [
                        const Text('Daily Mood Management',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 4),
                        const Text('How are you feeling today?',
                            style: TextStyle(
                                fontSize: 14, color: AppColors.textMid),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 20),
                          decoration: BoxDecoration(
                              color: AppColors.mint,
                              borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: _moods.map((m) {
                              final (mood, emoji, color) = m;
                              return GestureDetector(
                                onTap: () {
                                  app.setSelectedMood(mood);
                                  app.navigate(AppScreen.moodCheckin);
                                },
                                child: Column(children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                        color: color, shape: BoxShape.circle),
                                    child: Center(
                                        child: Text(emoji,
                                            style:
                                                const TextStyle(fontSize: 22))),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(mood.displayName,
                                      style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textMid)),
                                ]),
                              );
                            }).toList(),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 24),

                    // Today's history
                    if (todayEntries.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Today',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textDark)),
                              GestureDetector(
                                onTap: () => app.navigate(AppScreen.history),
                                child: const Text('See all',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.primary)),
                              ),
                            ]),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: todayEntries
                              .map((e) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: AppColors.border
                                                .withValues(alpha: 0.3)),
                                      ),
                                      child: Row(children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: e.type == EntryType.mood
                                                ? const Color(0xFFCEEACB)
                                                : const Color(0xFFE8DCFF),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                              child: Text(
                                                  e.type == EntryType.mood
                                                      ? (e.mood?.emoji ?? '😊')
                                                      : '📋',
                                                  style: const TextStyle(
                                                      fontSize: 18))),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                            child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                              Text(e.label,
                                                  style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color:
                                                          AppColors.textDark)),
                                              Text(e.timestamp,
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          AppColors.textMid)),
                                            ])),
                                      ]),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ),
            AidhdBottomNav(active: AppScreen.home, onTap: app.navigate),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ActionCard(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: SizedBox(
            height: 158,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(12)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                            color: Color(0xFFF2F4F2), shape: BoxShape.circle),
                        child: Icon(icon, color: AppColors.primary, size: 22)),
                    const SizedBox(height: 12),
                    Text(title,
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark)),
                    const SizedBox(height: 2),
                    Expanded(
                        child: Text(subtitle,
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textMid,
                                height: 1.4))),
                  ]),
            ),
          ),
        ),
      );
}

class _HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
      );
}
