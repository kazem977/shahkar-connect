import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shahkar_connect/theme.dart';
import 'package:shahkar_connect/ui/app_chrome.dart';
import 'package:shahkar_connect/ui/vpnai_logo.dart';
import 'package:shahkar_connect/ui/vpnai_wordmark.dart';

/// Luxury-minimal auth layout for the vpnai client (no page scroll).
class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.child,
    this.onBack,
    this.footer,
    this.compact = false,
  });

  final Widget child;
  final VoidCallback? onBack;
  final Widget? footer;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showBack: onBack != null,
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _LuxuryBackdrop(),
          Padding(
            padding: EdgeInsets.fromLTRB(28, compact ? 4 : 8, 28, 20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _BrandHero(compact: compact),
                    SizedBox(height: compact ? 22 : 32),
                    child,
                    if (footer != null) ...[
                      const SizedBox(height: 14),
                      footer!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LuxuryBackdrop extends StatelessWidget {
  const _LuxuryBackdrop();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF10141B),
            ShahkarTheme.ink,
            Color(0xFF080A0E),
          ],
          stops: [0.0, 0.45, 1.0],
        ),
      ),
      child: CustomPaint(
        painter: _SoftGlowPainter(),
        child: SizedBox.expand(),
      ),
    );
  }
}

class _SoftGlowPainter extends CustomPainter {
  const _SoftGlowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.22);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          ShahkarTheme.accent.withValues(alpha: 0.08),
          ShahkarTheme.accent.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 160));
    canvas.drawCircle(center, 160, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BrandHero extends StatelessWidget {
  const _BrandHero({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final mark = compact ? 64.0 : 80.0;
    return Column(
      children: [
        VpnaiLogo(size: mark),
        SizedBox(height: compact ? 14 : 18),
        VpnaiWordmark(
          fontSize: compact ? 24 : 27,
          underline: true,
        ),
      ],
    );
  }
}

class AuthField extends StatelessWidget {
  const AuthField({
    super.key,
    required this.controller,
    required this.label,
    this.obscure = false,
    this.onToggleObscure,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.onSubmitted,
    this.validator,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback? onToggleObscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      autocorrect: false,
      enableSuggestions: false,
      inputFormatters: inputFormatters,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: ShahkarTheme.fog,
        letterSpacing: 0.2,
      ),
      cursorColor: ShahkarTheme.accent,
      validator: validator,
      onFieldSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: label,
        hintStyle: TextStyle(
          color: ShahkarTheme.mute.withValues(alpha: 0.75),
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: const Color(0xFF14191F),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: ShahkarTheme.line.withValues(alpha: 0.9),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF232A33)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: ShahkarTheme.accent.withValues(alpha: 0.7),
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ShahkarTheme.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ShahkarTheme.danger),
        ),
        errorStyle: const TextStyle(fontSize: 11, height: 1.15),
        suffixIcon: onToggleObscure == null
            ? null
            : IconButton(
                onPressed: onToggleObscure,
                splashRadius: 18,
                iconSize: 18,
                color: ShahkarTheme.mute,
                icon: Icon(
                  obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
      ),
    );
  }
}

class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: ShahkarTheme.danger,
        fontSize: 12,
        height: 1.35,
      ),
    );
  }
}

class AuthSubmitButton extends StatefulWidget {
  const AuthSubmitButton({
    super.key,
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  State<AuthSubmitButton> createState() => _AuthSubmitButtonState();
}

class _AuthSubmitButtonState extends State<AuthSubmitButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final enabled = !widget.busy && widget.onPressed != null;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: enabled && _hover
              ? [
                  BoxShadow(
                    color: ShahkarTheme.accent.withValues(alpha: 0.22),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : const [],
        ),
        child: SizedBox(
          height: 46,
          width: double.infinity,
          child: Material(
            color: enabled
                ? (_hover ? ShahkarTheme.accentSoft : ShahkarTheme.accent)
                : ShahkarTheme.accent.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: enabled
                  ? () {
                      HapticFeedback.selectionClick();
                      widget.onPressed?.call();
                    }
                  : null,
              borderRadius: BorderRadius.circular(12),
              child: Center(
                child: widget.busy
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ShahkarTheme.fog,
                        ),
                      )
                    : Text(
                        widget.label,
                        style: TextStyle(
                          color: enabled
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.55),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
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

/// Panel rule: 3–32 chars, letters/digits, underscores only in between.
final usernamePattern = RegExp(r'^[A-Za-z0-9](?:[A-Za-z0-9_]*[A-Za-z0-9])?$');
