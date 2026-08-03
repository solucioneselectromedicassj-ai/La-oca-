import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/board_layout.dart';
import '../../models/jugador.dart';
import '../../theme/app_colors.dart';

// Grilla visual de 10x10 (más grande que las 30 casillas a propósito: al
// haber más "huecos" libres que casilleros, queda espacio de separación
// visible entre una casilla y la siguiente en vez de verse todas pegadas).
const _visualGrid = 10;

/// Cuatro formas de sendero bien distintas entre sí, para que el tablero
/// no se sienta monótono a lo largo de las 10 etapas de la campaña: espiral
/// (etapas 1-3), triángulo (4-6), círculo (7-9) y una S para el cierre
/// (etapa 10) — ver [boardShapeForEtapa].
enum BoardShape { espiral, triangulo, circulo, ese }

BoardShape boardShapeForEtapa(int etapa) {
  const formas = [BoardShape.espiral, BoardShape.triangulo, BoardShape.circulo, BoardShape.ese];
  return formas[((etapa - 1) ~/ 3) % formas.length];
}

/// Calcula la posición (0..1) de cada una de las 30 casillas para la forma
/// de sendero indicada.
List<Offset> buildBoardFractions(BoardShape shape) {
  const cellFrac = 1 / _visualGrid;
  final coords = switch (shape) {
    BoardShape.espiral => _espiralCoords(),
    BoardShape.triangulo => _trianguloCoords(),
    BoardShape.circulo => _circuloCoords(),
    BoardShape.ese => _eseCoords(),
  };
  return coords.map((c) => Offset(c.$1 * cellFrac, c.$2 * cellFrac)).toList();
}

/// El mismo algoritmo en espiral del prototipo HTML original, escalado a
/// la grilla visual actual.
List<(int, int)> _espiralCoords() {
  final gridSize = _visualGrid - 1;
  var x = 0, y = 0, dx = 1, dy = 0;
  var segLen = gridSize, segPassed = 0, turns = 0;
  final cells = <(int, int)>[];
  for (var i = 0; i < _visualGrid * _visualGrid; i++) {
    cells.add((x, y));
    x += dx;
    y += dy;
    segPassed++;
    if (segPassed == segLen) {
      segPassed = 0;
      final ndx = -dy, ndy = dx;
      dx = ndx;
      dy = ndy;
      turns++;
      if (turns % 2 == 0) segLen--;
    }
  }
  return cells.take(BoardEngine.totalCells).toList();
}

/// Línea recta entre dos puntos de la grilla, con pasos de un solo
/// casillero (diagonal mientras se pueda, derecho para lo que sobre) —
/// para trazar los lados de los triángulos sin saltos.
List<(int, int)> _staircase((int, int) from, (int, int) to) {
  var (x, y) = from;
  final sx = (to.$1 - x).sign, sy = (to.$2 - y).sign;
  var ax = (to.$1 - x).abs(), ay = (to.$2 - y).abs();
  final points = <(int, int)>[];
  while (ax > 0 || ay > 0) {
    if (ax > 0 && ay > 0) {
      x += sx;
      y += sy;
      ax--;
      ay--;
    } else if (ax > 0) {
      x += sx;
      ax--;
    } else {
      y += sy;
      ay--;
    }
    points.add((x, y));
  }
  return points;
}

/// Sendero triangular: dos triángulos anidados (uno grande por afuera y
/// uno chico adentro, unidos por un puente corto) — como el ícono clásico
/// de espiral triangular, pero calcado sobre nuestras casillas.
List<(int, int)> _trianguloCoords() {
  const outerApex = (4, 0);
  const outerLeft = (0, 8);
  const outerRight = (8, 8);
  const innerApex = (4, 5);
  const innerLeft = (4, 6);
  const innerRight = (5, 6);

  // Arranca en una esquina de la base (no en el ápice) para que el ápice
  // quede a mitad de camino del perímetro y no se vuelva a cruzar cerca
  // del puente hacia el triángulo interior.
  final cells = <(int, int)>[outerLeft];
  cells.addAll(_staircase(outerLeft, outerRight));
  cells.addAll(_staircase(outerRight, outerApex));
  final closing = _staircase(outerApex, outerLeft);
  cells.addAll(closing.sublist(0, closing.length - 1)); // no repetir el inicio
  cells.addAll(_staircase(cells.last, innerApex));
  cells.addAll(_staircase(innerApex, innerLeft));
  cells.addAll(_staircase(innerLeft, innerRight));
  final closingInner = _staircase(innerRight, innerApex);
  cells.addAll(closingInner.sublist(0, closingInner.length - 1));
  return cells;
}

/// Sendero circular: recorre el perímetro de un círculo (barrido de
/// ángulo) centrado en la grilla visual.
List<(int, int)> _circuloCoords() {
  final cx = (_visualGrid - 1) / 2, cy = (_visualGrid - 1) / 2;
  const r = 4.0;
  const steps = 300;
  final cells = <(int, int)>[];
  final seen = <(int, int)>{};
  for (var i = 0; i < steps; i++) {
    final theta = 2 * pi * i / steps;
    final x = (cx + r * cos(theta)).round().clamp(0, _visualGrid - 1);
    final y = (cy + r * sin(theta)).round().clamp(0, _visualGrid - 1);
    final p = (x, y);
    if (cells.isEmpty || p != cells.last) {
      if (seen.add(p)) cells.add(p);
    }
    if (cells.length == BoardEngine.totalCells) break;
  }
  return cells;
}

