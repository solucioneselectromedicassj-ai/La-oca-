import 'package:flutter/material.dart';
import '../services/mascota_service.dart';
import '../services/preferencias_service.dart';
import '../theme/app_colors.dart';

/// Palabras cortas (para menores/adolescentes) y más largas (para
/// adultos), varias con temática del propio juego para que se sienta
/// parte de Ocaland y no un agregado genérico.
const _palabrasCortas = ['OCA', 'DADO', 'JUEGO', 'AMIGO', 'CASA', 'SOL', 'GATO', 'PATO', 'LUNA', 'PAN'];
const _palabrasLargas = ['CAZADOR', 'TABLERO', 'CUESTIONADO', 'CAMPANA', 'MASCOTA', 'RULETA', 'DESAFIO', 'AVENTURA', 'SORPRESA', 'MONEDAS'];

const _maxFallos = 6;
const _abecedario = 'ABCDEFGHIJKLMNÑOPQRSTUVWXYZ';

/// Ahorcado clásico: adiviná la palabra letra por letra antes de agotar
/// los intentos. Parte de la Zona de juegos nueva de "Jugar con ella".
class AhorcadoScreen extends StatefulWidget {
  final String usuarioId;
  final String nivel; // 'menor' | 'adolescente' | 'adulto'
  const AhorcadoScreen({super.key, required this.usuarioId, required this.nivel});

  @override
  State<AhorcadoScreen> createState() => _AhorcadoScreenState();
}

class _AhorcadoScreenState extends State<AhorcadoScreen> {
  String _palabra = '';
  final Set<String> _adivinadas = {};
  final Set<String> _falladas = {};
  bool _premiado = false;
  bool _cargando = true;

  /// Cola de palabras ya barajadas: se van sacando de a una para no
  /// repetir hasta agotar todo el banco (mismo patrón que la tanda de
  /// cuestionados) — antes podía tocar la misma palabra dos veces
  /// seguidas por pura casualidad del sorteo.
  final List<String> _cola = [];

  @override
  void initState() {
    super.initState();
    _cargarEstado();
  }

  Future<void> _cargarEstado() async {
    final g = await PreferenciasService.obtenerEstadoJuego('ahorcado');
    if (g != null && g['palabra'] != null) {
      _palabra = g['palabra'] as String;
      _adivinadas.addAll((g['adivinadas'] as List).map((v) => v as String));
      _falladas.addAll((g['falladas'] as List).map((v) => v as String));
      _cola.addAll((g['cola'] as List).map((v) => v as String));
    } else {
      _elegirPalabra();
    }
    if (mounted) setState(() => _cargando = false);
  }

  Future<void> _guardarEstado() {
    return PreferenciasService.guardarEstadoJuego('ahorcado', {
      'palabra': _palabra,
      'adivinadas': _adivinadas.toList(),
      'falladas': _falladas.toList(),
      'cola': _cola,
    });
  }

  void _elegirPalabra() {
    if (_cola.isEmpty) {
      final banco = widget.nivel == 'adulto' ? _palabrasLargas : _palabrasCortas;
      _cola.addAll(List<String>.from(banco)..shuffle());
    }
    _palabra = _cola.removeAt(0);
  }

  bool get _gano => _palabra.split('').every(_adivinadas.contains);
  bool get _perdio => _falladas.length >= _maxFallos;

  void _elegirLetra(String letra) {
    if (_gano || _perdio || _adivinadas.contains(letra) || _falladas.contains(letra)) return;
    setState(() {
      if (_palabra.contains(letra)) {
        _adivinadas.add(letra);
      } else {
        _falladas.add(letra);
      }
    });
    _guardarEstado();
    if (_gano) _premiar();
  }

  Future<void> _premiar() async {
    if (_premiado) return;
    _premiado = true;
    await MascotaService.registrarJuego(usuarioId: widget.usuarioId, suba: 20);
  }

  void _reiniciar() {
    setState(() {
      _adivinadas.clear();
      _falladas.clear();
      _premiado = false;
      _elegirPalabra();
    });
    _guardarEstado();
  }

  @override
  Widget build(BuildContext context) {
    final fin = _gano || _perdio;
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, foregroundColor: Colors.white, title: const Text('🔤 Ahorcado')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: AppColors.heroGradient),
        ),
        child: SafeArea(
          child: _cargando
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🪿 Fallos: ${_falladas.length} / $_maxFallos', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.violetDark)),
                      const SizedBox(height: 12),
                      // Siempre en un solo renglón (las casillas se achican
                      // si la palabra es larga) — antes una palabra larga
                      // se cortaba en dos filas y parecía que eran dos
                      // palabras distintas.
                      LayoutBuilder(builder: (context, constraints) {
                        const espaciado = 6.0;
                        final n = _palabra.length;
                        final anchoIdeal = (30.0 * n + espaciado * (n - 1)) <= constraints.maxWidth
                            ? 30.0
                            : (constraints.maxWidth - espaciado * (n - 1)) / n;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var i = 0; i < n; i++) ...[
                              if (i > 0) const SizedBox(width: espaciado),
                              Container(
                                width: anchoIdeal,
                                height: 38,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.violetDark, width: 2))),
                                child: Text(
                                  (_adivinadas.contains(_palabra[i]) || fin) ? _palabra[i] : '',
                                  style: TextStyle(fontSize: anchoIdeal < 24 ? 15 : 22, fontWeight: FontWeight.bold, color: AppColors.violetDark),
                                ),
                              ),
                            ],
                          ],
                        );
                      }),
                      const SizedBox(height: 18),
                      if (!fin)
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final letra in _abecedario.split(''))
                              _TeclaLetra(
                                letra: letra,
                                usada: _adivinadas.contains(letra) || _falladas.contains(letra),
                                correcta: _adivinadas.contains(letra),
                                onTap: () => _elegirLetra(letra),
                              ),
                          ],
                        ),
                      if (fin) ...[
                        Text(
                          _gano ? '🎉 ¡La adivinaste!' : '😕 Esta vez no. Era "$_palabra".',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.violetDark),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _reiniciar, child: const Text('🔁 Otra palabra'))),
                      ],
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
}

class _TeclaLetra extends StatelessWidget {
  final String letra;
  final bool usada;
  final bool correcta;
  final VoidCallback onTap;
  const _TeclaLetra({required this.letra, required this.usada, required this.correcta, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = !usada ? AppColors.violet : (correcta ? AppColors.green : AppColors.coral);
    return SizedBox(
      width: 34,
      height: 34,
      child: Material(
        color: usada ? color.withValues(alpha: 0.35) : color,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: usada ? null : onTap,
          child: Center(child: Text(letra, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ),
      ),
    );
  }
}
