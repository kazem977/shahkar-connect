import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shahkar_connect/core/l10n/locale_controller.dart';
import 'package:shahkar_connect/features/auth/data/auth_repository.dart';
import 'package:shahkar_connect/features/auth/presentation/auth_shell.dart';
import 'package:shahkar_connect/features/connect/presentation/main_shell.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _form = GlobalKey<FormState>();
  final _user = TextEditingController();
  final _pass = TextEditingController();
  final _email = TextEditingController();
  bool _busy = false;
  bool _hidePass = true;
  String? _error;

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = context.read<AuthRepository>();
    final s = context.read<LocaleController>().s;
    try {
      await auth.register(
        username: _user.text.trim(),
        password: _pass.text,
        email: _email.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const MainShell()),
        (_) => false,
      );
    } catch (e) {
      setState(() => _error = auth.describeError(e, s));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleController>().s;
    return AuthShell(
      compact: true,
      onBack: () => Navigator.of(context).maybePop(),
      child: AutofillGroup(
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthField(
                controller: _user,
                label: s.username,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newUsername],
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9_]')),
                  LengthLimitingTextInputFormatter(32),
                ],
                validator: (value) {
                  final v = value?.trim() ?? '';
                  if (v.isEmpty) return s.requiredField;
                  if (v.length < 3 || !usernamePattern.hasMatch(v)) {
                    return s.usernameInvalid;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              AuthField(
                controller: _email,
                label: s.email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
              ),
              const SizedBox(height: 10),
              AuthField(
                controller: _pass,
                label: s.password,
                obscure: _hidePass,
                onToggleObscure: () => setState(() => _hidePass = !_hidePass),
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                onSubmitted: (_) => _submit(),
                validator: (value) {
                  if (value == null || value.isEmpty) return s.requiredField;
                  if (value.length < 6) return s.passwordShort;
                  return null;
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                AuthErrorBanner(message: _error!),
              ],
              const SizedBox(height: 18),
              AuthSubmitButton(
                label: s.register,
                busy: _busy,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
