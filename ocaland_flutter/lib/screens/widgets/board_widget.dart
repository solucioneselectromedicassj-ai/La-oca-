import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/board_layout.dart';
import '../../models/jugador.dart';
import '../../theme/app_colors.dart';

// Grilla visual de 10x10 (más grande que las 30 casillas a propósito: al
// haber más "huecos" libres que casilleros, queda espacio de separación
// visible entre una casilla y la siguiente en vez de verse todas pegadas).
const _visualGrid = 10;

/// Tres formas de sendero bien distintas entre sí, para que el tablero no
/// se sienta monótono a lo largo de las 10 etapas de la campaña. Se elige
/// una según la etapa (grupos de a 3) — ver [boardShapeForEtapa].
enum BoardShape { espiral, triangulo, circulo }

BoardShape boardShapeForEtapa(int etapa) {
  const formas = [BoardShape.espiral, BoardShape.triangulo, BoardShape.circulo];
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

/// Sendero en forma de triángulo: filas que crecen de a 1 casillero
/// (alineadas a la izquierda), recorridas en zigzag — cada fila entra
/// justo donde terminó la anterior, así el camino queda siempre continuo.
List<(int, int)> _trianguloCoords() {
  const rowLengths = [1, 2, 3, 4, 5, 6, 7];
  const offX = 1, offY = 1; // margen para centrarlo un poco en la grilla
  final cells = <(int, int)>[];
  var lastEnd = 0;
  for (var r = 0; r < rowLengths.length; r++) {
    final len = rowLengths[r];
    final startL2R = 0;
    final startR2L = len - 1;
    final goL2R = r == 0 || (startL2R - lastEnd).abs() <= (startR2L - lastEnd).abs();
    if (goL2R) {
      for (var c = 0; c < len; c++) {
        cells.add((offX + c, offY + r));
      }
      lastEnd = len - 1;
    } else {
      for (var c = len - 1; c >= 0; c--) {
        cells.add((offX + c, offY + r));
      }
      lastEnd = 0;
    }
  }
  // remate corto de 2 casillas para llegar a las 30, siguiendo desde donde
  // quedó la última fila (queda de "cola" del triángulo).
  final tailRow = rowLengths.length;
  final startCol = (lastEnd + 1).clamp(0, _visualGrid - 1 - offX);
  cells.add((offX + startCol, offY + tailRow));
  cells.add((offX + max(0, startCol - 1), offY + tailRow));
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
