import 'package:flutter/material.dart';

import '../services/session_service.dart';
import 'home_screen.dart';

/// Primera vez que se abre la app en este dispositivo: pide el nombre para
/// crear el usuario en `la_vuelta.usuarios`.
class NameEntryScreen extends StatefulWidget {
  const NameEntryScreen({super.key, required this.sessionService});

  final SessionService sessionService;

  @override
  State<NameEntryScreen> createState() => _NameEntryScreenState();
}

class _NameEntryScreenState extends State<NameEntryScreen> {
  final _controller = TextEditingController();
  bool _guardando = false;
  String? _error;

  Future<void> _continuar() async {
    final nombre = _controller.text.trim();
    if (nombre.isEmpty) {
      setState(() => _error = 'Escribí un nombre para seguir.');
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final usuario =
          await widget.sessionService.crearUsuarioEnEsteDispositivo(nombre);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomeScreen(usuario: usuario)),
      );
    } catch (e) {
      setState(() {
        _error = 'No se pudo crear el usuario: $e';
        _guardando = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '¡Bienvenido a Ocaland! 🪿',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                const Text(
                  '¿Cómo te llamás?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _controller,
                  textAlign: TextAlign.center,
                  maxLength: 20,
                  decoration: const InputDecoration(
                    hintText: 'Tu nombre',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _continuar(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _guardando ? null : _continuar,
                  child: _guardando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Empezar a jugar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
