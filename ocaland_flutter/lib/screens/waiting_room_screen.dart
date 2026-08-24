import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../app_config.dart';
import '../services/sala_game_controller.dart';
import '../theme/app_colors.dart';
import 'game_screen_multi.dart';
import 'lobby_screen.dart';

class WaitingRoomScreen extends StatefulWidget {
  final SalaGameController controller;
  const WaitingRoomScreen({super.key, required this.controller});

  @override
  State<WaitingRoomScreen> createState() => _WaitingRoomScreenState();
}

class _WaitingRoomScreenState extends State<WaitingRoomScreen> {
  bool _navegado = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChange);
  }

  void _onChange() {
    if (_navegado) return;
    if (widget.controller.partida?.estado == 'en_curso') {
      _navegado = true;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => GameScreenMulti(controller: widget.controller)));
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    super.dispose();
  }

  Future<void> _salir() async {
    await widget.controller.salir();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LobbyScreen(usuario: widget.controller.usuario, nombre: widget.controller.myNombre, edadBracket: widget.controller.myEdadBracket, pais: widget.controller.myPais)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: AppColors.heroGradient),
        ),
        child: SafeArea(
          child: ListenableBuilder(
            listenable: c,
            builder: (context, _) {
              final codigo = c.partida?.codigo ?? '----';
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        if (c.esCampanaGrupal)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 10),
                            child: Text('🏆 Campaña grupal en vivo (10 etapas)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Text('CÓDIGO DE SALA', style: TextStyle(fontSize: 12, color: Color(0xFF9B8AB5))),
                              Text(codigo, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 6, color: AppColors.violetDark)),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: () => Clipboard.setData(ClipboardData(text: codigo)),
                                  child: const Text('📋 Copiar código'),
                                ),
                              ),
                              const SizedBox(height: 6),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: () => Share.share('🎲 ¡Jugá conmigo a Ocaland! Entrá con el código: $codigo\n${AppConfig.appUrl}'),
                                  child: const Text('📲 Compartir por WhatsApp/chat'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text('Jugadores en la sala (${c.jugadores.length}/${c.partida?.maxJugadores ?? 6}):', style: const TextStyle(fontSize: 13)),
                              const SizedBox(height: 8),
                              for (final j in c.jugadores)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(color: j.id == c.myPlayerId ? AppColors.gold : AppColors.parchmentDark, borderRadius: BorderRadius.circular(8)),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(j.nombre, style: TextStyle(fontWeight: j.id == c.myPlayerId ? FontWeight.bold : FontWeight.normal)),
                                      if (j.id == c.myPlayerId) const Text('(vos)', style: TextStyle(fontSize: 11)),
                                    ],
                                  ),
                                ),
                              if (c.puedoIniciar)
                                SizedBox(width: double.infinity, child: ElevatedButton(onPressed: c.iniciarPartida, child: const Text('Iniciar partida')))
                              else
                                Text(
                                  c.soyHost ? 'Necesitás al menos 2 jugadores para empezar.' : 'Esperando a que el anfitrión inicie la partida...',
                                  style: const TextStyle(fontSize: 13, color: Color(0xFF7A6A99)),
                                ),
                              const SizedBox(height: 8),
                              OutlinedButton(onPressed: _salir, child: const Text('Salir de la sala')),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        ),
      ),
    );
  }
}
