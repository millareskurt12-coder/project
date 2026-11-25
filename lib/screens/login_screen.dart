import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../widgets/app_logo.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onLogin, this.authService});

  final Future<void> Function(UserModel user, bool rememberMe) onLogin;
  final AuthService? authService;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _loading = false;
  String? _error;
  String? _notice;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _openRegistration() async {
    final username = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => RegisterScreen(authService: widget.authService),
      ),
    );
    if (username != null && mounted) {
      setState(() {
        _usernameController.text = username;
        _notice = 'Account created. Sign in to continue.';
        _error = null;
      });
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
      _notice = null;
    });
    try {
      final user = await (widget.authService ?? AuthService()).login(
        username: _usernameController.text,
        password: _passwordController.text,
      );
      if (user == null) {
        setState(() => _error = 'Incorrect username or password.');
        return;
      }
      await widget.onLogin(user, _rememberMe);
    } catch (error) {
      if (mounted) setState(() => _error = 'Could not sign in: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F6),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: AppLogo(size: 68)),
                  const SizedBox(height: 22),
                  Text(
                    'Welcome back',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to stay on top of your money.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: const Color(0xFF687687)),
                  ),
                  const SizedBox(height: 28),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _usernameController,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.username],
                              decoration: const InputDecoration(
                                labelText: 'Username',
                                prefixIcon: Icon(Icons.person_outline_rounded),
                              ),
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                  ? 'Enter your username.'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.password],
                              onFieldSubmitted: (_) => _login(),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                ),
                                suffixIcon: IconButton(
                                  tooltip: _obscurePassword
                                      ? 'Show password'
                                      : 'Hide password',
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? 'Enter your password.'
                                  : null,
                            ),
                            const SizedBox(height: 8),
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              title: const Text('Remember me'),
                              value: _rememberMe,
                              onChanged: (value) =>
                                  setState(() => _rememberMe = value ?? false),
                            ),
                            if (_error != null)
                              _MessageBanner(message: _error!, isError: true),
                            if (_notice != null)
                              _MessageBanner(message: _notice!, isError: false),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: _loading ? null : _login,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                child: _loading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Sign in'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextButton(
                    onPressed: _openRegistration,
                    child: const Text('New to PocketTrack? Create an account'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageBanner extends StatelessWidget {
  const _MessageBanner({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? const Color(0xFFB3261E) : const Color(0xFF138A5B);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(message, style: TextStyle(color: color)),
    );
  }
}
