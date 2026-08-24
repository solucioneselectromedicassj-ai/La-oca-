import 'package:flutter/material.dart';
import '../services/mascota_service.dart';
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
  late String _palabra;
  final Set<String> _adivinadas = {};
  final Set<String> _falladas = {};
  bool _premiado = false;

  @override
  void initState() {
    super.initState();
    _elegirPalabra();
  }

  void _elegirPalabra() {
    final banco = widget.nivel == 'adulto' ? _palabrasLargas : _palabrasCortas;
    _palabra = (List<String>.from(banco)..shuffle()).first;
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
          child: Center(
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
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        children: [
                          for (final letra in _palabra.split(''))
                            Container(
                              width: 30,
                              height: 38,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.violetDark, width: 2))),
                              child: Text(
                                (_adivinadas.contains(letra) || fin) ? letra : '',
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.violetDark),
                              ),
                            ),
                        ],
                      ),
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
