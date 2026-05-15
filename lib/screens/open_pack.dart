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
  final _albumService = AlbumService();

  // null = pantalla de inicio; true = cargando; false = resultado listo
  bool? _opening;
  String? _error;
  List<dynamic> _stickers = [];
  int _packsToday = 0;
  int _packBalance = 0;
  int _packsRemaining = 3;
  bool _loadingInfo = true;

  int? get _uid => AuthService().currentUserId;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    final uid = _uid;
    if (uid == null) {
      setState(() => _loadingInfo = false);
      return;
    }
    try {
      final data = await _albumService.getUserAlbum(uid);
      if (mounted)
        setState(() {
          _packBalance = (data['pack_balance'] as num?)?.toInt() ?? 0;
          _loadingInfo = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loadingInfo = false);
    }
  }

  Future<void> _openPack() async {
    final uid = _uid;
    if (uid == null) {
      setState(() => _error = 'Debes iniciar sesión para abrir sobres.');
      return;
    }
    setState(() {
      _opening = true;
      _error = null;
    });
    try {
      final data = await _albumService.openPack(uid);
      if (mounted)
        setState(() {
          _stickers = data['stickers'] ?? [];
          _packsToday = (data['packs_today'] as num?)?.toInt() ?? 0;
          _packsRemaining =
              (data['packs_remaining_today'] as num?)?.toInt() ?? 0;
          _packBalance = (data['pack_balance'] as num?)?.toInt() ?? 0;
          _opening = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _opening = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Abrir sobre',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF00341C),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/album'),
        ),
      ),
      body: _loadingInfo
          ? const Center(child: CircularProgressIndicator())
          : _opening == true
          ? _buildLoading()
          : _opening == false && _stickers.isNotEmpty
          ? _buildResult(theme)
          : _buildLobby(theme),
    );
  }

  // ── Pantalla de lobby (antes de abrir) ────────────────────────────────────
  Widget _buildLobby(ThemeData theme) {
    final noSession = _uid == null;
    final noPacks = _packBalance <= 0;

    return Center(
      child: Container(
        width: 450,
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.style, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 24),
            Text(
              'Sobres disponibles: $_packBalance',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Abiertos hoy: $_packsToday / 3',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            if (noSession)
              ElevatedButton(
                onPressed: () => context.go('/login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00341C),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                ),
                child: const Text(
                  'Iniciar sesión',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: noPacks ? null : _openPack,
                icon: const Icon(Icons.style, size: 20),
                label: Text(noPacks ? 'Sin sobres disponibles' : 'Abrir sobre'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00341C),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            if (!noPacks && !noSession) ...[
              const SizedBox(height: 12),
              Text(
                'Puedes abrir $_packsRemaining sobre(s) más hoy',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() => const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(strokeWidth: 2),
        SizedBox(height: 16),
        Text('Abriendo sobre...', style: TextStyle(color: Colors.grey)),
      ],
    ),
  );

  // ── Pantalla de resultado ─────────────────────────────────────────────────
  Widget _buildResult(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Text(
            '¡${_stickers.length} láminas obtenidas!',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sobres restantes hoy: $_packsRemaining',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: _stickers.map((s) => _StickerCard(sticker: s)).toList(),
          ),
          const SizedBox(height: 48),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_packsRemaining > 0 && _packBalance > 0)
                ElevatedButton.icon(
                  onPressed: _openPack,
                  icon: const Icon(Icons.style, size: 18),
                  label: const Text('Abrir otro'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00341C),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: () => context.go('/album'),
                icon: const Icon(Icons.auto_stories, size: 18),
                label: const Text('Ver álbum'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  side: BorderSide(color: Colors.grey.shade300),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Tarjeta de lámina obtenida ────────────────────────────────────────────────
class _StickerCard extends StatelessWidget {
  final Map<String, dynamic> sticker;
  const _StickerCard({required this.sticker});

  static Color _rarityColor(String r) => switch (r) {
    'Legendary' => const Color(0xFFFFD700),
    'Epic' => const Color(0xFF9C27B0),
    'Rare' => const Color(0xFF1976D2),
    _ => Colors.grey.shade400,
  };

  static String _rarityLabel(String r) => switch (r) {
    'Legendary' => 'Legendaria',
    'Epic' => 'Épica',
    'Rare' => 'Rara',
    _ => 'Común',
  };

  @override
  Widget build(BuildContext context) {
    final rarity = sticker['rarity'] as String? ?? 'Common';
    final color = _rarityColor(rarity);
    final name = sticker['name'] as String? ?? '—';
    final team = sticker['team'] as String? ?? '—';
    final code = sticker['paniniCode'] as String?;
    final isSpecial = rarity == 'Legendary' || rarity == 'Epic';

    return Container(
      width: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color, width: isSpecial ? 2 : 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(5),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: color.withOpacity(0.1),
                  child: Icon(Icons.person, size: 24, color: color),
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  team,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _rarityLabel(rarity),
                    style: TextStyle(
                      fontSize: 10,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (code != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    '#$code',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
