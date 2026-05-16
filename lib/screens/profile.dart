import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth/auth.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mi perfil',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Cerrar sesión'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFBB0014),
                    side: const BorderSide(color: Color(0xFFBB0014)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
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
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _changeProfilePicture() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image != null) {
      setState(() => _isUploading = true);
      try {
        final bytes = await image.readAsBytes();
        final base64Image = 'data:${image.mimeType ?? 'image/jpeg'};base64,${base64Encode(bytes)}';
        final result = await AuthService().updateProfilePicture(base64Image);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? (result['success'] ? 'Foto actualizada' : 'Error')),
              backgroundColor: result['success'] ? const Color(0xFF00341C) : const Color(0xFFBB0014),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al procesar la imagen'), backgroundColor: Color(0xFFBB0014)),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isUploading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthService(),
      builder: (context, child) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final user = AuthService().currentUser ?? {};
    final fullName =
        '${user['firstName'] ?? 'Usuario'} ${user['lastName'] ?? ''}'.trim();
    final email = user['email'] ?? 'No disponible';
    final profilePicture = user['profilePicture'] as String?;

    ImageProvider? imageProvider;
    if (profilePicture != null && profilePicture.isNotEmpty) {
      if (profilePicture.startsWith('data:image')) {
        final base64Str = profilePicture.split(',').last;
        imageProvider = MemoryImage(base64Decode(base64Str));
      } else if (profilePicture.startsWith('http')) {
        imageProvider = NetworkImage(profilePicture);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: _isUploading ? null : _changeProfilePicture,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: const Color(0xFF00341C),
                    backgroundImage: imageProvider,
                    child: imageProvider == null
                        ? const Icon(Icons.person, size: 40, color: Colors.white)
                        : null,
                  ),
                  if (_isUploading)
                    const Positioned.fill(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Icon(Icons.camera_alt, size: 16, color: Color(0xFF00341C)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 48),
        Text(
          'Información personal',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              _buildProfileField('Nombre completo', fullName),
              Divider(height: 1, color: Colors.grey.shade200),
              _buildProfileField('Correo electrónico', email),
            ],
          ),
        ),
        const SizedBox(height: 48),
        Text(
          'Preferencias',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              SwitchListTile(
                title: const Text(
                  'Notificaciones push',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                value: true,
                onChanged: (val) {},
                activeColor: const Color(0xFF00341C),
              ),
              Divider(height: 1, color: Colors.grey.shade200),
              SwitchListTile(
                title: const Text(
                  'Notificaciones por correo',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                value: false,
                onChanged: (val) {},
                activeColor: const Color(0xFF00341C),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
