import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth/auth.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 48, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Mi Perfil', style: theme.textTheme.headlineMedium),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.red),
                tooltip: 'Cerrar Sesión',
                onPressed: () {
                  AuthService().logout();
                  context.go('/login');
                },
              ),
            ],
          ),
          const SizedBox(height: 32),
          const ProfileForm(),
        ],
      ),
    );
  }
}

class ProfileForm extends StatefulWidget {
  const ProfileForm({super.key});

  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser ?? {};
    final fullName = '${user['firstName'] ?? 'Usuario'} ${user['lastName'] ?? ''}'.trim();
    final email = user['email'] ?? 'No disponible';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: [
              const CircleAvatar(
                radius: 50,
                backgroundColor: Color(0xFF00341C),
                child: Icon(Icons.person, size: 50, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(fullName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text(email, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
        const SizedBox(height: 32),
        const Text('Información Personal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Divider(),
        const SizedBox(height: 16),
        _buildProfileField('Nombre Completo', fullName),
        _buildProfileField('Correo', email),
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
