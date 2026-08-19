import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../services/identity_service.dart';
import '../services/preferencias_service.dart';
import '../theme/app_colors.dart';
import 'edad_screen.dart';
import 'lobby_screen.dart';
import 'pais_screen.dart';

class NicknameScreen extends StatefulWidget {
  const NicknameScreen({super.key});

  @override
  State<NicknameScreen> createState() => _NicknameScreenState();
}

class _NicknameScreenState extends State<NicknameScreen> {
  final _nombreCtrl = TextEditingController();
  final _referidoCtrl = TextEditingController();
  bool _cargando = false;

  Future<void> _continuar() async {
    final nombre = _nombreCtrl.text.trim();
    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Escribí un nombre.')));
      return;
    }
    setState(() => _cargando = true);
    try {
      final usuario = await IdentityService.crearUsuario(nombre, codigoReferido: _referidoCtrl.text);
      if (!mounted) return;
      // Importante: push (no pushReplacement) — _irAPais y el onSelected de
      // PaisScreen reutilizan este `context` más adelante; si esta pantalla
      // se reemplazara, ese context quedaría desmontado y el Navigator.of(context)
      // posterior explota con un null check en tiempo de ejecución.
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => EdadScreen(onSelected: (bracket) {
          PreferenciasService.guardarEdad(bracket);
          _irAPais(context, usuario, nombre, bracket);
        })),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No pudimos conectar con el servidor. Probá de nuevo.')));
    }
  }

  void _irAPais(BuildContext context, Usuario usuario, String nombre, String edadBracket) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaisScreen(
          onSelected: (pais) {
            PreferenciasService.guardarPais(pais);
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => LobbyScreen(usuario: usuario, nombre: nombre, edadBracket: edadBracket, pais: pais)),
              (route) => false,
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.parchment,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Ocaland', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: AppColors.violetDark)),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text('Ingresá tu nombre para identificarte en la sala.'),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _nombreCtrl,
                            maxLength: 20,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(hintText: 'Tu nombre', counterText: ''),
                          ),
                          TextField(
                            controller: _referidoCtrl,
                            maxLength: 5,
                            textAlign: TextAlign.center,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(hintText: '¿Alguien te invitó? Código (opcional)', counterText: ''),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _cargando ? null : _continuar,
                              child: _cargando
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('Continuar'),
                            ),
                          ),
                        ],
                      ),
                    ),
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
