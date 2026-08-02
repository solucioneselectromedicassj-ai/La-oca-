import 'package:flutter/material.dart';

import '../game/avatares/avatar_sprites.dart';
import '../models/item_personalizacion.dart';
import '../models/usuario.dart';
import '../services/supabase_service.dart';
import '../theme/ocaland_theme.dart';
import '../widgets/avatar/avatar_placeholder.dart';

/// Tienda/selector de personalización de avatar: silueta (personaje base)
/// + color (variante de arte completo de esa silueta, ver
/// docs/SPEC_VISUAL_V2.md sección 9) + accesorio. Diseño acordado en el
/// chat. Usa el arte real cuando existe (`AvatarSprites`), si no cae al
/// placeholder de círculo+inicial.
class MiAvatarScreen extends StatefulWidget {
  const MiAvatarScreen({super.key, required this.usuario});

  final Usuario usuario;

  @override
  State<MiAvatarScreen> createState() => _MiAvatarScreenState();
}

class _MiAvatarScreenState extends State<MiAvatarScreen> {
  late Usuario _usuario = widget.usuario;
  List<ItemPersonalizacion>? _catalogo;
  String? _error;
  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    _cargarCatalogo();
  }

  Future<void> _cargarCatalogo() async {
    try {
      final catalogo = await SupabaseService.instance.obtenerCatalogoPersonalizacion();
      if (!mounted) return;
      setState(() => _catalogo = catalogo);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'No se pudo cargar el catálogo: $e');
    }
  }

  ItemPersonalizacion? _itemDe(String? id) {
    if (id == null || _catalogo == null) return null;
    for (final item in _catalogo!) {
      if (item.id == id) return item;
    }
    return null;
  }

  /// Primer color de esa silueta (preferentemente uno gratis), para
  /// cuando se cambia de silueta y el color equipado no le pertenece.
  ItemPersonalizacion? _colorPorDefectoDe(String siluetaId) {
    final colores = _catalogo!.where(
      (i) => i.tipo == TipoItemPersonalizacion.color && i.siluetaId == siluetaId,
    );
    if (colores.isEmpty) return null;
    return colores.firstWhere((c) => c.gratis, orElse: () => colores.first);
  }

  Future<void> _onTapItem(ItemPersonalizacion item) async {
    if (_procesando) return;
    final p = _usuario.personalizacion;
    final desbloqueado = item.gratis || p.estaDesbloqueado(item.id);

    if (!desbloqueado) {
      if (_usuario.monedas < item.precio) {
        _mostrarSnack('Te faltan monedas para "${item.nombre}" (necesitás ${item.precio}).');
        return;
      }
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Desbloquear "${item.nombre}"'),
          content: Text('Cuesta ${item.precio} monedas. ¿Confirmás?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Comprar'),
            ),
          ],
        ),
      );
      if (confirmar != true) return;
    }

    // Si se cambia de silueta y el color equipado no le pertenece, hay
    // que resolver un color válido para la silueta nueva (el servidor
    // rechaza combinaciones de silueta/color que no coinciden).
    var color = item.tipo == TipoItemPersonalizacion.color ? item.id : p.color;
    if (item.tipo == TipoItemPersonalizacion.silueta) {
      final colorActual = _itemDe(p.color);
      if (colorActual?.siluetaId != item.id) {
        color = _colorPorDefectoDe(item.id)?.id;
      }
    }
    if (color == null) {
      _mostrarSnack('Esa silueta todavía no tiene ningún color disponible.');
      return;
    }

    setState(() => _procesando = true);
    try {
      if (!desbloqueado) {
        await SupabaseService.instance.comprarItemPersonalizacion(
          usuarioId: _usuario.id,
          itemId: item.id,
        );
      }
      final colorAEquipar = _itemDe(color);
      final necesitaDesbloquearColor =
          colorAEquipar != null && !colorAEquipar.gratis && !p.estaDesbloqueado(color);
      if (necesitaDesbloquearColor) {
        await SupabaseService.instance.comprarItemPersonalizacion(
          usuarioId: _usuario.id,
          itemId: color,
        );
      }
      await SupabaseService.instance.equiparPersonalizacion(
        usuarioId: _usuario.id,
        silueta: item.tipo == TipoItemPersonalizacion.silueta ? item.id : p.silueta ?? '',
        color: color,
        accesorio:
            item.tipo == TipoItemPersonalizacion.accesorio ? item.id : p.accesorio,
      );
      final actualizado = await SupabaseService.instance.obtenerUsuario(_usuario.id);
      if (actualizado != null && mounted) setState(() => _usuario = actualizado);
    } catch (e) {
      _mostrarSnack('Ocurrió un error: $e');
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  void _mostrarSnack(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  @override
  Widget build(BuildContext context) {
    final p = _usuario.personalizacion;
    final siluetaActual = _itemDe(p.silueta);
    final colorActual = _itemDe(p.color);
    final accesorioActual = _itemDe(p.accesorio);
    final spriteActual = AvatarSprites.de(p.color);

    return Scaffold(
      appBar: AppBar(title: const Text('Mi avatar')),
      body: _catalogo == null
          ? Center(child: _error != null ? Text(_error!) : const CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: Column(
                    children: [
                      spriteActual != null
                          ? Image.asset(spriteActual.caminata.first, height: 96)
                          : AvatarPlaceholder(
                              silueta: siluetaActual,
                              color: colorActual,
                              accesorio: accesorioActual,
                              tamano: 96,
                            ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.monetization_on, color: OcalandColors.amarillo),
                          const SizedBox(width: 4),
                          Text('${_usuario.monedas}',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _SeccionCatalogo(
                  titulo: 'Silueta',
                  items: _catalogo!.where((i) => i.tipo == TipoItemPersonalizacion.silueta),
                  equipadoId: p.silueta,
                  personalizacion: p,
                  onTap: _onTapItem,
                  spritePara: (item) =>
                      AvatarSprites.de(_colorPorDefectoDe(item.id)?.id),
                ),
                _SeccionCatalogo(
                  titulo: 'Color',
                  items: _catalogo!.where(
                    (i) =>
                        i.tipo == TipoItemPersonalizacion.color &&
                        i.siluetaId == p.silueta,
                  ),
                  equipadoId: p.color,
                  personalizacion: p,
                  onTap: _onTapItem,
                  spritePara: (item) => AvatarSprites.de(item.id),
                ),
                _SeccionCatalogo(
                  titulo: 'Accesorio',
                  items: _catalogo!.where((i) => i.tipo == TipoItemPersonalizacion.accesorio),
                  equipadoId: p.accesorio,
                  personalizacion: p,
                  onTap: _onTapItem,
                ),
              ],
            ),
    );
  }
}

class _SeccionCatalogo extends StatelessWidget {
  const _SeccionCatalogo({
    required this.titulo,
    required this.items,
    required this.equipadoId,
    required this.personalizacion,
    required this.onTap,
    this.spritePara,
  });

  final String titulo;
  final Iterable<ItemPersonalizacion> items;
  final String? equipadoId;
  final dynamic personalizacion;
  final ValueChanged<ItemPersonalizacion> onTap;
  final dynamic Function(ItemPersonalizacion item)? spritePara;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items.map((item) {
            final desbloqueado = item.gratis || personalizacion.estaDesbloqueado(item.id);
            final equipado = item.id == equipadoId;
            return _ItemTile(
              item: item,
              desbloqueado: desbloqueado,
              equipado: equipado,
              sprite: spritePara?.call(item),
              onTap: () => onTap(item),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({
    required this.item,
    required this.desbloqueado,
    required this.equipado,
    required this.onTap,
    this.sprite,
  });

  final ItemPersonalizacion item;
  final bool desbloqueado;
  final bool equipado;
  final VoidCallback onTap;
  final dynamic sprite;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 84,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: equipado ? OcalandColors.violeta : Colors.black12,
            width: equipado ? 2 : 1,
          ),
          color: Colors.white,
        ),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: desbloqueado ? 1 : 0.4,
                  child: sprite != null
                      ? Image.asset(sprite.caminata.first, height: 48)
                      : item.tipo == TipoItemPersonalizacion.color
                          ? AvatarPlaceholder(color: item, tamano: 48)
                          : item.tipo == TipoItemPersonalizacion.silueta
                              ? AvatarPlaceholder(silueta: item, tamano: 48)
                              : AvatarPlaceholder(accesorio: item, tamano: 48),
                ),
                if (!desbloqueado)
                  const Positioned(
                    bottom: -2,
                    right: -2,
                    child: Icon(Icons.lock, size: 16, color: Colors.black54),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              item.nombre,
              style: const TextStyle(fontSize: 11),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (!desbloqueado)
              Text(
                '${item.precio} 🪙',
                style: const TextStyle(fontSize: 10, color: Colors.black54),
              ),
          ],
        ),
      ),
    );
  }
}
