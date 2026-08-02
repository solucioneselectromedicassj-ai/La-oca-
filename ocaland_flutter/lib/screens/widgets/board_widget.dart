import 'package:flutter/material.dart';
import '../../models/board_layout.dart';
import '../../models/jugador.dart';
import '../../theme/app_colors.dart';

/// Calcula la posición (0..1) de cada una de las 30 casillas siguiendo
/// exactamente el mismo algoritmo en espiral del prototipo HTML.
List<Offset> buildSpiralFractions() {
  const gridSize = 7;
  const visualGrid = gridSize + 1; // 8
  const cellFrac = 1 / visualGrid;
  var x = 0, y = 0, dx = 1, dy = 0;
  var segLen = gridSize, segPassed = 0, turns = 0;
  final cells = <Offset>[];
  for (var i = 0; i < visualGrid * visualGrid; i++) {
    cells.add(Offset(x * cellFrac, y * cellFrac));
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

class BoardWidget extends StatelessWidget {
  final Map<int, String> layoutCasillas;
  final List<JugadorPartida> jugadores;
  final String? animatingPlayerId;
  final int? animatingPos;
  final String? sufriendoPlayerId;

  const BoardWidget({
    super.key,
    required this.layoutCasillas,
    required this.jugadores,
    this.animatingPlayerId,
    this.animatingPos,
    this.sufriendoPlayerId,
  });

  @override
  Widget build(BuildContext context) {
    final cells = buildSpiralFractions();
    const cellSize = 1 / 8;

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
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(5), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 2))]),
      child: Stack(
        children: [
          Padding(padding: const EdgeInsets.all(2), child: Text('$index', style: const TextStyle(fontSize: 8, color: Color(0xFF7A6A99)))),
          if (tipo != null)
            Positioned(bottom: 1, right: 2, child: Text(AppColors.cellIcons[tipo] ?? '', style: const TextStyle(fontSize: 9))),
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