/// Sendero en forma de S, simétrica: fila de arriba (izq→der), baja por
/// la derecha, fila del medio (der→izq), baja por la izquierda — el mismo
/// largo que la bajada de la derecha — y fila de abajo (izq→der), del
/// mismo ancho que la de arriba. Remate de las 10 etapas de la campaña.
List<(int, int)> _eseCoords() {
  const width = 8; // ancho de las 3 filas (arriba, medio, abajo)
  const descent = 3; // largo de cada bajada, igual de los dos lados
  const offX = 1;
  const topRow = 0;
  final midRow = topRow + descent + 1;
  final botRow = midRow + descent + 1;
  final cells = <(int, int)>[];
  for (var c = 0; c < width; c++) {
    cells.add((offX + c, topRow));
  }
  final rightCol = offX + width - 1;
  for (var r = topRow + 1; r <= topRow + descent; r++) {
    cells.add((rightCol, r));
  }
  for (var c = width - 1; c >= 0; c--) {
    cells.add((offX + c, midRow));
  }
  for (var r = midRow + 1; r <= midRow + descent; r++) {
    cells.add((offX, r));
  }
  for (var c = 0; c < width; c++) {
    cells.add((offX + c, botRow));
  }
  return cells;
}

class BoardWidget extends StatelessWidget {
  final Map<int, String> layoutCasillas;
  final List<JugadorPartida> jugadores;
  final int etapa;
  final String? animatingPlayerId;
  final int? animatingPos;
  final String? sufriendoPlayerId;

  const BoardWidget({
    super.key,
    required this.layoutCasillas,
    required this.jugadores,
    this.etapa = 1,
    this.animatingPlayerId,
    this.animatingPos,
    this.sufriendoPlayerId,
  });

  @override
  Widget build(BuildContext context) {
    final cells = buildBoardFractions(boardShapeForEtapa(etapa));
    const cellSize = 1 / _visualGrid;

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.violet,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.violetDark, width: 5),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 6))],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final side = constraints.maxWidth;
            return Stack(
              children: [
                for (var i = 0; i < cells.length; i++)
                  Positioned(
                    left: cells[i].dx * side,
                    top: cells[i].dy * side,
                    width: cellSize * side,
                    height: cellSize * side,
                    child: _CellBox(index: i, tipo: BoardEngine.tipoCasilla(i, layoutCasillas)),
                  ),
                for (var idx = 0; idx < jugadores.length; idx++) _tokenFor(idx, jugadores[idx], cells, side, cellSize),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _tokenFor(int idx, JugadorPartida j, List<Offset> cells, double side, double cellSize) {
    final pos = (j.id == animatingPlayerId && animatingPos != null) ? animatingPos! : j.posicion;
    final clamped = pos.clamp(0, BoardEngine.totalCells - 1);
    final base = cells[clamped];
    final offX = (0.01 + (idx % 3) * 0.03) * side;
    final offY = (0.01 + (idx ~/ 3) * 0.03) * side;
    final size = 0.07 * side;
    final sufriendo = j.id == sufriendoPlayerId;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      left: base.dx * side + offX,
      top: base.dy * side + offY,
      width: size,
      height: size,
      child: _TokenDot(color: AppColors.tokenColors[idx % AppColors.tokenColors.length], letra: j.nombre.isNotEmpty ? j.nombre[0].toUpperCase() : '?', enCarcel: j.saltaTurno, sufriendo: sufriendo),
    );
  }
}

class _CellBox extends StatelessWidget {
  final int index;
  final String? tipo;
  const _CellBox({required this.index, required this.tipo});

  @override
  Widget build(BuildContext context) {
    final color = tipo != null ? AppColors.cellColors[tipo] : AppColors.parchment;
    return Container(
      margin: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(5), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 2))]),
      child: Stack(
        children: [
          Positioned(top: 1, left: 2, child: Text('$index', style: const TextStyle(fontSize: 7, color: Color(0xFF7A6A99)))),
          if (tipo != null)
            Center(child: Text(AppColors.cellIcons[tipo] ?? '', style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }
}

class _TokenDot extends StatefulWidget {
  final Color color;
  final String letra;
  final bool enCarcel;
  final bool sufriendo;
  const _TokenDot({required this.color, required this.letra, required this.enCarcel, required this.sufriendo});

  @override
  State<_TokenDot> createState() => _TokenDotState();
}

class _TokenDotState extends State<_TokenDot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));

  @override
  void didUpdateWidget(covariant _TokenDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.sufriendo && !oldWidget.sufriendo) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final shake = widget.sufriendo ? (1 - _ctrl.value) * 4 * ((_ctrl.value * 20).floor().isEven ? 1 : -1) : 0.0;
        return Transform.translate(
          offset: Offset(shake, 0),
          child: child,
        );
      },
      child: ColorFiltered(
        colorFilter: widget.enCarcel
            ? const ColorFilter.matrix(<double>[
                0.6, 0.2, 0.2, 0, 0,
                0.2, 0.6, 0.2, 0, 0,
                0.2, 0.2, 0.6, 0, 0,
                0, 0, 0, 1, 0,
              ])
            : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
        child: Container(
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white70, width: 2),
            boxShadow: [
              if (widget.sufriendo) const BoxShadow(color: Colors.redAccent, blurRadius: 6, spreadRadius: 3),
              const BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
          alignment: Alignment.center,
          child: Text(widget.letra, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 9)),
        ),
      ),
    );
  }
}
