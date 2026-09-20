import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../utils/input_validation.dart';

// ── Legal content ─────────────────────────────────────────────────────────────

const _termsTitle = 'Terms and Conditions';
const _privacyTitle = 'Privacy Policy';

const _termsSections = [
  (
    'Acceptance of Terms',
    'By registering and using AiDHD, you agree to these Terms and Conditions.'
  ),
  (
    'Not a Medical Service',
    'AiDHD is a self-management and educational tool. Nothing in AiDHD constitutes a medical diagnosis or clinical advice. Always consult a licensed healthcare professional for diagnosis and treatment of ADHD or any other condition.'
  ),
  (
    'AI Chat Disclaimer',
    'The AI chat assistant is designed for general ADHD-related support and educational topics only. It is not a substitute for professional mental health care. Do not rely on it in emergencies — contact emergency services or a crisis line immediately if needed.'
  ),
  (
    'Account Responsibilities',
    'You are responsible for keeping your login credentials secure and providing accurate information. You may not use the app for any unlawful purpose.'
  ),
  (
    'Data and Privacy',
    'Your personal data is stored locally on your device and optionally in Firebase. We do not sell or share your data with third parties. You may delete your account at any time.'
  ),
  (
    'Limitation of Liability',
    'AiDHD is provided "as is" without warranties. We are not liable for decisions made based on information provided by the app.'
  ),
  (
    'Changes to Terms',
    'We may update these Terms from time to time. Continued use constitutes acceptance of the updated Terms.'
  ),
];

const _privacySections = [
  (
    'Information We Collect',
    'We collect the profile information you provide (name, age, gender, email, username), assessment responses and scores, mood check-in entries and notes, and activity logs you record.'
  ),
  (
    'How We Use Your Information',
    'Your information is used exclusively to personalise your AiDHD experience, track your progress over time, and power age-appropriate AI responses. We do not sell your data.'
  ),
  (
    'Data Storage & Security',
    'Your data is stored securely on your device using local storage and optionally Firebase. No data is shared with third parties.'
  ),
  (
    'Your Rights',
    'You have the right to access, correct, or delete your data at any time from the Profile settings.'
  ),
  (
    'Contact',
    'For any privacy concerns, use the Help & Support section of the app.'
  ),
];

void _showLegal(BuildContext context, {required bool isTerms}) {
  final title = isTerms ? _termsTitle : _privacyTitle;
  final sections = isTerms ? _termsSections : _privacySections;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: const Color(0xFFDDE1DE),
                    borderRadius: BorderRadius.circular(2))),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
            child: Row(children: [
              Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark))),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF3F4F4)),
              ),
            ]),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.all(20),
              children: [
                const Text('Last Updated: September 2026',
                    style: TextStyle(fontSize: 12, color: AppColors.textMid)),
                const SizedBox(height: 16),
                ...sections.map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.$1,
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark)),
                            const SizedBox(height: 6),
                            Text(s.$2,
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textMid,
                                    height: 1.6)),
                          ]),
                    )),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Got it'),
            ),
          ),
        ]),
      ),
    ),
  );
}

