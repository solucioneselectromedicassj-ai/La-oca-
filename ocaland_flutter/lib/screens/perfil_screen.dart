import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/usuario.dart';
import '../services/audio_service.dart';
import '../services/economy_service.dart';
import '../services/sellos_service.dart';
import '../services/supabase_service.dart';
import '../theme/app_colors.dart';
import 'widgets/anuncio_simulado_overlay.dart';

class PerfilScreen extends StatefulWidget {
  final Usuario usuario;
  const PerfilScreen({super.key, required this.usuario});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  Usuario? _usuario;
  bool _cargando = true;
  int _sellos = 0;

  @override
  void initState() {
    super.initState();
    _cargar();
    SellosService.obtener().then((s) {
      if (mounted) setState(() => _sellos = s);
    });
  }

  Future<void> _cargar() async {
    try {
      final row = await SupabaseService.from('usuarios').select().eq('id', widget.usuario.id).single();
      if (mounted) setState(() { _usuario = Usuario.fromJson(row); _cargando = false; });
    } catch (_) {
      if (mounted) setState(() { _usuario = widget.usuario; _cargando = false; });
    }
  }

  /// Sellos: coleccionable que se puede usar para pedir pistas o reintentar
  /// en Cuestionados. Se consiguen viendo videos, o canjeados acá.
  Future<void> _abrirCanjeSellos() async {
    final u = _usuario ?? widget.usuario;
    final accion = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.parchment,
        title: const Text('🎖️ Mis sellos'),
        content: Text('Tenés $_sellos sello${_sellos == 1 ? '' : 's'}. Los podés usar para pedir pistas o reintentar en Cuestionados.'),
        actions: [
          TextButton(
            onPressed: _sellos >= 5 ? () => Navigator.of(dialogContext).pop('sellos_a_monedas') : null,
            child: const Text('🪙 Cambiar 5 sellos por 15 monedas'),
          ),
          TextButton(
            onPressed: u.monedas >= 15 ? () => Navigator.of(dialogContext).pop('monedas_a_sellos') : null,
            child: const Text('🎖️ Cambiar 15 monedas por 5 sellos'),
          ),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop('video'), child: const Text('📺 Ver un video (+2 sellos gratis)')),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cerrar')),
        ],
      ),
    );
    if (!mounted) return;
    if (accion == 'sellos_a_monedas' && _sellos >= 5) {
      final restantes = await SellosService.agregar(-5);
      final nuevoTotal = await EconomyService.agregarMonedas(widget.usuario.id, 15);
      if (!mounted) return;
      AudioService.coin();
      setState(() {
        _sellos = restantes;
        if (nuevoTotal != null) _usuario = (_usuario ?? widget.usuario).copyWith(monedas: nuevoTotal);
      });
    } else if (accion == 'monedas_a_sellos' && u.monedas >= 15) {
      final r = await EconomyService.gastarMonedas(widget.usuario.id, 15);
      if (!mounted) return;
      if (r == null || !r.exito) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No te alcanzan las monedas.')));
        return;
      }
      final restantes = await SellosService.agregar(5);
      if (!mounted) return;
      AudioService.sello();
      setState(() {
        _sellos = restantes;
        _usuario = (_usuario ?? widget.usuario).copyWith(monedas: r.monedasRestantes);
      });
    } else if (accion == 'video') {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AnuncioSimuladoOverlay(onContinuar: () => Navigator.of(dialogContext).pop()),
      );
      final restantes = await SellosService.agregar(2);
      if (!mounted) return;
      AudioService.sello();
      setState(() => _sellos = restantes);
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
                    child: Column(
                      children: [
                        Card(
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
                        const SizedBox(height: 14),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('🎖️ Mis sellos', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.violetDark)),
                                const SizedBox(height: 4),
                                const Text('Te ayudan a safar en Cuestionados: pedir pistas o reintentar antes de la penitencia.', style: TextStyle(fontSize: 12, color: Color(0xFF7A6A99))),
                                const SizedBox(height: 8),
                                _fila('Sellos acumulados', '$_sellos'),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(onPressed: _abrirCanjeSellos, child: const Text('Canjear sellos')),
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
