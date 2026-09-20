import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/initial_assessment_screen.dart';
import 'screens/home_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/remaining_screens.dart';

class AidhdApp extends StatelessWidget {
  const AidhdApp({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();

    return MaterialApp(
      title: 'AIDHD',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: _Router(screen: app.screen),
    );
  }
}

class _Router extends StatelessWidget {
  final AppScreen screen;
  const _Router({required this.screen});

  @override
  Widget build(BuildContext context) {
    switch (screen) {
      case AppScreen.login:
        return const LoginScreen();
      case AppScreen.signup:
        return const SignUpScreen();
      case AppScreen.initialAssessment:
        return const InitialAssessmentScreen();
      case AppScreen.home:
        return const HomeScreen();
      case AppScreen.moodCheckin:
        return const MoodCheckinScreen();
      case AppScreen.assessment:
        return const AssessmentScreen();
      case AppScreen.assessmentResult:
        return const AssessmentResultScreen();
      case AppScreen.history:
        return const HistoryScreen();
      case AppScreen.learn:
        return const LearnScreen();
      case AppScreen.chat:
        return const ChatScreen();
      case AppScreen.profile:
        return const ProfileScreen();
      case AppScreen.settings:
        return const SettingsScreen();
      case AppScreen.notificationSettings:
        return const NotificationSettingsScreen();
      case AppScreen.privacyPolicy:
        return const PrivacyPolicyScreen();
      case AppScreen.helpSupport:
        return const HelpSupportScreen();
    }
  }
}
