import 'package:flutter/material.dart';

import '../models/usuario.dart';
import '../theme/ocaland_theme.dart';
import 'board_screen.dart';
import 'mi_avatar_screen.dart';

/// Menú principal reorganizado en pestañas (Jugar / Bonus / Cuenta),
/// tal como quedó tras el reordenamiento descrito en la sección 15 de la
/// especificación (antes eran 11 botones apilados sin orden).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.usuario});

  final Usuario usuario;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _JugarTab(usuario: widget.usuario),
      _BonusTab(usuario: widget.usuario),
      _CuentaTab(usuario: widget.usuario),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('¡Hola de nuevo, ${widget.usuario.nombre}!'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Row(
                children: [
                  const Icon(Icons.monetization_on, color: OcalandColors.amarillo),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.usuario.monedas}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: tabs[_tabIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.casino), label: 'Jugar'),
          NavigationDestination(icon: Icon(Icons.card_giftcard), label: 'Bonus'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Cuenta'),
        ],
      ),
    );
  }
}

class _JugarTab extends StatelessWidget {
  const _JugarTab({required this.usuario});

  final Usuario usuario;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ModoCard(
          icono: Icons.smart_toy,
          titulo: 'Campaña Solo',
          subtitulo: '10 etapas contra un bot con dificultad creciente',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => BoardScreen(usuario: usuario)),
          ),
        ),
        const _ModoCard(
          icono: Icons.groups,
          titulo: 'Sala multijugador (tanda)',
          subtitulo: 'Mejor de 3 con amigos, vía código de sala',
        ),
        const _ModoCard(
          icono: Icons.emoji_events,
          titulo: 'Campaña grupal en vivo',
          subtitulo: 'Todos en el mismo tablero, etapa por etapa',
        ),
        const _ModoCard(
          icono: Icons.flag,
          titulo: 'Desafío grupal',
          subtitulo: 'Cada uno juega su campaña y se compara en un ranking',
        ),
      ],
    );
  }
}

class _BonusTab extends StatelessWidget {
  const _BonusTab({required this.usuario});

  final Usuario usuario;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ModoCard(
          icono: Icons.calendar_today,
          titulo: 'Recompensa diaria',
          subtitulo: 'Racha actual: ${usuario.rachaDias} día(s)',
        ),
        const _ModoCard(
          icono: Icons.casino_outlined,
          titulo: 'Ruleta multiplicador',
          subtitulo: 'x1.5, x2 o x3 monedas por tiempo limitado (1 vez al día)',
        ),
        const _ModoCard(
          icono: Icons.share,
          titulo: 'Compartir Ocaland',
          subtitulo: '+15 monedas por compartir (1 vez al día)',
        ),
      ],
    );
  }
}

class _CuentaTab extends StatelessWidget {
  const _CuentaTab({required this.usuario});

  final Usuario usuario;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ModoCard(
          icono: Icons.face,
          titulo: 'Mi avatar',
          subtitulo: 'Personalizá tu silueta, color y accesorios',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => MiAvatarScreen(usuario: usuario)),
          ),
        ),
        const SizedBox(height: 12),
        _StatTile(label: 'Monedas', value: '${usuario.monedas}'),
        _StatTile(label: 'Partidas jugadas', value: '${usuario.partidasJugadas}'),
        _StatTile(label: 'Partidas ganadas', value: '${usuario.partidasGanadas}'),
        _StatTile(
          label: 'Campañas completadas',
          value: '${usuario.campanasCompletadas}',
        ),
        _StatTile(label: 'Amigos invitados', value: '${usuario.amigosInvitados}'),
        if (usuario.codigoReferido != null)
          _StatTile(label: 'Tu código de referido', value: usuario.codigoReferido!),
      ],
    );
  }
}

class _ModoCard extends StatelessWidget {
  const _ModoCard({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    this.onTap,
  });

  final IconData icono;
  final String titulo;
  final String subtitulo;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: OcalandColors.violeta,
          foregroundColor: Colors.white,
          child: Icon(icono),
        ),
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitulo),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap ??
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$titulo: próximamente')),
              );
            },
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }
}
