import 'package:flutter/material.dart';
import 'package:frontend_proyecto/utils/theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 40, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('MI PERFIL', style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2)),
          const SizedBox(height: 4),
          const Text('Cuenta', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 28),
          const _ProfileHeader(),
          const SizedBox(height: 28),
          const _ProfileStats(),
          const SizedBox(height: 28),
          const _ProfileInfo(),
          const SizedBox(height: 28),
          const _ProfilePreferences(),
          const SizedBox(height: 28),
          const _DangerZone(),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              // ESPACIO AVATAR: reemplaza con CircleAvatar con imagen
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.accentRed, width: 2),
                ),
                child: const Icon(Icons.person, size: 44, color: Colors.white),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: AppTheme.accentRed, shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Usuario Ejemplo', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('usuario@ejemplo.com', style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 13)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.accentGreen.withOpacity(0.4)),
                  ),
                  child: const Text('FANÁTICO VERIFICADO', style: TextStyle(color: AppTheme.accentGreen, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              side: const BorderSide(color: AppTheme.divider),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            child: const Text('EDITAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: 1.5, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _ProfileStats extends StatelessWidget {
  const _ProfileStats();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth > 500;
      final stats = [
        _StatItem('LÁMINAS', '250', AppTheme.accentBlue),
        _StatItem('POLLAS', '3', AppTheme.accentGreen),
        _StatItem('TICKETS', '2', AppTheme.accentRed),
        _StatItem('PUNTOS', '340', AppTheme.accentYellow),
      ];
      if (isWide) {
        return Row(
          children: stats.map((s) => Expanded(child: Padding(
            padding: EdgeInsets.only(right: s == stats.last ? 0 : 12),
            child: _StatBox(item: s),
          ))).toList(),
        );
      }
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.2,
        physics: const NeverScrollableScrollPhysics(),
        children: stats.map((s) => _StatBox(item: s)).toList(),
      );
    });
  }
}

class _StatItem {
  final String label, value;
  final Color color;
  const _StatItem(this.label, this.value, this.color);
}

class _StatBox extends StatelessWidget {
  final _StatItem item;
  const _StatBox({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: item.color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(item.value, style: TextStyle(color: item.color, fontSize: 24, fontWeight: FontWeight.w900)),
          Text(item.label, style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
        ],
      ),
    );
  }
}

class _ProfileInfo extends StatelessWidget {
  const _ProfileInfo();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('INFORMACIÓN PERSONAL', style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2)),
          const SizedBox(height: 16),
          _InfoRow('Nombre', 'Usuario Ejemplo'),
          const Divider(color: AppTheme.divider, height: 24),
          _InfoRow('Correo', 'usuario@ejemplo.com'),
          const Divider(color: AppTheme.divider, height: 24),
          _InfoRow('País Favorito', '🇨🇴 Colombia'),
          const Divider(color: AppTheme.divider, height: 24),
          _InfoRow('Miembro desde', 'Mayo 2026'),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 140,
          child: Text(label, style: const TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 13)),
        ),
        Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14))),
        const Icon(Icons.edit_outlined, color: AppTheme.onSurfaceMuted, size: 16),
      ],
    );
  }
}

class _ProfilePreferences extends StatefulWidget {
  const _ProfilePreferences();

  @override
  State<_ProfilePreferences> createState() => _ProfilePreferencesState();
}

class _ProfilePreferencesState extends State<_ProfilePreferences> {
  bool _pushNotif = true;
  bool _emailNotif = false;
  bool _matchAlerts = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PREFERENCIAS', style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2)),
          const SizedBox(height: 16),
          _PreferenceSwitch(
            label: 'Notificaciones Push',
            subtitle: 'Recibe alertas en tu dispositivo',
            value: _pushNotif,
            onChanged: (v) => setState(() => _pushNotif = v),
          ),
          const Divider(color: AppTheme.divider, height: 20),
          _PreferenceSwitch(
            label: 'Notificaciones por Correo',
            subtitle: 'Confirmaciones y resúmenes',
            value: _emailNotif,
            onChanged: (v) => setState(() => _emailNotif = v),
          ),
          const Divider(color: AppTheme.divider, height: 20),
          _PreferenceSwitch(
            label: 'Alertas de Partidos',
            subtitle: 'Inicio, goles y resultados finales',
            value: _matchAlerts,
            onChanged: (v) => setState(() => _matchAlerts = v),
          ),
        ],
      ),
    );
  }
}

class _PreferenceSwitch extends StatelessWidget {
  final String label, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PreferenceSwitch({required this.label, required this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
              Text(subtitle, style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 12)),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.accentGreen,
          inactiveThumbColor: AppTheme.onSurfaceMuted,
          inactiveTrackColor: AppTheme.surfaceElevated,
        ),
      ],
    );
  }
}

class _DangerZone extends StatelessWidget {
  const _DangerZone();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.accentRed.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.accentRed.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ZONA DE PELIGRO', style: TextStyle(color: AppTheme.accentRed, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text('Eliminar tu cuenta es una acción permanente e irreversible.', style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 13)),
              ),
              const SizedBox(width: 16),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.accentRed,
                  side: const BorderSide(color: AppTheme.accentRed),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: const Text('ELIMINAR CUENTA', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 11)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
