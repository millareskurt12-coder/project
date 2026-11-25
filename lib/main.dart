import 'package:flutter/material.dart';

import 'database/database_helper.dart';
import 'services/auth_service.dart';
import 'models/user_model.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'services/session_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PocketTrackApp());
}

class PocketTrackApp extends StatefulWidget {
  const PocketTrackApp({super.key, this.database});

  final DatabaseHelper? database;

  @override
  State<PocketTrackApp> createState() => _PocketTrackAppState();
}

class _PocketTrackAppState extends State<PocketTrackApp> {
  bool _starting = true;
  UserModel? _user;

  DatabaseHelper get _database => widget.database ?? DatabaseHelper.instance;

  Future<void> _signIn(UserModel user, bool rememberMe) async {
    final sessions = SessionService(database: _database);
    if (rememberMe) {
      await sessions.rememberUser(user);
    } else {
      await sessions.clearSession();
    }
    if (mounted) setState(() => _user = user);
  }

  Future<void> _signOut() async {
    await SessionService(database: _database).clearSession();
    if (mounted) setState(() => _user = null);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF138A5B),
      brightness: Brightness.light,
      surface: const Color(0xFFF5F8F6),
    );
    return MaterialApp(
      title: 'PocketTrack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF5F8F6),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF5F8F6),
          foregroundColor: Color(0xFF101D2D),
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFFE9EFEC)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF8FAF9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFDCE5E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFDCE5E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF138A5B), width: 1.5),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF138A5B),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
      home: _starting
          ? SplashScreen(
              sessions: SessionService(database: _database),
              onFinished: (user) {
                if (mounted) {
                  setState(() {
                    _user = user;
                    _starting = false;
                  });
                }
              },
            )
          : _user == null
          ? LoginScreen(
              authService: AuthService(database: _database),
              onLogin: _signIn,
            )
          : DashboardScreen(
              user: _user!,
              onLogout: _signOut,
              database: _database,
            ),
    );
  }
}
