import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../services/audio_service.dart';
import '../services/economy_service.dart';
import '../services/mascota_service.dart';
import '../services/preferencias_service.dart';
import '../theme/app_colors.dart';
import 'juegos_hub_screen.dart';
import 'nivel_juegos_screen.dart';
import 'rescate_mascota_screen.dart';
import 'widgets/oca_comiendo_sprite.dart';
import 'widgets/oca_face.dart';

/// Pantalla de la Oca-mascota: darle de comer, jugar con ella, dejarla
/// dormir, y ver sus tres barras. Nunca bloquea nada del resto del juego —
/// es una invitación a volver, no una obligación.
class MascotaScreen extends StatefulWidget {
  final Usuario usuario;
  final String edadBracket;
  final String pais;
  const MascotaScreen({super.key, required this.usuario, required this.edadBracket, required this.pais});

  @override
  State<MascotaScreen> createState() => _MascotaScreenState();
}

class _MascotaScreenState extends State<MascotaScreen> {
  EstadoMascota? _estado;
  int _monedas = 0;
  bool _ocupado = false;
  bool _mostrandoComer = false;

  @override
  void initState() {
    super.initState();
    _monedas = widget.usuario.monedas;
    _cargar();
  }

  Future<void> _cargar() async {
    final e = await MascotaService.obtenerEstado(usuarioId: widget.usuario.id);
    if (mounted) setState(() => _estado = e);
  }

  Future<void> _alimentar() async {
    final e = _estado;
    if (e == null || _ocupado || e.hambre >= 100) return;
    setState(() => _ocupado = true);
    final r = await EconomyService.gastarMonedas(widget.usuario.id, 10);
    if (r == null || !r.exito) {
      if (mounted) {
        setState(() => _ocupado = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Te faltan monedas para darle de comer (necesitás 10 🪙).')));
      }
      return;
    }
    final nuevo = await MascotaService.alimentar(usuarioId: widget.usuario.id);
    if (!mounted) return;
    AudioService.carino();
    setState(() {
      _estado = nuevo;
      _monedas = r.monedasRestantes;
      _ocupado = false;
      _mostrandoComer = true;
    });
  }

  void _terminarAnimacionComer() {
    if (mounted) setState(() => _mostrandoComer = false);
  }

  Future<void> _alternarDormir() async {
    final e = _estado;
    if (e == null || _ocupado) return;
    setState(() => _ocupado = true);
    final nuevo = await MascotaService.alternarDormir(usuarioId: widget.usuario.id, durmiendo: !e.durmiendo);
    if (!mounted) return;
    if (!nuevo.durmiendo) AudioService.carino();
    setState(() {
      _estado = nuevo;
      _ocupado = false;
    });
  }

  Future<void> _jugarConElla() async {
    if (_ocupado) return;
    var nivel = await PreferenciasService.obtenerNivelJuegos();
    if (nivel == null) {
      if (!mounted) return;
      final elegido = await Navigator.of(context).push<String>(MaterialPageRoute(builder: (_) => const NivelJuegosScreen()));
      if (elegido == null) return;
      await PreferenciasService.guardarNivelJuegos(elegido);
      nivel = elegido;
    }
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => JuegosHubScreen(usuarioId: widget.usuario.id, nivel: nivel!),
    ));
    _cargar();
  }

  Future<void> _irABuscarla() async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => RescateMascotaScreen(usuario: widget.usuario, edadBracket: widget.edadBracket, pais: widget.pais),
    ));
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    final e = _estado;
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, foregroundColor: Colors.white, title: const Text('🪿 Tu Oca')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: AppColors.heroGradient),
        ),
        child: SafeArea(
          child: e == null
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: e.secuestrada ? _contenidoSecuestrada() : _contenidoNormal(e),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _contenidoSecuestrada() {
    return Column(
      children: [
        const Text('🏹', style: TextStyle(fontSize: 96)),
        const SizedBox(height: 8),
        const Text(
          'El cazador se la llevó porque la extrañaste mucho tiempo.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text('No es un castigo: cuando quieras, jugá un desafío de Cuestionados y la traés de vuelta.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: Colors.white.withValues(alpha: 0.85))),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.coral, foregroundColor: Colors.white),
            onPressed: _irABuscarla,
            child: const Text('🏹 Ir a buscarla'),
          ),
        ),
      ],
    );
  }

  String _mensaje(EstadoMascota e) {
    if (_mostrandoComer) return '¡Ñam, ñam! Gracias por la comida 🌾';
    if (e.durmiendo) return 'Zzz... está durmiendo la siesta.';
    if (e.hambre < 30) return 'Tiene hambre... ¿le das de comer?';
    if (e.diversion < 30) return 'Está un poco aburrida, ¿jugamos con ella?';
    if (e.sueno < 30) return 'Tiene sueño... capaz quiere dormir un rato.';
    return '¡Hola! ¿Cómo estás hoy?';
  }

  Widget _contenidoNormal(EstadoMascota e) {
    return Column(
      children: [
        if (_mostrandoComer)
          OcaComiendoSprite(onTerminado: _terminarAnimacionComer, size: 150)
        else
          OcaFace(estado: e, size: 150),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Text(
            _mensaje(e),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.violetDark),
          ),
        ),
        const SizedBox(height: 24),
        if (!e.durmiendo) ...[
          _BarraNecesidad(emoji: '🍽️', label: 'Hambre', valor: e.hambre),
          const SizedBox(height: 12),
          _BarraNecesidad(emoji: '💤', label: 'Sueño', valor: e.sueno),
          const SizedBox(height: 12),
          _BarraNecesidad(emoji: '🎾', label: 'Diversión', valor: e.diversion),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: AppColors.violetDark),
              onPressed: (_ocupado || e.hambre >= 100) ? null : _alimentar,
              child: Text(e.hambre >= 100 ? 'Ya no tiene hambre 🍽️' : 'Darle de comer (10 🪙)'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.turquoise, foregroundColor: Colors.white),
              onPressed: _ocupado ? null : _jugarConElla,
              child: Text(e.diversion >= 100 ? 'Ya está súper contenta 🎾' : 'Jugar con ella 🎾'),
            ),
          ),
          const SizedBox(height: 10),
        ] else
          const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.indigo, foregroundColor: Colors.white),
            onPressed: _ocupado ? null : _alternarDormir,
            child: Text(e.durmiendo ? '☀️ Despertarla' : 'Dejarla dormir un rato 💤'),
          ),
        ),
        const SizedBox(height: 16),
        Text('Tenés $_monedas 🪙', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(
          'Jugar cualquier partida también la pone contenta. Si la dejás dormir un rato recupera el sueño.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8)),
        ),
      ],
    );
  }
}

class _BarraNecesidad extends StatelessWidget {
  final String emoji;
  final String label;
  final double valor;
  const _BarraNecesidad({required this.emoji, required this.label, required this.valor});

  Color get _color {
    if (valor >= 60) return AppColors.green;
    if (valor >= 30) return AppColors.gold;
    return AppColors.coral;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        SizedBox(width: 78, child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: valor / 100,
              minHeight: 14,
              backgroundColor: Colors.white,
              valueColor: AlwaysStoppedAnimation(_color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(width: 36, child: Text('${valor.round()}%', style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
      ],
    );
  }
}
