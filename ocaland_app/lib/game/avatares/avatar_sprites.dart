import '../../models/avatar_sprite_set.dart';

/// Registro de qué colores (skins) del catálogo de personalización ya
/// tienen arte real (spec visual v2, sección 3 y 9). Cada color es una
/// variante de arte completo de una silueta puntual — por eso se busca
/// por el id del color equipado, no por la silueta.
///
/// Las combinaciones sin arte real acá siguen usando el placeholder de
/// círculo+inicial (`AvatarPlaceholder`). A medida que lleguen más
/// variantes, agregar su entrada alcanza para que el resto (tablero,
/// festejo, reacción) las use solo.
class AvatarSprites {
  AvatarSprites._();

  static const String _base = 'assets/avatars';

  static const Map<String, AvatarSpriteSet> porColor = {
    'masculino_azul': AvatarSpriteSet(
      caminata: [
        '$_base/masculino/caminata_1.png',
        '$_base/masculino/caminata_2.png',
        '$_base/masculino/caminata_3.png',
        '$_base/masculino/caminata_4.png',
      ],
      festejo: [
        '$_base/masculino/festejo_1.png',
        '$_base/masculino/festejo_2.png',
        '$_base/masculino/festejo_3.png',
      ],
      reaccion: [
        '$_base/masculino/reaccion_1.png',
        '$_base/masculino/reaccion_2.png',
      ],
    ),
    'masculino_verde': AvatarSpriteSet(
      caminata: [
        '$_base/masculino_verde/caminata_1.png',
        '$_base/masculino_verde/caminata_2.png',
        '$_base/masculino_verde/caminata_3.png',
        '$_base/masculino_verde/caminata_4.png',
      ],
      festejo: [
        '$_base/masculino_verde/festejo_1.png',
        '$_base/masculino_verde/festejo_2.png',
        '$_base/masculino_verde/festejo_3.png',
      ],
      reaccion: [
        '$_base/masculino_verde/reaccion_1.png',
        '$_base/masculino_verde/reaccion_2.png',
      ],
    ),
    'androgino_azul': AvatarSpriteSet(
      caminata: [
        '$_base/androgino/caminata_1.png',
        '$_base/androgino/caminata_2.png',
        '$_base/androgino/caminata_3.png',
        '$_base/androgino/caminata_4.png',
      ],
      festejo: [
        '$_base/androgino/festejo_1.png',
        '$_base/androgino/festejo_2.png',
        '$_base/androgino/festejo_3.png',
      ],
      reaccion: [
        '$_base/androgino/reaccion_1.png',
        '$_base/androgino/reaccion_2.png',
      ],
    ),
    'femenino_azul': AvatarSpriteSet(
      caminata: [
        '$_base/femenino/caminata_1.png',
        '$_base/femenino/caminata_2.png',
        '$_base/femenino/caminata_3.png',
        '$_base/femenino/caminata_4.png',
      ],
      festejo: [
        '$_base/femenino/festejo_1.png',
        '$_base/femenino/festejo_2.png',
        '$_base/femenino/festejo_3.png',
      ],
      reaccion: [
        '$_base/femenino/reaccion_1.png',
        '$_base/femenino/reaccion_2.png',
      ],
    ),
  };

  static AvatarSpriteSet? de(String? colorId) =>
      colorId == null ? null : porColor[colorId];
}
