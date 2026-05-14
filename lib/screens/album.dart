import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/album_service.dart';
import '../services/auth/auth.dart';

class AlbumScreen extends StatefulWidget {
  const AlbumScreen({super.key});

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  final AlbumService _albumService = AlbumService();
  Map<String, dynamic>? _albumData;
  bool _isLoading = true;

  int get _currentUserId => AuthService().currentUserId ?? 1;

  @override
  void initState() {
    super.initState();
    _fetchAlbum();
  }

  Future<void> _fetchAlbum() async {
    try {
      final data = await _albumService.getUserAlbum(_currentUserId);
      setState(() {
        _albumData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_albumData == null) {
      return const Center(child: Text("Error cargando el álbum"));
    }

    final collections = _albumData!['collections'] as List<dynamic>? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 48, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Álbum Digital', style: theme.textTheme.headlineMedium),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => context.push('/album-progress'),
                    icon: const Icon(Icons.grid_view_rounded),
                    label: const Text('Ver Progreso'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      side: BorderSide(color: theme.colorScheme.primary),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/open-pack'),
                    icon: const Icon(Icons.style),
                    label: const Text('ABRIR SOBRE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Statistics
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 600) {
                return Row(
                  children: [
                    Expanded(child: _buildStatCard(context, 'Completado', '${_albumData!['completion_percentage']}%', Colors.green)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatCard(context, 'Láminas', '${_albumData!['total_stickers']}/${_albumData!['max_stickers']}', Colors.blue)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatCard(context, 'Repetidas', '${_albumData!['repeated_stickers']}', Colors.orange)),
                  ],
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStatCard(context, 'Completado', '${_albumData!['completion_percentage']}%', Colors.green),
                    const SizedBox(height: 16),
                    _buildStatCard(context, 'Láminas', '${_albumData!['total_stickers']}/${_albumData!['max_stickers']}', Colors.blue),
                    const SizedBox(height: 16),
                    _buildStatCard(context, 'Repetidas', '${_albumData!['repeated_stickers']}', Colors.orange),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 32),
          Text('Mis Colecciones', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              childAspectRatio: 0.8,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: collections.length,
            itemBuilder: (context, index) {
              final col = collections[index];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        color: Colors.grey[300],
                        child: const Center(child: Icon(Icons.flag, size: 48)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(col['name'] ?? 'Selección', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: color)),
        ],
      ),
    );
  }
}
