import 'package:flutter/material.dart';
import '../../models/campana.dart';
import '../../theme/app_colors.dart';

class EtapaBanner extends StatefulWidget {
  final int etapa;
  const EtapaBanner({super.key, required this.etapa});

  @override
  State<EtapaBanner> createState() => _EtapaBannerState();
}

class _EtapaBannerState extends State<EtapaBanner> {
  bool _mostrarLeyenda = false;

  @override
  Widget build(BuildContext context) {
    final info = Campana.etapasInfo[widget.etapa];
    if (info == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Etapa ${widget.etapa}: ${info.nombre}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.violetDark))),
              TextButton(onPressed: () => setState(() => _mostrarLeyenda = !_mostrarLeyenda), child: const Text('📖 Leer')),
            ],
          ),
          if (_mostrarLeyenda) Text(info.leyenda, style: const TextStyle(fontStyle: FontStyle.italic, color: Color(0xFF7A6A99))),
        ],
      ),
    );
  }
}
