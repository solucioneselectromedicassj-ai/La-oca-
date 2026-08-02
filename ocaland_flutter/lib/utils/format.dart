String formatearMs(int ms) {
  final totalSeg = (ms / 1000).round();
  final min = totalSeg ~/ 60;
  final seg = totalSeg % 60;
  return min > 0 ? '${min}m ${seg}s' : '${seg}s';
}
