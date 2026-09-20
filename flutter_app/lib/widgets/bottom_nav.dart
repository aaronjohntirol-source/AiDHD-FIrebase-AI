import 'package:flutter/material.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class AidhdBottomNav extends StatelessWidget {
  final AppScreen active;
  final void Function(AppScreen) onTap;

  const AidhdBottomNav({super.key, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      (AppScreen.home, Icons.home_outlined, Icons.home, 'Home'),
      (AppScreen.history, Icons.history_outlined, Icons.history, 'History'),
      (AppScreen.learn, Icons.menu_book_outlined, Icons.menu_book, 'Learn'),
      (AppScreen.profile, Icons.person_outline, Icons.person, 'Profile'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE0E8E4), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: items.map((item) {
            final (screen, outlinedIcon, filledIcon, label) = item;
            final isActive = active == screen;
            return Expanded(
              child: GestureDetector(
                onTap: () => onTap(screen),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isActive ? filledIcon : outlinedIcon,
                        color: isActive ? AppColors.primary : AppColors.textMid,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w400,
                          color:
                              isActive ? AppColors.primary : AppColors.textMid,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
