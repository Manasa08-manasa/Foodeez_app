import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/auth_controller.dart';
import '../controllers/navigation_controller.dart';
import '../utils/theme.dart';
import '../widgets/common.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter email and password'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    try {
      final ok = await ref.read(authControllerProvider).login(email, password);
      if (!ok && mounted) {
        final err = ref.read(authControllerProvider).error ?? 'Login failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err, maxLines: 4, overflow: TextOverflow.ellipsis),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString(), maxLines: 4, overflow: TextOverflow.ellipsis),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.red,
        ),
      );
    }
  }

  void _ensureVisible() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.surface,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.onboardingGradTop, AppColors.surface],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: SingleChildScrollView(
                    controller: _scrollCtrl,
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(26, 16, 26, 26),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight - 42),
                      child: Column(
                        mainAxisAlignment: keyboardOpen ? MainAxisAlignment.start : MainAxisAlignment.center,
                        children: [
                          if (!keyboardOpen) ...[
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 168,
                                  height: 168,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        AppColors.accent.withValues(alpha: 0.12),
                                        AppColors.onboardingGradTop.withValues(alpha: 0),
                                      ],
                                    ),
                                  ),
                                ),
                                Image.asset(
                                  'assets/images/foodeez-icon-clear.png',
                                  width: 128,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, error, stackTrace) => Image.asset(
                                    'assets/images/foodeez-mark.png',
                                    width: 104,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                          ] else
                            const SizedBox(height: 8),
                          RichText(
                            text: TextSpan(
                              style: AppText.display(size: keyboardOpen ? 22 : 28, letterSpacing: -0.6),
                              children: const [
                                TextSpan(text: 'Foodeez '),
                                TextSpan(text: 'Partner', style: TextStyle(color: AppColors.accent)),
                              ],
                            ),
                          ),
                          if (!keyboardOpen) ...[
                            const SizedBox(height: 8),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 280),
                              child: Text(
                                'Run your kitchen — accept orders, manage your menu, track earnings.',
                                textAlign: TextAlign.center,
                                style: AppText.body(size: 14, color: AppColors.bodyGrey),
                              ),
                            ),
                          ],
                          SizedBox(height: keyboardOpen ? 20 : 32),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F1E8),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: AppColors.inputBorder, width: 1.5),
                            ),
                            child: TextField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              autocorrect: false,
                              textInputAction: TextInputAction.next,
                              onTap: _ensureVisible,
                              style: AppText.body(size: 15, weight: FontWeight.w600),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Partner email',
                                hintStyle: AppText.body(size: 15, color: AppColors.lightGreyText),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F1E8),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: AppColors.inputBorder, width: 1.5),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _passwordCtrl,
                                    obscureText: _obscure,
                                    textInputAction: TextInputAction.done,
                                    onTap: _ensureVisible,
                                    onSubmitted: (_) => _submit(),
                                    style: AppText.body(size: 15, weight: FontWeight.w600),
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: 'Password',
                                      hintStyle: AppText.body(size: 15, color: AppColors.lightGreyText),
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => setState(() => _obscure = !_obscure),
                                  child: Icon(
                                    _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    size: 20,
                                    color: AppColors.lightGreyText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          PrimaryButton(
                            label: auth.loading ? 'Signing in…' : 'Log in to dashboard',
                            onTap: auth.loading ? () {} : _submit,
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () => ref.read(navigationControllerProvider).go('register'),
                            child: RichText(
                              text: TextSpan(
                                style: AppText.body(size: 12.5, color: AppColors.lightGreyText),
                                children: const [
                                  TextSpan(text: 'New here? '),
                                  TextSpan(text: 'Register your restaurant', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: keyboardOpen ? 12 : 8),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
