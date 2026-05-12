import 'package:flutter/material.dart';

class Inicio extends StatelessWidget {
  const Inicio({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 48, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bienvenido de nuevo, Fanático', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              double cardWidth = constraints.maxWidth < 300 ? constraints.maxWidth : 300;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(width: cardWidth, child: const DashboardCard(title: 'Próximos Partidos', icon: Icons.calendar_month)),
                  SizedBox(width: cardWidth, child: const DashboardCard(title: 'Mi Álbum', icon: Icons.book)),
                  SizedBox(width: cardWidth, child: const DashboardCard(title: 'Mis Pollas', icon: Icons.group)),
                ],
              );
            }
          ),
          const SizedBox(height: 32),
          Text('Noticias del Mundial', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: Text('Noticias destacadas')),
          ),
        ],
      ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;

  const DashboardCard({required this.title, required this.icon, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 32, color: const Color(0xFF00341C)),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          const Text('Ver más detalles', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class AppTopBar extends StatelessWidget {
  const AppTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          const Spacer(),
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
          const SizedBox(width: 16),
          const CircleAvatar(
            backgroundColor: Color(0xFF00341C),
            child: Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Flexible(child: Text('Usuario Ejemplo', style: TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
