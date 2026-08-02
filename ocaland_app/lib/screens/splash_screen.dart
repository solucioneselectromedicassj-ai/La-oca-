import 'package:flutter/material.dart';

import '../models/usuario.dart';
import '../services/session_service.dart';
import '../services/supabase_service.dart';
import '../theme/ocaland_theme.dart';
import 'home_screen.dart';
import 'name_entry_screen.dart';

/// Pantalla de arranque: intenta reconocer al usuario por este dispositivo
/// ("¡Hola de nuevo, Pablo!") antes de mostrar el menú principal.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final SessionService _sessionService;
  String? _error;

  @override
  void initState() {
    super.initState();
    _sessionService = SessionService(SupabaseService.instance);
    _restaurarSesion();
  }

  Future<void> _restaurarSesion() async {
    try {
      final Usuario? usuario = await _sessionService.restaurarSesion();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => usuario != null
              ? HomeScreen(usuario: usuario)
              : NameEntryScreen(sessionService: _sessionService),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OcalandColors.violeta,
      body: Center(
        child: _error != null
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'No pudimos conectar con Ocaland.\n$_error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() => _error = null);
                        _restaurarSesion();
                      },
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              )
            : const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ocaland',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 24),
                  CircularProgressIndicator(color: Colors.white),
                ],
              ),
      ),
    );
  }
}
