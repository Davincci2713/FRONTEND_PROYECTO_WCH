import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mi Perfil', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 32),
          const ProfileForm(),
        ],
      ),
    );
  }
}

class ProfileForm extends StatelessWidget {
  const ProfileForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Color(0xFF00341C),
                child: Icon(Icons.person, size: 50, color: Colors.white),
              ),
              SizedBox(height: 16),
              Text('Usuario Ejemplo', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text('usuario@ejemplo.com', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
        const SizedBox(height: 32),
        const Text('Información Personal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Divider(),
        const SizedBox(height: 16),
        _buildProfileField('Nombre', 'Usuario Ejemplo'),
        _buildProfileField('Correo', 'usuario@ejemplo.com'),
        _buildProfileField('País Favorito', 'Colombia'),
        const SizedBox(height: 32),
        const Text('Preferencias', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Divider(),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Notificaciones Push'),
          value: true,
          onChanged: (val) {},
        ),
        SwitchListTile(
          title: const Text('Notificaciones por Correo'),
          value: false,
          onChanged: (val) {},
        ),
      ],
    );
  }

  Widget _buildProfileField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
