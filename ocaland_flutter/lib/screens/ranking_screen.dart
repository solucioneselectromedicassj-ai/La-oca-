import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../services/supabase_service.dart';
import '../theme/app_colors.dart';

class RankingScreen extends StatefulWidget {
  final Usuario usuario;
  const RankingScreen({super.key, required this.usuario});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  List<Usuario>? _top;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final rows = await SupabaseService.from('usuarios').select().order('partidas_ganadas', ascending: false).limit(20);
      if (!mounted) return;
      setState(() => _top = (rows as List).map((r) => Usuario.fromJson(r as Map<String, dynamic>)).toList());
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  static const _medallas = ['🥇', '🥈', '🥉'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.parchment,
      appBar: AppBar(backgroundColor: AppColors.parchment, elevation: 0, foregroundColor: AppColors.violetDark, title: const Text('🏆 Ranking')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _contenido(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _contenido() {
    if (_error) return const Text('No se pudo cargar el ranking.');
    if (_top == null) return const Center(child: CircularProgressIndicator(color: AppColors.violetDark));
    if (_top!.isEmpty) return const Text('Todavía no hay nadie en el ranking.');

    final estoyEnElTop = _top!.any((u) => u.id == widget.usuario.id);

    return SingleChildScrollView(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < _top!.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${i < 3 ? _medallas[i] : '${i + 1}.'} ${_top![i].nombre}${_top![i].id == widget.usuario.id ? ' (vos)' : ''}',
                        style: TextStyle(fontWeight: _top![i].id == widget.usuario.id ? FontWeight.bold : FontWeight.normal, color: _top![i].id == widget.usuario.id ? AppColors.violetDark : null),
                      ),
                      Text('${_top![i].partidasGanadas} 🏆'),
                    ],
                  ),
                ),
              if (!estoyEnElTop)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('Tu posición: fuera del Top 20 — tenés ${widget.usuario.partidasGanadas} 🏆', style: const TextStyle(fontSize: 12.5)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
