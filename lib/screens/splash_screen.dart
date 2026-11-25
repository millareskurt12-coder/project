import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/session_service.dart';
import '../widgets/app_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onFinished, this.sessions});

  final ValueChanged<UserModel?> onFinished;
  final SessionService? sessions;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  String? _error;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _checkSession();
  }

  Future<void> _checkSession() async {
    setState(() {
      _checking = true;
      _error = null;
    });
    try {
      await Future<void>.delayed(const Duration(milliseconds: 1300));
      final user = await (widget.sessions ?? SessionService())
          .getRememberedUser();
      if (mounted) widget.onFinished(user);
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'Unable to open PocketTrack: $error');
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101D2D),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: Tween<double>(begin: 0.94, end: 1.04).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: Curves.easeInOut,
                  ),
                ),
                child: const AppLogo(size: 106),
              ),
              const SizedBox(height: 24),
              const Text(
                'PocketTrack',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Track Smart. Spend Wisely.',
                style: TextStyle(color: Color(0xFFB6C5D2), fontSize: 15),
              ),
              const SizedBox(height: 38),
              if (_checking)
                const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Color(0xFF48D597),
                  ),
                ),
              if (_error != null) ...[
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFFFB4AB)),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _checkSession,
                  child: const Text('Try again'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
