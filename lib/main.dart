import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:forui/theme.dart';
import 'package:ivo/data/notifiers.dart';
import 'package:ivo/services/auth/auth_gate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/dark_theme.dart';
import 'theme/light_theme.dart';

void main() async {
  // supabase setup
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  final supabaseUrl = dotenv.env['SUPABASE_URL']!;
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY']!;
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  print('Initializing database...');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Wrap with ValueListenableBuilder to listen for theme changes
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkThemeNotifier,
      builder: (context, isDark, _) {
        // Select theme based on isDark value
        final theme = isDark ? blueDark : blueLight;

        return ValueListenableBuilder<String>(
          valueListenable: languageNotifier,
          builder:
              (_, __, ___) => MaterialApp(
                debugShowCheckedModeBanner: false,
                builder:
                    (_, child) => FAnimatedTheme(data: theme, child: child!),
                home: const AuthGate(),
                theme: theme.toApproximateMaterialTheme(),
              ),
        );
      },
    );
  }
}
