import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _ageCtrl;
  bool _editingName = false;
  bool _editingAge = false;
  bool _showGender = false;

  static const _genderOptions = ['Male', 'Female', 'Prefer not to say'];

  String? _avatarEmoji(String? gender) {
    if (gender == 'Male') return '👨';
    if (gender == 'Female') return '👩';
    return null; // "Prefer not to say" → silhouette icon
  }

  @override
  void initState() {
    super.initState();
    final user = context.read<AppProvider>().currentUser;
    _nameCtrl = TextEditingController(text: user?.name ?? '');
    _ageCtrl = TextEditingController(text: user?.age ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final user = app.currentUser;
    final age = user?.age ?? '';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.mint,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 18),
            onPressed: () => app.navigate(AppScreen.home)),
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          // Avatar
          Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
                color: Color(0xFFEADDFF), shape: BoxShape.circle),
            child: Center(
              child: _avatarEmoji(user?.gender) != null
                  ? Text(_avatarEmoji(user?.gender)!,
                      style: const TextStyle(fontSize: 56))
                  : const Icon(Icons.person,
                      size: 68, color: Color(0xFF7B61B4)),
            ),
          ),
          const SizedBox(height: 8),
          Text(user?.name ?? '',
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark)),
          if (user != null)
            Text('@${user.username}',
                style: const TextStyle(fontSize: 13, color: AppColors.textMid)),
          const SizedBox(height: 24),

          // Name
          _ProfileField(
            icon: '👤',
            label: 'Name',
            isEditing: _editingName,
            displayValue: user?.name ?? '',
            controller: _nameCtrl,
            onEdit: () => setState(() => _editingName = true),
            onDone: () {
              setState(() => _editingName = false);
              app.updateProfile(name: _nameCtrl.text.trim());
            },
          ),
          const SizedBox(height: 12),

          // Age
          _ProfileField(
            icon: '🎂',
            label: 'Age',
            isEditing: _editingAge,
            displayValue: age.isNotEmpty ? age : '—',
            controller: _ageCtrl,
            keyboardType: TextInputType.number,
            onEdit: () => setState(() => _editingAge = true),
            onDone: () {
              setState(() => _editingAge = false);
              app.updateProfile(age: _ageCtrl.text.trim());
            },
          ),
          const SizedBox(height: 12),

          // Email
          if (user != null)
            _InfoField(icon: '✉️', label: 'Email', value: user.email),
          const SizedBox(height: 12),

          // Gender
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border)),
            child: Column(children: [
              Row(children: [
                const _IconBadge('⚧'),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      const Text('Gender',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textMid,
                              letterSpacing: 0.6)),
                      Text(user?.gender ?? 'Prefer not to say',
                          style: const TextStyle(
                              fontSize: 16, color: AppColors.textDark)),
                    ])),
                GestureDetector(
                  onTap: () => setState(() => _showGender = !_showGender),
                  child: Icon(
                      _showGender
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: AppColors.textMid),
                ),
              ]),
              if (_showGender) ...[
                const SizedBox(height: 8),
                const Divider(),
                ..._genderOptions.map((opt) => GestureDetector(
                      onTap: () {
                        setState(() => _showGender = false);
                        app.updateProfile(gender: opt);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 4),
                        child: Text(opt,
                            style: TextStyle(
                                fontSize: 15,
                                color: opt == user?.gender
                                    ? AppColors.primary
                                    : AppColors.textDark,
                                fontWeight: opt == user?.gender
                                    ? FontWeight.w600
                                    : FontWeight.w400)),
                      ),
                    )),
              ],
            ]),
          ),

          // Initial assessment result
          if (user?.initialAssessmentCategory != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: AppColors.mint.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.mint)),
              child: Row(children: [
                ClipOval(
                    child: Image.asset('assets/brain_logo.png',
                        width: 32, height: 32, fit: BoxFit.cover)),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      const Text('Initial Screening Result',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary)),
                      Text(user!.initialAssessmentCategory!,
                          style: const TextStyle(
                              fontSize: 15, color: AppColors.textDark)),
                      if (user.initialAssessmentScore != null)
                        Text('Score: ${user.initialAssessmentScore}/40',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textMid)),
                    ])),
              ]),
            ),
          ],

          const SizedBox(height: 32),
          GestureDetector(
            onTap: app.logout,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                  color: const Color(0xFFF2F4F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border)),
              child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout, color: AppColors.error, size: 18),
                    SizedBox(width: 8),
                    Text('Log Out',
                        style: TextStyle(fontSize: 16, color: AppColors.error)),
                  ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final String icon;
  final String label;
  final bool isEditing;
  final String displayValue;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final VoidCallback onEdit;
  final VoidCallback onDone;
  const _ProfileField(
      {required this.icon,
      required this.label,
      required this.isEditing,
      required this.displayValue,
      required this.controller,
      this.keyboardType,
      required this.onEdit,
      required this.onDone});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border)),
        child: Row(children: [
          _IconBadge(icon),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMid,
                        letterSpacing: 0.6)),
                isEditing
                    ? TextField(
                        controller: controller,
                        keyboardType: keyboardType,
                        autofocus: true,
                        onSubmitted: (_) => onDone(),
                        decoration:
                            const InputDecoration.collapsed(hintText: ''),
                        style: const TextStyle(
                            fontSize: 16, color: AppColors.textDark))
                    : Text(displayValue,
                        style: const TextStyle(
                            fontSize: 16, color: AppColors.textDark)),
              ])),
          GestureDetector(
            onTap: isEditing ? onDone : onEdit,
            child: Icon(isEditing ? Icons.check : Icons.edit_outlined,
                color: AppColors.primary, size: 18),
          ),
        ]),
      );
}

class _InfoField extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  const _InfoField(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border)),
        child: Row(children: [
          _IconBadge(icon),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMid,
                        letterSpacing: 0.6)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 16, color: AppColors.textDark)),
              ])),
        ]),
      );
}

class _IconBadge extends StatelessWidget {
  final String emoji;
  const _IconBadge(this.emoji);
  @override
  Widget build(BuildContext context) => Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
            color: Color(0xFFECEEEC), shape: BoxShape.circle),
        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 18))),
      );
}
