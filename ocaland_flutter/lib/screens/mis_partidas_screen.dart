import 'package:flutter/material.dart';
import '../models/sesion_activa.dart';
import '../models/usuario.dart';
import '../services/sala_game_controller.dart';
import '../services/session_service.dart';
import '../services/solo_game_controller.dart';
import '../theme/app_colors.dart';
import 'game_screen_multi.dart';
import 'game_screen_solo.dart';
import 'waiting_room_screen.dart';

class MisPartidasScreen extends StatefulWidget {
  final Usuario usuario;
  const MisPartidasScreen({super.key, required this.usuario});

  @override
  State<MisPartidasScreen> createState() => _MisPartidasScreenState();
}

class _MisPartidasScreenState extends State<MisPartidasScreen> {
  List<SesionActiva>? _sesiones;
  String? _entrando;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final lista = await SessionService.leerLista();
    if (mounted) setState(() => _sesiones = lista);
  }

  Future<void> _entrar(SesionActiva sesion) async {
    setState(() => _entrando = sesion.partidaId);
    if (sesion.esModoSolo) {
      final controller = SoloGameController(usuario: widget.usuario, myNombre: sesion.nombre, myEdadBracket: sesion.edadBracket, myPais: sesion.pais);
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => GameScreenSolo(controller: controller, sesionAReanudar: sesion)));
      return;
    }

    final controller = SalaGameController(usuario: widget.usuario, myNombre: sesion.nombre, myEdadBracket: sesion.edadBracket, myPais: sesion.pais);
    final ok = await controller.reanudarDesdeSesion(sesion);
    if (!mounted) return;
    if (!ok) {
      await SessionService.borrar(sesion.partidaId);
      if (!mounted) return;
      setState(() => _entrando = null);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Esa partida ya no está disponible.')));
      await _cargar();
      return;
    }
    if (controller.partida?.estado == 'esperando') {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => WaitingRoomScreen(controller: controller)));
    } else {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => GameScreenMulti(controller: controller)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.parchment,
      appBar: AppBar(backgroundColor: AppColors.parchment, elevation: 0, foregroundColor: AppColors.violetDark, title: const Text('🎮 Mis partidas')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(padding: const EdgeInsets.all(20), child: _contenido()),
          ),
        ),
      ),
    );
  }

  Widget _contenido() {
    final sesiones = _sesiones;
    if (sesiones == null) return const Center(child: CircularProgressIndicator(color: AppColors.violetDark));
    if (sesiones.isEmpty) return const Text('Todavía no tenés ninguna partida activa.');
    return SingleChildScrollView(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              for (final s in sesiones)
                ListTile(
                  title: Text(s.esModoSolo ? '🤖 Campaña solo' : '👥 Sala ${s.codigo.isEmpty ? "----" : s.codigo}'),
                  trailing: _entrando == s.partidaId
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : OutlinedButton(onPressed: () => _entrar(s), child: const Text('Entrar')),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
