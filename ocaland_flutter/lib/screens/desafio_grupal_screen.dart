import 'dart:math';
import 'package:flutter/material.dart';
import '../models/amigo.dart';
import '../models/desafio_resultado.dart';
import '../models/grupo.dart';
import '../models/usuario.dart';
import '../services/amigos_service.dart';
import '../services/grupos_service.dart';
import '../services/mensajes_service.dart';
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

  /// Si se abre desde una invitación del buzón, ya viene con el código
  /// puesto y se une automáticamente sin tener que tipearlo.
  final String? codigoInicial;

  const DesafioGrupalScreen({super.key, required this.usuario, required this.nombre, required this.edadBracket, required this.pais, this.codigoInicial});

  @override
  State<DesafioGrupalScreen> createState() => _DesafioGrupalScreenState();
}

class _DesafioGrupalScreenState extends State<DesafioGrupalScreen> {
  final _codeCtrl = TextEditingController();
  String? _desafioId;
  String? _desafioCodigo;
  List<DesafioResultado>? _resultados;
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    if (widget.codigoInicial != null) {
      _codeCtrl.text = widget.codigoInicial!;
      WidgetsBinding.instance.addPostFrameCallback((_) => _unirseDesafio());
    }
  }

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

  Future<void> _invitarAmigos() async {
    final codigo = _desafioCodigo;
    if (codigo == null) return;
    final amigos = await AmigosService.listar(widget.usuario.id);
    final grupos = await GruposService.listar(widget.usuario.id);
    if (!mounted) return;
    if (amigos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Todavía no tenés amigos agregados. Andá a "Mis amigos" para sumar alguno.')));
      return;
    }
    final elegidos = await showModalBottomSheet<Set<String>>(
      context: context,
      backgroundColor: AppColors.parchment,
      isScrollControlled: true,
      builder: (sheetContext) => _SelectorInvitados(amigos: amigos, grupos: grupos),
    );
    if (elegidos == null || elegidos.isEmpty || !mounted) return;
    var enviados = 0;
    for (final a in amigos.where((a) => elegidos.contains(a.amigoUsuarioId))) {
      try {
        await MensajesService.enviarInvitacion(
          destinatarioUsuarioId: a.amigoUsuarioId,
          remitenteUsuarioId: widget.usuario.id,
          remitenteNombre: widget.nombre,
          texto: '🎯 ${widget.nombre} te invitó a un desafío grupal. ¡Jugá tu campaña y competí por el ranking!',
          payload: {'desafio_codigo': codigo},
        );
        enviados++;
      } catch (_) {}
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(enviados > 0 ? 'Invitación enviada a $enviados amigo${enviados == 1 ? '' : 's'}.' : 'No se pudo enviar la invitación.')));
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
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, foregroundColor: Colors.white, title: const Text('🎯 Desafío grupal')),
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
                            const SizedBox(height: 8),
                            SizedBox(width: double.infinity, child: OutlinedButton(onPressed: _invitarAmigos, child: const Text('📬 Invitar amigos'))),
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

/// Selector de a quién invitar: amigos sueltos + grupos enteros (que
/// simplemente marcan a todos sus miembros). Devuelve el set de
/// `amigo_usuario_id` elegidos.
class _SelectorInvitados extends StatefulWidget {
  final List<Amigo> amigos;
  final List<Grupo> grupos;
  const _SelectorInvitados({required this.amigos, required this.grupos});

  @override
  State<_SelectorInvitados> createState() => _SelectorInvitadosState();
}

class _SelectorInvitadosState extends State<_SelectorInvitados> {
  final Set<String> _elegidos = {};
  final Map<String, List<GrupoMiembro>> _miembrosPorGrupo = {};

  Future<void> _tocarGrupo(Grupo g) async {
    var miembros = _miembrosPorGrupo[g.id];
    if (miembros == null) {
      miembros = await GruposService.miembros(g.id);
      if (!mounted) return;
      _miembrosPorGrupo[g.id] = miembros;
    }
    final ids = miembros.map((m) => m.amigoUsuarioId);
    final todosAdentro = ids.every(_elegidos.contains);
    setState(() {
      if (todosAdentro) {
        _elegidos.removeAll(ids);
      } else {
        _elegidos.addAll(ids);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('¿A quién invitás?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.violetDark)),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    if (widget.grupos.isNotEmpty) ...[
                      const Text('Grupos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF9B8AB5))),
                      for (final g in widget.grupos)
                        ListTile(
                          leading: const Text('👨‍👩‍👧‍👦', style: TextStyle(fontSize: 20)),
                          title: Text(g.nombre),
                          trailing: const Icon(Icons.group_add),
                          onTap: () => _tocarGrupo(g),
                        ),
                      const Divider(),
                    ],
                    const Text('Amigos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF9B8AB5))),
                    for (final a in widget.amigos)
                      CheckboxListTile(
                        value: _elegidos.contains(a.amigoUsuarioId),
                        title: Text(a.apodo),
                        onChanged: (v) => setState(() => v == true ? _elegidos.add(a.amigoUsuarioId) : _elegidos.remove(a.amigoUsuarioId)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _elegidos.isEmpty ? null : () => Navigator.of(context).pop(_elegidos),
                child: Text(_elegidos.isEmpty ? 'Elegí al menos uno' : 'Invitar (${_elegidos.length})'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
