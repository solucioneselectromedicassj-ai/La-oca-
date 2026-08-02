import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/usuario.dart';
import '../services/supabase_service.dart';
import '../theme/app_colors.dart';

class PerfilScreen extends StatefulWidget {
  final Usuario usuario;
  const PerfilScreen({super.key, required this.usuario});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  Usuario? _usuario;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final row = await SupabaseService.from('usuarios').select().eq('id', widget.usuario.id).single();
      if (mounted) setState(() { _usuario = Usuario.fromJson(row); _cargando = false; });
    } catch (_) {
      if (mounted) setState(() { _usuario = widget.usuario; _cargando = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = _usuario ?? widget.usuario;
    final winRate = u.partidasJugadas > 0 ? ((u.partidasGanadas / u.partidasJugadas) * 100).round() : 0;
    final mejorTiempo = u.mejorTiempoCampanaMs != null ? _formatearMs(u.mejorTiempoCampanaMs!) : '—';
    final multiplicadorActivo = u.multiplicadorVenceTs != null && u.multiplicadorVenceTs!.isAfter(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.parchment,
      appBar: AppBar(backgroundColor: AppColors.parchment, elevation: 0, foregroundColor: AppColors.violetDark, title: const Text('Mi perfil')),
      body: SafeArea(
        child: _cargando
            ? const Center(child: CircularProgressIndicator(color: AppColors.violetDark))
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('📊 ${u.nombre}', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: AppColors.violetDark)),
                            const SizedBox(height: 8),
                            _fila('🪙 Monedas', '${u.monedas}'),
                            if (multiplicadorActivo) _fila('⚡ Multiplicador activo', 'x${u.multiplicadorValor}'),
                            _fila('🔥 Racha', '${u.rachaDias} día${u.rachaDias == 1 ? '' : 's'} seguidos'),
                            _fila('🎲 Partidas jugadas', '${u.partidasJugadas}'),
                            _fila('🏆 Partidas ganadas', '${u.partidasGanadas} ($winRate%)'),
                            _fila('🏁 Campañas completadas', '${u.campanasCompletadas}'),
                            _fila('⏱️ Mejor tiempo de campaña', mejorTiempo),
                            _fila('👥 Amigos invitados', '${u.amigosInvitados}'),
                            const SizedBox(height: 6),
                            Text('Tu código para invitar: ${u.codigoReferido ?? '—'} (+20 🪙 por cada amigo que lo use)', style: const TextStyle(fontSize: 12)),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () => Share.share('🎲 ¡Jugá Ocaland conmigo! Usá mi código ${u.codigoReferido} al entrar.'),
                                child: const Text('📲 Compartir mi código'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _fila(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label), Text(valor, style: const TextStyle(fontWeight: FontWeight.bold))]),
    );
  }

  String _formatearMs(int ms) {
    final totalSeg = (ms / 1000).round();
    final min = totalSeg ~/ 60;
    final seg = totalSeg % 60;
    return min > 0 ? '${min}m ${seg}s' : '${seg}s';
  }
}
