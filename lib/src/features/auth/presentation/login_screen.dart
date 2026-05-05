import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/auth_controller.dart';
import '../domain/auth_state.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _passwordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final ok = await ref.read(authControllerProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
    if (!mounted) return;
    if (ok) {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    ref.listen<AuthStateData>(authControllerProvider, (previous, next) {
      if (next.status == AuthStatus.error && next.error != null) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text(next.error!),
              backgroundColor: scheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    });

    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scheme.primaryContainer,
                scheme.surface,
                scheme.secondaryContainer,
              ],
              stops: const [0, 0.5, 1],
            ),
          ),
          child: SafeArea(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              behavior: HitTestBehavior.translucent,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: KioskTokens.spaceL,
                    vertical: KioskTokens.spaceXL,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _LogoMark(color: scheme.primary),
                          const SizedBox(height: KioskTokens.spaceL),
                          Text(
                            l10n.loginTitle,
                            style: Theme.of(context).textTheme.displayMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: KioskTokens.spaceXS),
                          Text(
                            l10n.loginSubtitle,
                            textAlign: TextAlign.center,
                            style:
                                Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: scheme.secondary,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 2,
                                    ),
                          ),
                          const SizedBox(height: KioskTokens.spaceXL),
                          _EmailField(
                            controller: _emailController,
                            focusNode: _emailFocus,
                            label: l10n.loginEmail,
                            requiredError: l10n.loginEmailRequired,
                            enabled: !isLoading,
                            onSubmitted: (_) =>
                                _passwordFocus.requestFocus(),
                          ),
                          const SizedBox(height: KioskTokens.spaceM),
                          _PasswordField(
                            controller: _passwordController,
                            focusNode: _passwordFocus,
                            label: l10n.loginPassword,
                            requiredError: l10n.loginPasswordRequired,
                            enabled: !isLoading,
                            visible: _passwordVisible,
                            onToggleVisibility: () => setState(
                              () => _passwordVisible = !_passwordVisible,
                            ),
                            onSubmitted: (_) => _submit(),
                          ),
                          const SizedBox(height: KioskTokens.spaceXL),
                          SizedBox(
                            width: double.infinity,
                            height: KioskTokens.touchTargetHero,
                            child: FilledButton(
                              onPressed: isLoading ? null : _submit,
                              style: FilledButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    KioskTokens.radiusXLarge,
                                  ),
                                ),
                              ),
                              child: isLoading
                                  ? SizedBox(
                                      width: 32,
                                      height: 32,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          scheme.onPrimary,
                                        ),
                                      ),
                                    )
                                  : FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        l10n.loginSignIn,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineLarge
                                            ?.copyWith(
                                              color: scheme.onPrimary,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 1.5,
                                            ),
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmailField extends StatelessWidget {
  const _EmailField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.requiredError,
    required this.enabled,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String requiredError;
  final bool enabled;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        keyboardType: TextInputType.visiblePassword,
        textInputAction: TextInputAction.next,
        autocorrect: false,
        enableSuggestions: false,
        showCursor: true,
        style: const TextStyle(fontSize: 24, height: 1.2),
        onFieldSubmitted: onSubmitted,
        onTap: () => SystemChannels.textInput.invokeMethod('TextInput.show'),
        validator: (value) =>
            (value == null || value.trim().isEmpty) ? requiredError : null,
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(
            fontSize: 22,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          prefixIcon: const Padding(
            padding: EdgeInsetsDirectional.only(start: 16, end: 8),
            child: Icon(Icons.alternate_email_rounded, size: 28),
          ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 56, minHeight: 56),
          filled: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(KioskTokens.radiusMedium),
          ),
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.requiredError,
    required this.enabled,
    required this.visible,
    required this.onToggleVisibility,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String requiredError;
  final bool enabled;
  final bool visible;
  final VoidCallback onToggleVisibility;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        obscureText: !visible,
        keyboardType: TextInputType.visiblePassword,
        textInputAction: TextInputAction.done,
        autocorrect: false,
        enableSuggestions: false,
        showCursor: true,
        style: const TextStyle(fontSize: 24, height: 1.2),
        onFieldSubmitted: onSubmitted,
        onTap: () => SystemChannels.textInput.invokeMethod('TextInput.show'),
        validator: (value) =>
            (value == null || value.isEmpty) ? requiredError : null,
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(
            fontSize: 22,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          prefixIcon: const Padding(
            padding: EdgeInsetsDirectional.only(start: 16, end: 8),
            child: Icon(Icons.lock_rounded, size: 28),
          ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 56, minHeight: 56),
          suffixIcon: IconButton(
            iconSize: 28,
            icon: Icon(
              visible
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded,
            ),
            onPressed: onToggleVisibility,
          ),
          filled: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(KioskTokens.radiusMedium),
          ),
        ),
      ),
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(KioskTokens.radiusXLarge),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 32,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(
        Icons.lock_person_rounded,
        size: 76,
        color: Colors.white,
      ),
    );
  }
}
