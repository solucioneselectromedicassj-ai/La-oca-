import 'package:flutter/material.dart';
import '../models/jugador.dart';
import '../models/usuario.dart';
import '../services/join_room_result.dart';
import '../services/sala_game_controller.dart';
import '../theme/app_colors.dart';
import 'game_screen_multi.dart';
import 'waiting_room_screen.dart';

class JoinSalaScreen extends StatefulWidget {
  final Usuario usuario;
  final String nombre;
  final String edadBracket;
  final String pais;

  const JoinSalaScreen({super.key, required this.usuario, required this.nombre, required this.edadBracket, required this.pais});

  @override
  State<JoinSalaScreen> createState() => _JoinSalaScreenState();
}

class _JoinSalaScreenState extends State<JoinSalaScreen> {
  final _codeCtrl = TextEditingController();
  bool _cargando = false;
  SalaGameController? _controllerPendienteReconexion;
  List<JugadorPartida> _paraReconectar = const [];

  SalaGameController _nuevoController() => SalaGameController(
        usuario: widget.usuario,
        myNombre: widget.nombre,
        myEdadBracket: widget.edadBracket,
        myPais: widget.pais,
      );

  Future<void> _unirse() async {
    final code = _codeCtrl.text.trim();
    if (code.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El código tiene 4 caracteres.')));
      return;
    }
    setState(() => _cargando = true);
    final controller = _nuevoController();
    try {
      final result = await controller.unirseSala(code);
      if (!mounted) return;
      switch (result.outcome) {
        case JoinOutcome.ok:
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => WaitingRoomScreen(controller: controller)));
          break;
        case JoinOutcome.salaLlena:
          setState(() => _cargando = false);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La sala está llena.')));
          break;
        case JoinOutcome.noExiste:
          setState(() => _cargando = false);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se encontró esa sala.')));
          break;
        case JoinOutcome.reconectar:
          setState(() {
            _cargando = false;
            _controllerPendienteReconexion = controller;
            _paraReconectar = result.jugadoresParaReconectar;
          });
          break;
        case JoinOutcome.error:
          setState(() => _cargando = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.errorMsg ?? 'Ocurrió un error.')));
          break;
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No pudimos conectar con el servidor.')));
    }
  }

  Future<void> _reconectarComo(JugadorPartida jugador) async {
    final controller = _controllerPendienteReconexion!;
    setState(() => _cargando = true);
    await controller.reconectarComo(controller.partida!, jugador);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => GameScreenMulti(controller: controller)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.parchment,
      appBar: AppBar(backgroundColor: AppColors.parchment, elevation: 0, foregroundColor: AppColors.violetDark, title: const Text('Unirme a una sala')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _paraReconectar.isNotEmpty ? _reconectarUI() : _codigoUI(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _codigoUI() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('¿Ya tenés un código?'),
            const SizedBox(height: 10),
            TextField(
              controller: _codeCtrl,
              maxLength: 4,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(hintText: 'CÓDIGO', counterText: ''),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _cargando ? null : _unirse,
                child: _cargando ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Unirme'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reconectarUI() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔌 Esta partida ya está en curso. ¿Cuál de estos jugadores sos vos?'),
            const SizedBox(height: 10),
            for (final j in _paraReconectar)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(width: double.infinity, child: OutlinedButton(onPressed: _cargando ? null : () => _reconectarComo(j), child: Text(j.nombre))),
              ),
          ],
        ),
      ),
    );
  }
}
