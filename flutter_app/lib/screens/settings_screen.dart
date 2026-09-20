import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppProvider>();

    final items = [
      (
        Icons.notifications_outlined,
        'Notification Settings',
        'Manage your notifications.',
        AppScreen.notificationSettings
      ),
      (
        Icons.lock_outline,
        'Privacy Policy',
        'Learn how we protect your data.',
        AppScreen.privacyPolicy
      ),
      (
        Icons.help_outline,
        'Help & Support',
        'Get help and contact support.',
        AppScreen.helpSupport
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.mint,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 18),
            onPressed: () => app.navigate(AppScreen.home)),
        title: const Text('Settings'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final (icon, title, subtitle, screen) = items[i];
          return GestureDetector(
            onTap: () => app.navigate(screen),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppColors.border.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                      color: AppColors.mint.withValues(alpha: 0.5),
                      shape: BoxShape.circle),
                  child: Icon(icon, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark)),
                      Text(subtitle,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textMid)),
                    ])),
                const Icon(Icons.chevron_right,
                    color: AppColors.textMid, size: 20),
              ]),
            ),
          );
        },
      ),
    );
  }
}
