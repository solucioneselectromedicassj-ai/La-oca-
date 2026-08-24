import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../app_config.dart';
import '../models/amigo.dart';
import '../models/grupo.dart';
import '../models/usuario.dart';
import '../services/amigos_service.dart';
import '../services/grupos_service.dart';
import '../theme/app_colors.dart';

/// Agenda de amigos guardados y grupos consolidados de amigos, para poder
/// invitarlos de una sola vez a un desafío grupal en vez de tener que
/// pasarles el código a mano cada vez.
class AmigosScreen extends StatefulWidget {
  final Usuario usuario;
  const AmigosScreen({super.key, required this.usuario});

  @override
  State<AmigosScreen> createState() => _AmigosScreenState();
}

class _AmigosScreenState extends State<AmigosScreen> {
  List<Amigo> _amigos = [];
  List<Grupo> _grupos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final amigos = await AmigosService.listar(widget.usuario.id);
    final grupos = await GruposService.listar(widget.usuario.id);
    if (!mounted) return;
    setState(() {
      _amigos = amigos;
      _grupos = grupos;
      _cargando = false;
    });
  }

  Future<void> _agregarAmigo() async {
    final ctrl = TextEditingController();
    final codigo = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.parchment,
        title: const Text('Agregar amigo'),
        content: TextField(
          controller: ctrl,
          maxLength: 6,
          textAlign: TextAlign.center,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(hintText: 'Código de perfil', counterText: ''),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(ctrl.text.trim()), child: const Text('Agregar')),
        ],
      ),
    );
    if (codigo == null || codigo.isEmpty || !mounted) return;
    try {
      await AmigosService.agregarPorCodigo(widget.usuario.id, codigo);
      await _cargar();
    } on AmigoEsUnoMismoException {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ese es tu propio código 😅')));
    } on AmigoYaExisteException {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ya lo tenías agregado.')));
    } on CodigoInvalidoException {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No encontramos ese código.')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo agregar. Probá de nuevo.')));
    }
  }

  Future<void> _compartirCodigo() async {
    final codigo = widget.usuario.codigoReferido;
    if (codigo == null) return;
    await Share.share('🎲 ¡Jugá Ocaland conmigo! Usá mi código $codigo al entrar.\n${AppConfig.appUrl}');
  }

  Future<void> _eliminarAmigo(Amigo a) async {
    await AmigosService.eliminar(a.id);
    await _cargar();
  }

  Future<void> _crearGrupo() async {
    final ctrl = TextEditingController();
    final nombre = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.parchment,
        title: const Text('Nuevo grupo'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'Nombre del grupo (ej: Primos)')),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(ctrl.text.trim()), child: const Text('Crear')),
        ],
      ),
    );
    if (nombre == null || nombre.isEmpty || !mounted) return;
    await GruposService.crear(widget.usuario.id, nombre);
    await _cargar();
  }

  Future<void> _abrirGrupo(Grupo g) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => _GrupoDetalleScreen(grupo: g, amigosDisponibles: _amigos)));
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.parchment,
      appBar: AppBar(backgroundColor: AppColors.parchment, elevation: 0, foregroundColor: AppColors.violetDark, title: const Text('👥 Mis amigos')),
      body: SafeArea(
        child: _cargando
            ? const Center(child: CircularProgressIndicator(color: AppColors.violetDark))
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [AppColors.violet.withValues(alpha: 0.85), AppColors.fuchsia.withValues(alpha: 0.85)]),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              const Text('Invitá gente con tu código 👇', style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              Text(
                                widget.usuario.codigoReferido ?? '—',
                                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: widget.usuario.codigoReferido == null ? null : _compartirCodigo,
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.violetDark, shape: const StadiumBorder()),
                                icon: const Icon(Icons.share, size: 18),
                                label: const Text('Compartir mi código'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton(onPressed: _agregarAmigo, child: const Text('¿Ya tenés un código? Agregar amigo')),
                        const SizedBox(height: 20),
                        const Text('Amigos', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.violetDark)),
                        const SizedBox(height: 6),
                        if (_amigos.isEmpty) const Text('Todavía no agregaste a nadie.', style: TextStyle(fontSize: 12.5, color: Color(0xFF9B8AB5))),
                        for (final a in _amigos)
                          Card(
                            child: ListTile(
                              leading: const Text('🙂', style: TextStyle(fontSize: 20)),
                              title: Text(a.apodo),
                              trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _eliminarAmigo(a)),
                            ),
                          ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Grupos', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.violetDark)),
                            TextButton(onPressed: _crearGrupo, child: const Text('+ Nuevo grupo')),
                          ],
                        ),
                        if (_grupos.isEmpty) const Text('Todavía no armaste ningún grupo.', style: TextStyle(fontSize: 12.5, color: Color(0xFF9B8AB5))),
                        for (final g in _grupos)
                          Card(
                            child: ListTile(
                              leading: const Text('👨‍👩‍👧‍👦', style: TextStyle(fontSize: 20)),
                              title: Text(g.nombre),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _abrirGrupo(g),
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
}

class _GrupoDetalleScreen extends StatefulWidget {
  final Grupo grupo;
  final List<Amigo> amigosDisponibles;
  const _GrupoDetalleScreen({required this.grupo, required this.amigosDisponibles});

  @override
  State<_GrupoDetalleScreen> createState() => _GrupoDetalleScreenState();
}

class _GrupoDetalleScreenState extends State<_GrupoDetalleScreen> {
  List<GrupoMiembro> _miembros = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final m = await GruposService.miembros(widget.grupo.id);
    if (mounted) setState(() { _miembros = m; _cargando = false; });
  }

  Future<void> _agregarMiembro() async {
    final yaAdentro = _miembros.map((m) => m.amigoUsuarioId).toSet();
    final candidatos = widget.amigosDisponibles.where((a) => !yaAdentro.contains(a.amigoUsuarioId)).toList();
    if (candidatos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ya están todos tus amigos en este grupo.')));
      return;
    }
    final elegido = await showDialog(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        backgroundColor: AppColors.parchment,
        title: const Text('Agregar al grupo'),
        children: [
          for (final a in candidatos)
            SimpleDialogOption(onPressed: () => Navigator.of(dialogContext).pop(a), child: Text(a.apodo)),
        ],
      ),
    );
    if (elegido == null) return;
    await GruposService.agregarMiembro(widget.grupo.id, elegido.amigoUsuarioId, elegido.apodo);
    _cargar();
  }

  Future<void> _quitar(GrupoMiembro m) async {
    await GruposService.quitarMiembro(m.id);
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.parchment,
      appBar: AppBar(backgroundColor: AppColors.parchment, elevation: 0, foregroundColor: AppColors.violetDark, title: Text(widget.grupo.nombre)),
      body: SafeArea(
        child: _cargando
            ? const Center(child: CircularProgressIndicator(color: AppColors.violetDark))
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton(onPressed: _agregarMiembro, child: const Text('+ Agregar amigo a este grupo')),
                        const SizedBox(height: 12),
                        if (_miembros.isEmpty) const Text('Este grupo todavía no tiene miembros.', style: TextStyle(fontSize: 12.5, color: Color(0xFF9B8AB5))),
                        for (final m in _miembros)
                          Card(
                            child: ListTile(
                              leading: const Text('🙂', style: TextStyle(fontSize: 20)),
                              title: Text(m.apodo),
                              trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _quitar(m)),
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
}
