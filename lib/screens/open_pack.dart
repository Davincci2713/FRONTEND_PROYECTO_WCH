import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/album_service.dart';
import '../services/auth/auth.dart';

class OpenPackScreen extends StatefulWidget {
  const OpenPackScreen({super.key});

  @override
  State<OpenPackScreen> createState() => _OpenPackScreenState();
}

class _OpenPackScreenState extends State<OpenPackScreen> {
  final AlbumService _albumService = AlbumService();
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _stickers = [];

  int get _currentUserId => AuthService().currentUserId ?? 1;

  @override
  void initState() {
    super.initState();
    _openPack();
  }

  Future<void> _openPack() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _albumService.openPack(_currentUserId);
      if (mounted) {
        setState(() {
          _stickers = data['stickers'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(title: const Text('¡Apertura de Sobre!')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _errorMessage != null
          ? _buildErrorView(context, theme)
          : _buildSuccessView(context, theme),
    );
  }

  Widget _buildErrorView(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('No se pudo abrir el sobre', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.go('/album'),
              child: const Text('VOLVER AL ÁLBUM'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text('Has obtenido ${_stickers.length} nuevas láminas', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 32),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: _stickers.map((s) => _buildCard(context, s['name'], s['team'], true, false)).toList(),
          ),
          const SizedBox(height: 48),
          ElevatedButton.icon(
            onPressed: _openPack,
            icon: const Icon(Icons.style),
            label: const Text('ABRIR OTRO SOBRE'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.secondary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => context.go('/album'),
            icon: const Icon(Icons.auto_stories),
            label: const Text('IR AL ÁLBUM'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, String name, String country, bool isNew, bool isRepeated, {bool isSpecial = false}) {
    return Container(
      width: 180,
      height: 240,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4)),
        ],
        border: isSpecial ? Border.all(color: Colors.amber, width: 2) : null,
      ),
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Stack(
                children: [
                  const Center(child: Icon(Icons.person, size: 64, color: Colors.grey)),
                  if (isNew)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
                        child: const Text('NUEVA', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  if (isRepeated)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(12)),
                        child: const Text('REPETIDA', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  if (isSpecial)
                    const Positioned(
                      top: 8,
                      right: 8,
                      child: Icon(Icons.stars, color: Colors.amber),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(country, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
