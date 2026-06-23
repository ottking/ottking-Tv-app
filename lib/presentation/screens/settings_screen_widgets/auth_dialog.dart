// lib/presentation/screens/settings_screen_widgets/auth_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../providers/app_state.dart';

class AuthDialog extends StatefulWidget {
  const AuthDialog({super.key});

  @override
  State<AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<AuthDialog> {
  bool _isRegister = false;
  bool _loading = false;
  final _email = TextEditingController();
  final _pass = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit(AppState appState) async {
    if (_email.text.trim().isEmpty || _pass.text.isEmpty) return;
    setState(() => _loading = true);
    _isRegister
        ? await appState.register(_email.text.trim(), _pass.text)
        : await appState.login(_email.text.trim(), _pass.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (appState.errorMessage.isEmpty) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return AlertDialog(
      backgroundColor: const Color(0xFF131B2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        _isRegister ? 'Create Account' : 'Sign In',
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Field(
                ctrl: _email, label: 'Email', icon: Icons.email_outlined),
            const SizedBox(height: 16),
            _Field(
              ctrl: _pass,
              label: 'Password',
              icon: Icons.lock_outline,
              obscure: true,
            ),
            const SizedBox(height: 12),
            TextButton(
              autofocus: true,
              onPressed: () =>
                  setState(() => _isRegister = !_isRegister),
              child: Text(
                _isRegister
                    ? 'Already have an account? Sign in': 'Create a new account',
                style: const TextStyle(color: AppTheme.primary),
              ),
            ),
            if (appState.errorMessage.isNotEmpty)
              Text(appState.errorMessage,
                  style: const TextStyle(
                      color: Colors.redAccent, fontSize: 13)),
          ],
        ),
      ),
      actions: [
        if (appState.isAuthenticated)
          TextButton(
            onPressed: () {
              appState.logout();
              Navigator.pop(context);
            },
            child: const Text('Logout',
                style: TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel',
              style: TextStyle(color: Colors.white38)),
        ),
        FilledButton(
          onPressed: _loading ? null : () => _submit(appState),
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.primary,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
                  ))
              : Text(
                  _isRegister ? 'Register' : 'Sign In',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.black),
                ),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.ctrl,
    required this.label,
    required this.icon,
    this.obscure = false,
  });
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final bool obscure;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(icon, color: Colors.white38),
        enabledBorder: UnderlineInputBorder(
            borderSide:
                BorderSide(color: Colors.white.withOpacity(0.08))),
        focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppTheme.primary)),
      ),
    );
  }
}
