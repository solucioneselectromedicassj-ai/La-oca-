import 'dart:math';
import 'package:flutter/material.dart';
import '../models/desafio_resultado.dart';
import '../models/usuario.dart';
import '../services/solo_game_controller.dart';
import '../services/supabase_service.dart';
import '../theme/app_colors.dart';
import '../utils/format.dart';
import 'game_screen_solo.dart';

/// Desafío grupal: cada persona juega su propia campaña de 10 etapas
/// cuando quiera (no hace falta estar todos conectados a la vez), atada a
/// un código de desafío compartido. Al completarla, el resultado se
/// compara en un ranking del desafío.
class DesafioGrupalScreen extends StatefulWidget {
  final Usuario usuario;
  final String nombre;
  final String edadBracket;
  final String pais;

  const DesafioGrupalScreen({super.key, required this.usuario, required this.nombre, required this.edadBracket, required this.pais});

  @override
  State<DesafioGrupalScreen> createState() => _DesafioGrupalScreenState();
}

class _DesafioGrupalScreenState extends State<DesafioGrupalScreen> {
  final _codeCtrl = TextEditingController();
  String? _desafioId;
  String? _desafioCodigo;
  List<DesafioResultado>? _resultados;
  bool _cargando = false;

  String _genCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random();
    return List.generate(4, (_) => chars[rnd.nextInt(chars.length)]).join();
  }

  Future<void> _crearDesafio() async {
    setState(() => _cargando = true);
    Map<String, dynamic>? row;
    for (var i = 0; i < 5 && row == null; i++) {
      try {
        row = await SupabaseService.from('desafios_grupales').insert({'codigo': _genCode()}).select().single();
      } catch (_) {}
    }
    if (!mounted) return;
    if (row == null) {
      setState(() => _cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo crear el desafío.')));
      return;
    }
    setState(() {
      _desafioId = row!['id'] as String;
      _desafioCodigo = row['codigo'] as String;
      _cargando = false;
    });
    await _cargarRanking();
  }

  Future<void> _unirseDesafio() async {
    final codigo = _codeCtrl.text.trim().toUpperCase();
    if (codigo.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El código tiene 4 caracteres.')));
      return;
    }
    setState(() => _cargando = true);
    try {
      final row = await SupabaseService.from('desafios_grupales').select().eq('codigo', codigo).single();
      if (!mounted) return;
      setState(() {
        _desafioId = row['id'] as String;
        _desafioCodigo = row['codigo'] as String;
        _cargando = false;
      });
      await _cargarRanking();
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se encontró ese desafío.')));
    }
  }

  Future<void> _cargarRanking() async {
    if (_desafioId == null) return;
    try {
      final rows = await SupabaseService.from('desafios_resultados').select().eq('desafio_id', _desafioId!).order('etapas_completadas', ascending: false);
      final lista = (rows as List).map((r) => DesafioResultado.fromJson(r as Map<String, dynamic>)).toList()
        ..sort((a, b) => a.etapasCompletadas != b.etapasCompletadas ? b.etapasCompletadas - a.etapasCompletadas : a.msTotal.compareTo(b.msTotal));
      if (mounted) setState(() => _resultados = lista);
    } catch (_) {
      if (mounted) setState(() => _resultados = []);
    }
  }

  void _jugarMiCampana() {
    final controller = SoloGameController(
      usuario: widget.usuario,
      myNombre: widget.nombre,
      myEdadBracket: widget.edadBracket,
      myPais: widget.pais,
      desafioId: _desafioId,
    );
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => GameScreenSolo(controller: controller))).then((_) => _cargarRanking());
  }

  static const _medallas = ['🥇', '🥈', '🥉'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.parchment,
      appBar: AppBar(backgroundColor: AppColors.parchment, elevation: 0, foregroundColor: AppColors.violetDark, title: const Text('🎯 Desafío grupal')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  if (_desafioId == null) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _cargando ? null : _crearDesafio, child: const Text('+ Crear desafío nuevo'))),
                      ),
                    ),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text('¿Tenés un código de desafío?'),
                            const SizedBox(height: 8),
                            TextField(controller: _codeCtrl, maxLength: 4, textAlign: TextAlign.center, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(hintText: 'CÓDIGO', counterText: '')),
                            const SizedBox(height: 8),
                            SizedBox(width: double.infinity, child: OutlinedButton(onPressed: _cargando ? null : _unirseDesafio, child: const Text('Ver / Unirme'))),
                          ],
                        ),
                      ),
                    ),
                  ] else
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text('CÓDIGO DE DESAFÍO', style: TextStyle(fontSize: 12, color: Color(0xFF9B8AB5))),
                            Text(_desafioCodigo ?? '----', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 6, color: AppColors.violetDark)),
                            const SizedBox(height: 10),
                            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _jugarMiCampana, child: const Text('Jugar mi campaña para este desafío'))),
                            const SizedBox(height: 14),
                            _rankingContenido(),
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

  Widget _rankingContenido() {
    final resultados = _resultados;
    if (resultados == null) return const CircularProgressIndicator(color: AppColors.violetDark);
    if (resultados.isEmpty) return const Text('Todavía nadie completó su campaña para este desafío.', style: TextStyle(fontSize: 12.5));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Align(alignment: Alignment.centerLeft, child: Text('Resultados del desafío:', style: TextStyle(fontWeight: FontWeight.bold))),
        for (var i = 0; i < resultados.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${i < 3 ? _medallas[i] : '${i + 1}.'} ${resultados[i].nombre}'),
                Text('${resultados[i].etapasCompletadas}/10 · ${formatearMs(resultados[i].msTotal)}'),
              ],
            ),
          ),
      ],
    );
  }
}