// ── Sign-up screen ────────────────────────────────────────────────────────────

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  final _ageFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _showPassword = false;
  bool _showConfirm = false;
  bool _agreed = false;
  final _formErrors = <String, String>{};

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _ageCtrl,
      _emailCtrl,
      _usernameCtrl,
      _passwordCtrl,
      _confirmCtrl
    ]) {
      c.dispose();
    }
    for (final f in [
      _ageFocus,
      _emailFocus,
      _usernameFocus,
      _passwordFocus,
      _confirmFocus
    ]) {
      f.dispose();
    }
    super.dispose();
  }

  bool _validate() {
    final errs = <String, String>{};
    final nameError = InputValidation.nameError(_nameCtrl.text);
    if (nameError != null) {
      errs['name'] = nameError;
    }
    final ageError = InputValidation.ageError(_ageCtrl.text);
    if (ageError != null) {
      errs['age'] = ageError;
    }
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
        .hasMatch(_emailCtrl.text.trim())) {
      errs['email'] = 'Valid email required.';
    }
    final usernameError = InputValidation.usernameError(_usernameCtrl.text);
    if (usernameError != null) {
      errs['username'] = usernameError;
    }
    if (_passwordCtrl.text.length < 7) {
      errs['password'] = 'Password must be at least 7 characters.';
    }
    if (_passwordCtrl.text != _confirmCtrl.text) {
      errs['confirm'] = 'Passwords do not match.';
    }
    if (!_agreed) {
      errs['agreed'] = 'You must agree to the Terms and Privacy Policy.';
    }
    setState(() {
      _formErrors.clear();
      _formErrors.addAll(errs);
    });
    return errs.isEmpty;
  }

  void _register(AppProvider app) {
    if (!_validate()) return;
    app.register(
      _nameCtrl.text.trim(),
      _emailCtrl.text.trim(),
      _usernameCtrl.text.trim(),
      _passwordCtrl.text,
      age: _ageCtrl.text.trim(),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl,
    String errorKey, {
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
    FocusNode? focusNode,
    FocusNode? nextFocus,
    TextInputAction textInputAction = TextInputAction.next,
    VoidCallback? onSubmit,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textDark)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboardType,
          obscureText: obscure,
          inputFormatters: inputFormatters,
          maxLength: maxLength,
          focusNode: focusNode,
          textInputAction: textInputAction,
          onFieldSubmitted: (_) {
            if (onSubmit != null) {
              onSubmit();
            } else if (nextFocus != null) {
              FocusScope.of(context).requestFocus(nextFocus);
            }
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: _formErrors.containsKey(errorKey)
                      ? AppColors.error
                      : AppColors.border,
                  width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            suffixIcon: suffix,
          ),
        ),
        if (_formErrors.containsKey(errorKey))
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(_formErrors[errorKey]!,
                style: const TextStyle(fontSize: 11, color: AppColors.error)),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.only(top: 40, bottom: 12),
              child: Column(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset('assets/brain_logo.png',
                      width: 94, height: 94, fit: BoxFit.cover),
                ),
                const SizedBox(height: 12),
                const Text('AiDHD',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        letterSpacing: -0.5)),
                const SizedBox(height: 4),
                const Text(
                  'Your calm, focused companion for ADHD support',
                  style: TextStyle(fontSize: 12, color: AppColors.textMid),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text('Create Account',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark)),
              ]),
            ),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _field('Name', _nameCtrl, 'name',
                        nextFocus: _ageFocus, maxLength: 80),
                    const SizedBox(height: 16),
                    // Age field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Age',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textDark)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _ageCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          maxLength: 3,
                          focusNode: _ageFocus,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) =>
                              FocusScope.of(context).requestFocus(_emailFocus),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: _formErrors.containsKey('age')
                                      ? AppColors.error
                                      : AppColors.border,
                                  width: 2),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: AppColors.primary, width: 2),
                            ),
                          ),
                        ),
                        if (_formErrors.containsKey('age'))
                          Padding(
                            padding: const EdgeInsets.only(top: 4, left: 4),
                            child: Text(_formErrors['age']!,
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.error)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _field(
                      'Email',
                      _emailCtrl,
                      'email',
                      keyboardType: TextInputType.emailAddress,
                      focusNode: _emailFocus,
                      nextFocus: _usernameFocus,
                    ),
                    const SizedBox(height: 16),
                    _field(
                      'Username',
                      _usernameCtrl,
                      'username',
                      focusNode: _usernameFocus,
                      nextFocus: _passwordFocus,
                      maxLength: 20,
                    ),
                    const SizedBox(height: 16),
                    _field(
                      'Password',
                      _passwordCtrl,
                      'password',
                      obscure: !_showPassword,
                      focusNode: _passwordFocus,
                      nextFocus: _confirmFocus,
                      suffix: IconButton(
                        icon: Icon(
                            _showPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.textMid),
                        onPressed: () =>
                            setState(() => _showPassword = !_showPassword),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 4, left: 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Password should contain 7+ characters',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMid)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _field(
                      'Confirm Password',
                      _confirmCtrl,
                      'confirm',
                      obscure: !_showConfirm,
                      focusNode: _confirmFocus,
                      textInputAction: TextInputAction.done,
                      onSubmit: () => _register(app),
                      suffix: IconButton(
                        icon: Icon(
                            _showConfirm
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.textMid),
                        onPressed: () =>
                            setState(() => _showConfirm = !_showConfirm),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Terms checkbox
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => _agreed = !_agreed),
                          child: Container(
                            width: 20,
                            height: 20,
                            margin: const EdgeInsets.only(top: 2),
                            decoration: BoxDecoration(
                              color: _agreed ? AppColors.primary : Colors.white,
                              border: Border.all(
                                color: _formErrors.containsKey('agreed')
                                    ? AppColors.error
                                    : (_agreed
                                        ? AppColors.primary
                                        : AppColors.textMid),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: _agreed
                                ? const Icon(Icons.check,
                                    size: 14, color: Colors.white)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text.rich(TextSpan(
                            style: const TextStyle(
                                fontSize: 15, color: AppColors.textMid),
                            children: [
                              const TextSpan(text: 'I agree to the '),
                              WidgetSpan(
                                child: GestureDetector(
                                  onTap: () =>
                                      _showLegal(context, isTerms: true),
                                  child: const Text('Terms and Conditions',
                                      style: TextStyle(
                                          fontSize: 15,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600,
                                          decoration:
                                              TextDecoration.underline)),
                                ),
                              ),
                              const TextSpan(text: ' and '),
                              WidgetSpan(
                                child: GestureDetector(
                                  onTap: () =>
                                      _showLegal(context, isTerms: false),
                                  child: const Text('Privacy Policy',
                                      style: TextStyle(
                                          fontSize: 15,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600,
                                          decoration:
                                              TextDecoration.underline)),
                                ),
                              ),
                            ],
                          )),
                        ),
                      ],
                    ),
                    if (_formErrors.containsKey('agreed'))
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4, left: 4),
                          child: Text(_formErrors['agreed']!,
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.error)),
                        ),
                      ),

                    if (app.error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: const Color(0xFFFFF2F2),
                            border: Border.all(color: const Color(0xFFFFC7C7)),
                            borderRadius: BorderRadius.circular(10)),
                        child: Text(app.error!,
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.error)),
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFF0F0F0)))),
              child: Column(
                children: [
                  app.loading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary))
                      : ElevatedButton(
                          onPressed: () => _register(app),
                          child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Sign Up', style: TextStyle(fontSize: 18)),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward, size: 18),
                              ]),
                        ),
                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Text('Already have an account? ',
                        style:
                            TextStyle(fontSize: 15, color: AppColors.textMid)),
                    GestureDetector(
                      onTap: () => app.navigate(AppScreen.login),
                      child: const Text('Log in',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary)),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
