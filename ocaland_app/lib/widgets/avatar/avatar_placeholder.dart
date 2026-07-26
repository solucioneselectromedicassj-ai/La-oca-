import 'package:flutter/material.dart';

import '../../models/item_personalizacion.dart';
import '../../theme/ocaland_theme.dart';

/// Representación provisoria de un avatar mientras no exista el arte
/// final (círculo de color + inicial de la silueta + ícono del
/// accesorio) — ver "Estado de implementación" en docs/SPEC_VISUAL_V2.md.
class AvatarPlaceholder extends StatelessWidget {
  const AvatarPlaceholder({
    super.key,
    this.silueta,
    this.color,
    this.accesorio,
    this.tamano = 64,
  });

  final ItemPersonalizacion? silueta;
  final ItemPersonalizacion? color;
  final ItemPersonalizacion? accesorio;
  final double tamano;

  static const Map<String, IconData> _iconosAccesorio = {
    'accesorio_gorro': Icons.school,
    'accesorio_anteojos': Icons.visibility,
    'accesorio_bufanda': Icons.waves,
    'accesorio_corona': Icons.workspace_premium,
  };

  @override
  Widget build(BuildContext context) {
    final colorFondo = color?.color ?? OcalandColors.violeta;
    final inicial = (silueta?.nombre.isNotEmpty ?? false) ? silueta!.nombre[0] : '?';
    final iconoAccesorio =
        accesorio != null ? _iconosAccesorio[accesorio!.id] : null;

    return SizedBox(
      width: tamano,
      height: tamano,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: colorFondo,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                inicial,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: tamano * 0.4,
                ),
              ),
            ),
          ),
          if (iconoAccesorio != null)
            Positioned(
              top: -tamano * 0.08,
              right: -tamano * 0.08,
              child: Container(
                padding: EdgeInsets.all(tamano * 0.06),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(iconoAccesorio, size: tamano * 0.28, color: Colors.black87),
              ),
            ),
        ],
      ),
    );
  }
}
