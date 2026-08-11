import 'dart:async';
import 'package:flutter/material.dart';
import '../models/mensaje.dart';
import '../models/usuario.dart';
import '../services/mensajes_service.dart';
import '../theme/app_colors.dart';
import 'desafio_grupal_screen.dart';

/// Buzón de avisos: invitaciones de amigos a desafíos grupales, y avisos
/// de la mascota (por ejemplo, que el cazador se la llevó). A diferencia
/// del resto de las notificaciones nuevas de esta sesión (sellos,
/// comodines), esto sí vive en Supabase porque tiene que llegar de un
/// dispositivo a otro.
class BuzonScreen extends StatefulWidget {
  final Usuario usuario;
  final String edadBracket;
  final String pais;
  const BuzonScreen({super.key, required this.usuario, required this.edadBracket, required this.pais});

  @override
  State<BuzonScreen> createState() => _BuzonScreenState();
}

class _BuzonScreenState extends State<BuzonScreen> {
  List<Mensaje> _mensajes = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final m = await MensajesService.listar(widget.usuario.id);
    if (!mounted) return;
    setState(() {
      _mensajes = m;
      _cargando = false;
    });
    unawaited(MensajesService.marcarTodosLeidos(widget.usuario.id));
  }

  Future<void> _unirseDesafio(Mensaje m) async {
    final codigo = m.payload?['desafio_codigo'] as String?;
    if (codigo == null) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => DesafioGrupalScreen(usuario: widget.usuario, nombre: widget.usuario.nombre, edadBracket: widget.edadBracket, pais: widget.pais, codigoInicial: codigo),
    ));
  }

  Future<void> _eliminar(Mensaje m) async {
    await MensajesService.eliminar(m.id);
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.parchment,
      appBar: AppBar(backgroundColor: AppColors.parchment, elevation: 0, foregroundColor: AppColors.violetDark, title: const Text('📬 Buzón')),
      body: SafeArea(
        child: _cargando
            ? const Center(child: CircularProgressIndicator(color: AppColors.violetDark))
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: _mensajes.isEmpty
                      ? const Padding(padding: EdgeInsets.all(24), child: Text('No tenés mensajes por ahora.', style: TextStyle(color: Color(0xFF9B8AB5))))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _mensajes.length,
                          itemBuilder: (context, i) {
                            final m = _mensajes[i];
                            final esInvitacion = m.tipo == 'invitacion_desafio' && m.payload?['desafio_codigo'] != null;
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(m.remitenteNombre != null ? '${m.remitenteNombre} te escribió:' : '🪿 Ocaland', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF9B8AB5))),
                                    const SizedBox(height: 4),
                                    Text(m.texto, style: const TextStyle(fontSize: 14.5, color: AppColors.violetDark)),
                                    if (esInvitacion) ...[
                                      const SizedBox(height: 10),
                                      SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => _unirseDesafio(m), child: const Text('Unirme al desafío'))),
                                    ],
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => _eliminar(m)),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
      ),
    );
  }
}
