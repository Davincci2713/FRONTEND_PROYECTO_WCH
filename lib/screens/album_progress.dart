import 'package:flutter/material.dart';
import '../services/album_service.dart';
import '../services/auth/auth.dart';

class AlbumProgressScreen extends StatefulWidget {
  const AlbumProgressScreen({super.key});
  @override
  State<AlbumProgressScreen> createState() => _AlbumProgressScreenState();
}

class _AlbumProgressScreenState extends State<AlbumProgressScreen> {
  final _service = AlbumService();
  Map<String, dynamic>? _data;
  bool _loading = true;
  String _filter = 'all'; // 'all' | 'team' | 'special'
  String _query = '';

  int get _userId => AuthService().currentUserId ?? 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await _service.getAlbumProgress(_userId);
      if (mounted) setState(() { _data = d; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<dynamic> get _filteredSections {
    if (_data == null) return [];
    final sections = List<dynamic>.from(_data!['sections']);
    return sections.where((s) {
      if (_filter == 'team' && s['type'] != 'team') return false;
      if (_filter == 'special' && s['type'] != 'special') return false;
      if (_query.isNotEmpty) {
        final label = (s['label'] as String).toLowerCase();
        final hasMatch = label.contains(_query.toLowerCase()) ||
            (s['stickers'] as List).any((st) =>
                (st['name'] as String).toLowerCase().contains(_query.toLowerCase()));
        if (!hasMatch) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progreso del Álbum'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _data == null
              ? const Center(child: Text('Error cargando el álbum'))
              : Column(
                  children: [
                    _ProgressHeader(data: _data!),
                    _FilterBar(
                      filter: _filter,
                      query: _query,
                      onFilterChanged: (v) => setState(() => _filter = v),
                      onQueryChanged: (v) => setState(() => _query = v),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: _filteredSections.length,
                        itemBuilder: (ctx, i) =>
                            _SectionTile(section: _filteredSections[i]),
                      ),
                    ),
                  ],
                ),
    );
  }
}

// ---------------------------------------------------------------------------
// Progress header
// ---------------------------------------------------------------------------
class _ProgressHeader extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ProgressHeader({required this.data});

  @override
  Widget build(BuildContext context) {
    final pct = (data['completion_percentage'] as num).toDouble();
    final owned = data['total_owned'] as int;
    final total = data['total_unique'] as int;

    return Container(
      color: Theme.of(context).colorScheme.primary,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Stat(label: 'Obtenidas', value: '$owned', color: Colors.greenAccent),
              _Stat(label: 'Total', value: '$total', color: Colors.white70),
              _Stat(label: 'Completado', value: '${pct.toStringAsFixed(1)}%', color: Colors.amber),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _Stat({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
      Text(label, style: const TextStyle(fontSize: 12, color: Colors.white60)),
    ],
  );
}

// ---------------------------------------------------------------------------
// Filter bar
// ---------------------------------------------------------------------------
class _FilterBar extends StatelessWidget {
  final String filter, query;
  final ValueChanged<String> onFilterChanged, onQueryChanged;
  const _FilterBar({
    required this.filter, required this.query,
    required this.onFilterChanged, required this.onQueryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              for (final f in [
                ('all', 'Todos'),
                ('special', 'Especiales'),
                ('team', 'Equipos'),
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(f.$2),
                    selected: filter == f.$1,
                    onSelected: (_) => onFilterChanged(f.$1),
                    selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                    checkmarkColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          TextField(
            onChanged: onQueryChanged,
            decoration: InputDecoration(
              hintText: 'Buscar jugador o equipo…',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section expansion tile
// ---------------------------------------------------------------------------
class _SectionTile extends StatelessWidget {
  final Map<String, dynamic> section;
  const _SectionTile({required this.section});

  static const _specialEmoji = {
    'Golden Baller':    '⭐',
    'Top Keeper':       '🧤',
    'Defensive Rock':   '🛡️',
    'Midfield Maestro': '🎯',
    'Goal Machine':     '⚽',
    'Master Rookie':    '🌟',
    'Official':         '🏆',
    'Eternal':          '♾️',
  };

  static const _teamFlag = {
    'Alemania':               '🇩🇪',
    'Arabia Saudita':         '🇸🇦',
    'Argelia':                '🇩🇿',
    'Argentina':              '🇦🇷',
    'Australia':              '🇦🇺',
    'Austria':                '🇦🇹',
    'Bélgica':                '🇧🇪',
    'Bosnia Y Herzegovina':   '🇧🇦',
    'Bosnia y Herzegovina':   '🇧🇦',
    'Brasil':                 '🇧🇷',
    'Cabo Verde':             '🇨🇻',
    'Canadá':                 '🇨🇦',
    'Catar':                  '🇶🇦',
    'Colombia':               '🇨🇴',
    'Congo Rd':               '🇨🇩',
    'Congo RD':               '🇨🇩',
    'Corea Del Sur':          '🇰🇷',
    'Corea del Sur':          '🇰🇷',
    'Costa De Marfil':        '🇨🇮',
    'Costa de Marfil':        '🇨🇮',
    'Croacia':                '🇭🇷',
    'Curazao':                '🇨🇼',
    'Ecuador':                '🇪🇨',
    'Egipto':                 '🇪🇬',
    'Escocia':                '🏴󠁧󠁢󠁳󠁣󠁴󠁿',
    'España':                 '🇪🇸',
    'Estados Unidos':         '🇺🇸',
    'Francia':                '🇫🇷',
    'Ghana':                  '🇬🇭',
    'Haití':                  '🇭🇹',
    'Inglaterra':             '🏴󠁧󠁢󠁥󠁮󠁧󠁿',
    'Irak':                   '🇮🇶',
    'Irán':                   '🇮🇷',
    'Japón':                  '🇯🇵',
    'Jordania':               '🇯🇴',
    'Marruecos':              '🇲🇦',
    'México':                 '🇲🇽',
    'Noruega':                '🇳🇴',
    'Nueva Zelanda':          '🇳🇿',
    'Países Bajos':           '🇳🇱',
    'Panamá':                 '🇵🇦',
    'Paraguay':               '🇵🇾',
    'Portugal':               '🇵🇹',
    'República Checa':        '🇨🇿',
    'Senegal':                '🇸🇳',
    'Sudáfrica':              '🇿🇦',
    'Suecia':                 '🇸🇪',
    'Suiza':                  '🇨🇭',
    'Túnez':                  '🇹🇳',
    'Turquía':                '🇹🇷',
    'Uruguay':                '🇺🇾',
    'Uzbekistán':             '🇺🇿',
  };

  String _sectionEmoji(String type, String key) {
    if (type == 'special') return _specialEmoji[key] ?? '🃏';
    return _teamFlag[key] ?? _teamFlag[key.split(' ').map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase()).join(' ')] ?? '🏳️';
  }

  @override
  Widget build(BuildContext context) {
    final owned = section['owned_count'] as int;
    final total = section['total'] as int;
    final pct = section['completion_pct'] as double;
    final complete = owned == total && total > 0;
    final stickers = List<Map<String, dynamic>>.from(section['stickers']);
    final emoji = _sectionEmoji(section['type'], section['key']);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: complete ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: complete
            ? const BorderSide(color: Colors.amber, width: 1.5)
            : BorderSide.none,
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: complete ? Colors.amber.shade100 : Colors.grey.shade200,
          child: Text(emoji, style: const TextStyle(fontSize: 18)),
        ),
        title: Text(
          section['label'] as String,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$owned / $total  ($pct%)',
              style: TextStyle(
                fontSize: 12,
                color: complete ? Colors.amber.shade800 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 3),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: total > 0 ? owned / total : 0,
                minHeight: 4,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  complete ? Colors.amber : Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        trailing: complete
            ? const Icon(Icons.check_circle, color: Colors.amber)
            : null,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 120,
                childAspectRatio: 0.68,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              ),
              itemCount: stickers.length,
              itemBuilder: (ctx, i) => _StickerCard(sticker: stickers[i]),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sticker card
// ---------------------------------------------------------------------------
class _StickerCard extends StatelessWidget {
  final Map<String, dynamic> sticker;
  const _StickerCard({required this.sticker});

  static Color _rarityColor(String r) => switch (r) {
    'Legendary' => const Color(0xFFFFD700),
    'Epic'      => const Color(0xFF9C27B0),
    'Rare'      => const Color(0xFF1976D2),
    _           => const Color(0xFF9E9E9E),
  };

  static IconData _categoryIcon(String cat) => switch (cat) {
    'Golden Baller'    => Icons.star,
    'Top Keeper'       => Icons.sports_handball,
    'Defensive Rock'   => Icons.shield,
    'Midfield Maestro' => Icons.cached,
    'Goal Machine'     => Icons.sports_soccer,
    'Master Rookie'    => Icons.rocket_launch,
    'Fan Favourite'    => Icons.favorite,
    'Icon Card'        => Icons.diamond,
    'Team Crest'       => Icons.flag,
    'Official'         => Icons.emoji_events,
    _                  => Icons.person,
  };

  @override
  Widget build(BuildContext context) {
    final owned = sticker['owned'] as bool;
    final rarity = sticker['rarity'] as String;
    final color = _rarityColor(rarity);
    final copies = sticker['copies'] as int;

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: owned ? Colors.white : const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: owned ? color : Colors.grey.shade700,
              width: owned ? 2 : 1,
            ),
            boxShadow: owned
                ? [BoxShadow(color: color.withOpacity(0.15), blurRadius: 6)]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Rarity strip
              Container(
                height: 5,
                decoration: BoxDecoration(
                  color: owned ? color : Colors.grey.shade700,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ),
              // Card body
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: owned ? _OwnedContent(sticker: sticker, color: color) : _UnownedContent(sticker: sticker),
                ),
              ),
            ],
          ),
        ),
        // Badge de copias repetidas
        if (copies > 1)
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.orange.shade700,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'x$copies',
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }
}

class _OwnedContent extends StatelessWidget {
  final Map<String, dynamic> sticker;
  final Color color;
  const _OwnedContent({required this.sticker, required this.color});

  @override
  Widget build(BuildContext context) {
    final name = sticker['name'] as String;
    final category = sticker['category'] as String;
    final position = sticker['position'] as String?;
    final panini = sticker['panini_code'] as String?;

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Avatar placeholder con icono de categoría
        CircleAvatar(
          radius: 22,
          backgroundColor: color.withOpacity(0.15),
          child: Icon(_StickerCard._categoryIcon(category), color: color, size: 20),
        ),
        Column(
          children: [
            Text(
              name,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black87),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (position != null) ...[
              const SizedBox(height: 2),
              Text(position, style: const TextStyle(fontSize: 8, color: Colors.grey), textAlign: TextAlign.center),
            ],
          ],
        ),
        // Panini code chip
        if (panini != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '#$panini',
              style: TextStyle(fontSize: 8, color: color, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}

class _UnownedContent extends StatelessWidget {
  final Map<String, dynamic> sticker;
  const _UnownedContent({required this.sticker});

  @override
  Widget build(BuildContext context) {
    final category = sticker['category'] as String;
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: Colors.grey.shade800,
          child: Icon(
            _StickerCard._categoryIcon(category),
            color: Colors.grey.shade600,
            size: 20,
          ),
        ),
        const Text('No encontrado', style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            category,
            style: const TextStyle(fontSize: 7, color: Colors.grey),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
