import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';
import 'services/supabase_service.dart';
import 'theme/ocaland_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.init();
  runApp(const OcalandApp());
}

class OcalandApp extends StatelessWidget {
  const OcalandApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ocaland',
      debugShowCheckedModeBanner: false,
      theme: OcalandTheme.light,
      home: const SplashScreen(),
    );
  }
}
