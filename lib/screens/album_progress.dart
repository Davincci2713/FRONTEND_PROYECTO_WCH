import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/album_service.dart';
import '../services/auth/auth.dart';

class AlbumProgressScreen extends StatefulWidget {
  final String? initialTeam;
  const AlbumProgressScreen({super.key, this.initialTeam});
  @override
  State<AlbumProgressScreen> createState() => _AlbumProgressScreenState();
}

class _AlbumProgressScreenState extends State<AlbumProgressScreen> {
  final _service = AlbumService();
  Map<String, dynamic>? _data;
  bool _loading = true;
  String _filter = 'all';
  late String _query;

  int get _userId => AuthService().currentUserId ?? 1;

  @override
  void initState() {
    super.initState();
    _query = widget.initialTeam ?? '';
    if (widget.initialTeam != null) _filter = 'team';
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await _service.getAlbumProgress(_userId);
      if (mounted) {
        setState(() {
          _data = d;
          _loading = false;
        });
      }
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
        final hasMatch =
            label.contains(_query.toLowerCase()) ||
            (s['stickers'] as List).any(
              (st) => (st['name'] as String).toLowerCase().contains(
                _query.toLowerCase(),
              ),
            );
        if (!hasMatch) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Progreso del álbum',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF00341C),
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
                        padding: const EdgeInsets.all(24),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Stat(
                label: 'Obtenidas',
                value: '$owned',
                color: Colors.green.shade700,
              ),
              _Stat(label: 'Total', value: '$total', color: Colors.black87),
              _Stat(
                label: 'Completado',
                value: '${pct.toStringAsFixed(1)}%',
                color: const Color(0xFF00341C),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total > 0 ? owned / total : 0,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF00341C),
              ),
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
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
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
    required this.filter,
    required this.query,
    required this.onFilterChanged,
    required this.onQueryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final f in [
                ('all', 'Todos'),
                ('special', 'Especiales'),
                ('team', 'Equipos'),
              ])
                FilterChip(
                  label: Text(
                    f.$2,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: filter == f.$1 ? Colors.white : Colors.black87,
                    ),
                  ),
                  selected: filter == f.$1,
                  onSelected: (_) => onFilterChanged(f.$1),
                  backgroundColor: Colors.white,
                  selectedColor: const Color(0xFF00341C),
                  checkmarkColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                    side: BorderSide(
                      color: filter == f.$1
                          ? const Color(0xFF00341C)
                          : Colors.grey.shade300,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            onChanged: onQueryChanged,
            decoration: InputDecoration(
              hintText: 'Buscar jugador o equipo...',
              prefixIcon: Icon(
                Icons.search,
                size: 20,
                color: Colors.grey.shade500,
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
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

  Widget _buildSectionIcon(String type, String? originalFlagUrl, bool complete) {
    if (type == 'special') {
      return Icon(Icons.star,
          color: complete ? const Color(0xFF00341C) : Colors.grey.shade600, size: 20);
    }

    if (originalFlagUrl != null && originalFlagUrl.isNotEmpty) {
      final flagUrl =
          'http://localhost:5001/api/v1/proxy/image?url=${Uri.encodeComponent(originalFlagUrl)}';

      if (originalFlagUrl.endsWith('.svg')) {
        return SvgPicture.network(
          flagUrl,
          width: 20,
          height: 20,
          fit: BoxFit.contain,
          placeholderBuilder: (context) => Icon(Icons.flag,
              color: complete ? const Color(0xFF00341C) : Colors.grey.shade600, size: 20),
        );
      } else {
        return Image.network(
          flagUrl,
          width: 20,
          height: 20,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Icon(Icons.flag,
              color: complete ? const Color(0xFF00341C) : Colors.grey.shade600, size: 20),
        );
      }
    }

    return Icon(Icons.flag,
        color: complete ? const Color(0xFF00341C) : Colors.grey.shade600, size: 20);
  }

  @override
  Widget build(BuildContext context) {
    final owned = section['owned_count'] as int;
    final total = section['total'] as int;
    final pct = section['completion_pct'] as double;
    final complete = owned == total && total > 0;
    final stickers = List<Map<String, dynamic>>.from(section['stickers']);
    final flagUrl = section['flagUrl'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: complete ? const Color(0xFF00341C) : Colors.grey.shade300,
          width: complete ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: Colors.black87,
          collapsedIconColor: Colors.grey.shade600,
          leading: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: complete
                  ? const Color(0xFF00341C).withOpacity(0.1)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: _buildSectionIcon(section['type'], flagUrl, complete),
          ),
          title: Text(
            section['label'] as String,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$owned / $total',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: complete ? const Color(0xFF00341C) : Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      '${pct.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: complete ? const Color(0xFF00341C) : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: total > 0 ? owned / total : 0,
                    minHeight: 4,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      complete ? const Color(0xFF00341C) : Colors.blue.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 140,
                  childAspectRatio: 0.55,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: stickers.length,
                itemBuilder: (ctx, i) => _StickerCard(sticker: stickers[i]),
              ),
            ),
          ],
        ),
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
        'Epic' => const Color(0xFF9C27B0),
        'Rare' => const Color(0xFF1976D2),
        _ => Colors.grey.shade400,
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
            color: owned ? Colors.white : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: owned ? color : Colors.grey.shade300,
              width: owned ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Rarity strip
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: owned ? color : Colors.grey.shade300,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ),
              // Card body
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: owned
                      ? _OwnedContent(sticker: sticker, color: color)
                      : _UnownedContent(sticker: sticker),
                ),
              ),
            ],
          ),
        ),
        if (copies > 1)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'x$copies',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
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
    final position = sticker['position'] as String?;
    final panini = sticker['panini_code'] as String?;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: color.withOpacity(0.1),
          child: Icon(Icons.person, color: color, size: 20),
        ),
        const SizedBox(height: 12),
        Text(
          name,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (position != null) ...[
          const SizedBox(height: 4),
          Text(
            position,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 8),
        if (panini != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '#$panini',
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class _UnownedContent extends StatefulWidget {
  final Map<String, dynamic> sticker;
  const _UnownedContent({required this.sticker});

  @override
  State<_UnownedContent> createState() => _UnownedContentState();
}

class _UnownedContentState extends State<_UnownedContent> {
  void _showTradeDialog() {
    showDialog(
      context: context,
      builder: (_) => _TradeDialog(requestedSticker: widget.sticker),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.sticker['name'] as String? ?? 'Desconocido';
    final position = widget.sticker['position'] as String?;
    final panini = widget.sticker['panini_code'] as String?;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: Colors.grey.shade200,
          child: Icon(
            Icons.lock_outline,
            color: Colors.grey.shade400,
            size: 16,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (position != null) ...[
          const SizedBox(height: 4),
          Text(
            position,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 8),
        if (panini != null)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '#$panini',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        InkWell(
          onTap: _showTradeDialog,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF00341C).withOpacity(0.05),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF00341C).withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.swap_horiz, size: 12, color: Color(0xFF00341C)),
                const SizedBox(width: 4),
                Text(
                  'Pedir',
                  style: TextStyle(
                    fontSize: 10,
                    color: const Color(0xFF00341C),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// DIALOG DE INTERCAMBIO CON DRAG & DROP
// ══════════════════════════════════════════════════════════════════════════════
class _TradeDialog extends StatefulWidget {
  final Map<String, dynamic> requestedSticker;
  const _TradeDialog({required this.requestedSticker});
  @override
  State<_TradeDialog> createState() => _TradeDialogState();
}

class _TradeDialogState extends State<_TradeDialog> {
  final _emailCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _owned = [];
  List<Map<String, dynamic>> _filtered = [];
  List<Map<String, dynamic>> _offered = [];
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadOwned();
    _searchCtrl.addListener(_filter);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadOwned() async {
    final uid = AuthService().currentUserId ?? 1;
    try {
      final album = await AlbumService().getAlbumProgress(uid);
      final sections = album['sections'] as List? ?? [];
      final all = <Map<String, dynamic>>[];
      for (final sec in sections) {
        for (final s in (sec['stickers'] as List? ?? [])) {
          if (s['owned'] == true) all.add(Map<String, dynamic>.from(s as Map));
        }
      }
      if (mounted) setState(() { _owned = all; _filtered = all; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _filter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _owned.where((s) =>
          q.isEmpty ||
          (s['name'] as String? ?? '').toLowerCase().contains(q) ||
          (s['team'] as String? ?? '').toLowerCase().contains(q)).toList();
    });
  }

  void _addOffered(Map<String, dynamic> sticker) {
    setState(() {
      _offered.add(sticker);
      _owned.removeWhere((s) => s['id'] == sticker['id']);
      _filter();
    });
  }

  void _removeOffered(Map<String, dynamic> sticker) {
    setState(() {
      _offered.removeWhere((s) => s['id'] == sticker['id']);
      _owned.add(sticker);
      _filter();
    });
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    if (_offered.isEmpty || email.isEmpty) return;
    setState(() => _submitting = true);
    try {
      final uid = AuthService().currentUserId!;
      final requestedId = widget.requestedSticker['id'] as int;
      String? lastError;
      int sent = 0;
      for (final s in _offered) {
        final res = await AlbumService().proposeTrade(uid, email, s['id'] as int, requestedId);
        if (res['success'] == true) sent++; else lastError = res['message'] as String?;
      }
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        sent > 0
            ? SnackBar(content: Text(sent == 1 ? 'Solicitud enviada' : '$sent solicitudes enviadas'))
            : SnackBar(content: Text(lastError ?? 'Error'), backgroundColor: const Color(0xFFBB0014)),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: const Color(0xFFBB0014)));
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.requestedSticker;
    final name = s['name'] as String? ?? 'Desconocido';
    final team = s['team'] as String? ?? '';
    final rarity = s['rarity'] as String? ?? '';
    final panini = s['panini_code'] ?? s['id'];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 640),
        child: Column(
          children: [
            // ── Header fijo ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Solicitar intercambio',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
                  const SizedBox(height: 16),
                  Text('Estás pidiendo:',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  _RequestedCard(name: name, team: team, rarity: rarity, panini: panini.toString()),
                  const SizedBox(height: 16),
                  Text('¿A quién se la pides?',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'Correo de tu amigo',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('¿Qué lámina ofreces a cambio?',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  // Drop zone
                  DragTarget<Map<String, dynamic>>(
                    onAcceptWithDetails: (d) => _addOffered(d.data),
                    builder: (_, candidates, __) {
                      final hovering = candidates.isNotEmpty;
                      final hasItems = _offered.isNotEmpty;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        constraints: const BoxConstraints(minHeight: 52),
                        padding: hasItems
                            ? const EdgeInsets.symmetric(horizontal: 10, vertical: 8)
                            : EdgeInsets.zero,
                        decoration: BoxDecoration(
                          color: hovering
                              ? const Color(0xFF00341C).withOpacity(0.05)
                              : Colors.grey.shade50,
                          border: Border.all(
                            color: hovering || hasItems
                                ? const Color(0xFF00341C)
                                : Colors.grey.shade300,
                            width: hovering || hasItems ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: hasItems ? Alignment.topLeft : Alignment.center,
                        child: hasItems
                            ? Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: _offered.map((s) => Chip(
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                  backgroundColor: const Color(0xFF00341C).withOpacity(0.08),
                                  side: BorderSide(color: const Color(0xFF00341C).withOpacity(0.3)),
                                  label: Text(
                                    '${s['name']}${s['panini_code'] != null ? ' #${s['panini_code']}' : ''}',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF00341C), fontWeight: FontWeight.w600),
                                  ),
                                  deleteIcon: const Icon(Icons.close, size: 14, color: Color(0xFF00341C)),
                                  onDeleted: () => _removeOffered(s),
                                )).toList(),
                              )
                            : Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.drag_indicator, color: Colors.grey.shade400, size: 20),
                                const SizedBox(width: 6),
                                Text('Arrastra una o más láminas aquí',
                                    style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                              ]),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  // Búsqueda
                  TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre o equipo...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
            // ── Grid de láminas (scrollable) ─────────────────────────────────
            Flexible(
              child: _loading
                  ? const Center(child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator()))
                  : _filtered.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text('No tienes láminas que coincidan',
                              style: TextStyle(color: Colors.grey.shade500)))
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 0.72,
                          ),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) => _DraggableSticker(sticker: _filtered[i]),
                        ),
            ),
            // ── Acciones ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Row(children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: (_offered.isNotEmpty && !_submitting) ? _submit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00341C),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: _submitting
                        ? const SizedBox(height: 18, width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Enviar', style: TextStyle(fontWeight: FontWeight.w500)),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestedCard extends StatelessWidget {
  final String name, team, rarity, panini;
  const _RequestedCard({required this.name, required this.team, required this.rarity, required this.panini});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.grey.shade50,
      border: Border.all(color: Colors.grey.shade200),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white, shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade300)),
        child: const Icon(Icons.style, size: 20, color: Color(0xFF00341C)),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
        const SizedBox(height: 2),
        Text('$team • $rarity', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      ])),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
        child: Text('#$panini', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    ]),
  );
}

class _DraggableSticker extends StatelessWidget {
  final Map<String, dynamic> sticker;
  const _DraggableSticker({required this.sticker});

  @override
  Widget build(BuildContext context) {
    final name = sticker['name'] as String? ?? '';
    final team = sticker['team'] as String? ?? '';
    final panini = sticker['panini_code'];
    final photoUrl = sticker['photo_url'] as String?;
    final rarity = sticker['rarity'] as String? ?? '';

    final card = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (photoUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(photoUrl,
                  height: 60, width: 44, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.person, size: 28, color: Colors.grey)),
            )
          else
            const Icon(Icons.style, size: 28, color: Color(0xFF00341C)),
          const SizedBox(height: 4),
          Text(name,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          Text(team,
              style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          if (panini != null)
            Text('#$panini',
                style: TextStyle(fontSize: 9, color: Colors.grey.shade400,
                    fontWeight: FontWeight.w600)),
          if (rarity.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFF00341C).withOpacity(0.08),
                borderRadius: BorderRadius.circular(3)),
              child: Text(rarity,
                  style: const TextStyle(fontSize: 8, color: Color(0xFF00341C),
                      fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );

    return Draggable<Map<String, dynamic>>(
      data: sticker,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.9,
          child: SizedBox(width: 90, height: 115, child: card),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: card),
      child: card,
    );
  }
}
