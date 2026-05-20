import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:frontend_proyecto/providers/theme_provider.dart';
import 'package:frontend_proyecto/utils/theme.dart';
import '../services/album_service.dart';
import '../services/auth/auth.dart';
import '../config.dart';

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
    context.watch<ThemeProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'PROGRESO DEL ÁLBUM',
          style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -1),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.inverseSurface,
        elevation: 0,
        shape: Border(bottom: BorderSide(color: AppColors.onPrimary, width: 2)),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _data == null
              ? Center(child: Text('ERROR CARGANDO EL ÁLBUM', style: GoogleFonts.spaceGrotesk(color: AppColors.text)))
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
        color: AppColors.primary,
        border: Border(bottom: BorderSide(color: AppColors.onPrimary, width: 2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Stat(
                label: 'OBTENIDAS',
                value: '$owned',
                color: AppColors.onPrimary,
              ),
              _Stat(label: 'TOTAL', value: '$total', color: AppColors.border),
              _Stat(
                label: 'COMPLETADO',
                value: '${pct.toStringAsFixed(1)}%',
                color: AppColors.onPrimary,
              ),
            ],
          ),
          SizedBox(height: 32),
          Container(
            height: 16,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: total > 0 ? owned / total : 0,
              child: Container(color: Colors.black),
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
            style: GoogleFonts.spaceGrotesk(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: -1,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 10,
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final f in [
                ('all', 'TODOS'),
                ('special', 'ESPECIALES'),
                ('team', 'EQUIPOS'),
              ])
                GestureDetector(
                  onTap: () => onFilterChanged(f.$1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: filter == f.$1 ? AppColors.primary : Colors.transparent,
                      border: Border.all(
                        color: filter == f.$1 ? AppColors.primary : AppColors.border,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      f.$2,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: filter == f.$1 ? Colors.black : AppColors.textMuted,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 24),
          TextField(
            onChanged: onQueryChanged,
            style: GoogleFonts.dmSans(color: AppColors.text, fontSize: 16),
            cursorColor: AppColors.primary,
            decoration: InputDecoration(
              hintText: 'BUSCAR JUGADOR O EQUIPO...',
              hintStyle: GoogleFonts.dmSans(color: AppColors.border, fontSize: 14),
              prefixIcon: Icon(Icons.search, size: 20, color: AppColors.textMuted),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              filled: true,
              fillColor: Colors.transparent,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: AppColors.border, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: AppColors.border, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: AppColors.primary, width: 2),
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
    final color = complete ? Colors.black : AppColors.textMuted;
    if (type == 'special') {
      return Icon(Icons.star, color: color, size: 24);
    }

    if (originalFlagUrl != null && originalFlagUrl.isNotEmpty) {
      final flagUrl = '$kBaseUrl/proxy/image?url=${Uri.encodeComponent(originalFlagUrl)}';

      if (originalFlagUrl.endsWith('.svg')) {
        return SvgPicture.network(
          flagUrl, width: 24, height: 24, fit: BoxFit.contain,
          placeholderBuilder: (context) => Icon(Icons.flag, color: color, size: 24),
        );
      } else {
        return Image.network(
          flagUrl, width: 24, height: 24, fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Icon(Icons.flag, color: color, size: 24),
        );
      }
    }

    return Icon(Icons.flag, color: color, size: 24);
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
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(
          color: complete ? AppColors.primary : AppColors.border,
          width: 2,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: AppColors.text,
          collapsedIconColor: AppColors.textMuted,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: complete ? AppColors.primary : Colors.transparent,
              border: Border.all(color: complete ? Colors.black : AppColors.border, width: 2),
            ),
            child: _buildSectionIcon(section['type'], flagUrl, complete),
          ),
          title: Text(
            (section['label'] as String).toUpperCase(),
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: AppColors.text,
              letterSpacing: -0.5,
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
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: complete ? AppColors.primary : AppColors.textMuted,
                      ),
                    ),
                    Text(
                      '${pct.toStringAsFixed(0)}%',
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: complete ? AppColors.primary : AppColors.textMuted,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: total > 0 ? owned / total : 0,
                    child: Container(color: complete ? AppColors.primary : const Color(0xFF00FFFF)),
                  ),
                ),
              ],
            ),
          ),
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border, width: 2)),
              ),
              padding: const EdgeInsets.all(24),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 140,
                  childAspectRatio: 0.55,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
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
        'Legendary' => const Color(0xFFFFD700), // Yellow
        'Epic' => const Color(0xFFFF00FF), // Magenta
        'Rare' => const Color(0xFF00FFFF), // Cyan
        _ => AppColors.text,
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
            color: owned ? AppColors.surface : Colors.transparent,
            border: Border.all(
              color: owned ? color : AppColors.border,
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Rarity strip
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: owned ? color : AppColors.border,
                ),
              ),
              // Card body
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
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
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                border: Border.all(color: AppColors.onPrimary, width: 2),
              ),
              child: Text(
                'X$copies',
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.onPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
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
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            border: Border.all(color: color, width: 2),
          ),
          child: Icon(Icons.person, color: color, size: 24),
        ),
        SizedBox(height: 16),
        Text(
          name.toUpperCase(),
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: AppColors.text,
            height: 1.1,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (position != null) ...[
          SizedBox(height: 4),
          Text(
            position.toUpperCase(),
            style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
        const Spacer(),
        if (panini != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color,
            ),
            child: Text(
              '#$panini',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                color: AppColors.onPrimary,
                fontWeight: FontWeight.w900,
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
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(color: AppColors.border, width: 2),
          ),
          child: Icon(
            Icons.lock_outline,
            color: AppColors.border,
            size: 20,
          ),
        ),
        SizedBox(height: 12),
        Text(
          name.toUpperCase(),
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: AppColors.textMuted,
            height: 1.1,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (position != null) ...[
          SizedBox(height: 4),
          Text(
            position.toUpperCase(),
            style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.border, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
        const Spacer(),
        if (panini != null)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Text(
              '#$panini',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        InkWell(
          onTap: _showTradeDialog,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(color: AppColors.accentText, width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.swap_horiz, size: 16, color: AppColors.accentText),
                SizedBox(width: 8),
                Text(
                  'PEDIR',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    color: AppColors.accentText,
                    fontWeight: FontWeight.w900,
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
  final List<Map<String, dynamic>> _offered = [];
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
      final offeredIds = _offered.map((s) => s['id'] as int).toList();
      final res = await AlbumService().proposeTrade(uid, email, offeredIds, requestedId);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        res['success'] == true
            ? SnackBar(content: Text('SOLICITUD ENVIADA', style: GoogleFonts.dmSans(color: AppColors.onPrimary, fontWeight: FontWeight.bold)), backgroundColor: AppColors.primary)
            : SnackBar(content: Text((res['message'] as String? ?? 'ERROR').toUpperCase(), style: GoogleFonts.dmSans(color: AppColors.onPrimary, fontWeight: FontWeight.bold)), backgroundColor: AppColors.error),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().toUpperCase(), style: GoogleFonts.dmSans(color: AppColors.onPrimary, fontWeight: FontWeight.bold)), backgroundColor: AppColors.error));
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
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: AppColors.border, width: 2)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 800),
        child: Column(
          children: [
            // ── Header fijo ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SOLICITAR INTERCAMBIO',
                      style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, fontSize: 24, color: AppColors.text, letterSpacing: -1)),
                  SizedBox(height: 24),
                  Text('ESTÁS PIDIENDO:',
                      style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  SizedBox(height: 8),
                  _RequestedCard(name: name, team: team, rarity: rarity, panini: panini.toString()),
                  SizedBox(height: 24),
                  Text('¿A QUIÉN SE LA PIDES?',
                      style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  SizedBox(height: 8),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.dmSans(color: AppColors.text, fontSize: 16),
                    cursorColor: AppColors.primary,
                    decoration: InputDecoration(
                      hintText: 'CORREO DE TU AMIGO',
                      hintStyle: GoogleFonts.dmSans(color: AppColors.border),
                      filled: true,
                      fillColor: Colors.transparent,
                      border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.border, width: 2)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.border, width: 2)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.primary, width: 2)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                  SizedBox(height: 24),
                  Text('¿QUÉ LÁMINA OFRECES A CAMBIO?',
                      style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  SizedBox(height: 8),
                  // Drop zone
                  DragTarget<Map<String, dynamic>>(
                    onAcceptWithDetails: (d) => _addOffered(d.data),
                    builder: (_, candidates, __) {
                      final hovering = candidates.isNotEmpty;
                      final hasItems = _offered.isNotEmpty;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        constraints: const BoxConstraints(minHeight: 64),
                        padding: hasItems
                            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
                            : EdgeInsets.zero,
                        decoration: BoxDecoration(
                          color: hovering
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : Colors.transparent,
                          border: Border.all(
                            color: hovering || hasItems
                                ? AppColors.primary
                                : AppColors.border,
                            width: 2,
                          ),
                        ),
                        alignment: hasItems ? Alignment.topLeft : Alignment.center,
                        child: hasItems
                            ? Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _offered.map((s) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    border: Border.all(color: AppColors.accentText, width: 2),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${s['name']}${s['panini_code'] != null ? ' #${s['panini_code']}' : ''}'.toUpperCase(),
                                        style: GoogleFonts.spaceGrotesk(fontSize: 12, color: AppColors.text, fontWeight: FontWeight.w900),
                                      ),
                                      SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () => _removeOffered(s),
                                        child: Icon(Icons.close, size: 16, color: AppColors.accentText),
                                      ),
                                    ],
                                  ),
                                )).toList(),
                              )
                            : Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.drag_indicator, color: AppColors.textMuted, size: 24),
                                SizedBox(width: 8),
                                Text('ARRASTRA UNA O MÁS LÁMINAS AQUÍ',
                                    style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                              ]),
                      );
                    },
                  ),
                  SizedBox(height: 16),
                  // Búsqueda
                  TextField(
                    controller: _searchCtrl,
                    style: GoogleFonts.dmSans(color: AppColors.text, fontSize: 14),
                    cursorColor: AppColors.primary,
                    decoration: InputDecoration(
                      hintText: 'BUSCAR POR NOMBRE O EQUIPO...',
                      hintStyle: GoogleFonts.dmSans(color: AppColors.border),
                      prefixIcon: Icon(Icons.search, size: 20, color: AppColors.textMuted),
                      filled: true,
                      fillColor: Colors.transparent,
                      border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.border, width: 2)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.border, width: 2)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.primary, width: 2)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ),
            // ── Grid de láminas (scrollable) ─────────────────────────────────
            Flexible(
              child: _loading
                  ? Center(child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(color: AppColors.primary)))
                  : _filtered.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(48),
                          child: Text('NO TIENES LÁMINAS QUE COINCIDAN',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.spaceGrotesk(color: AppColors.textMuted, fontWeight: FontWeight.w900, fontSize: 16)))
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.55,
                          ),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) => _DraggableSticker(sticker: _filtered[i]),
                        ),
            ),
            // ── Acciones ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.text,
                      side: BorderSide(color: AppColors.border, width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                    ),
                    child: Text('CANCELAR', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900)),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: (_offered.isNotEmpty && !_submitting) ? _submit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                    ),
                    child: _submitting
                        ? SizedBox(height: 20, width: 20,
                            child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.onPrimary))
                        : Text('ENVIAR', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900)),
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
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.transparent,
      border: Border.all(color: AppColors.border, width: 2),
    ),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primary,
          border: Border.all(color: AppColors.onPrimary, width: 2)),
        child: Icon(Icons.style_rounded, size: 24, color: AppColors.onPrimary),
      ),
      SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name.toUpperCase(), style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.text, letterSpacing: -0.5)),
        SizedBox(height: 4),
        Text('$team • $rarity'.toUpperCase(), style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
      ])),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: AppColors.surfaceVariant, border: Border.all(color: AppColors.border, width: 1)),
        child: Text('#$panini', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.text)),
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
        color: AppColors.surface,
        border: Border.all(color: AppColors.border, width: 2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (photoUrl != null)
            Container(
              decoration: BoxDecoration(border: Border.all(color: AppColors.border, width: 2)),
              child: Image.network(photoUrl,
                  height: 60, width: 44, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: AppColors.borderLight, width: 44, height: 60, child: Icon(Icons.person, size: 28, color: AppColors.textMuted))),
            )
          else
            Container(width: 44, height: 60, decoration: BoxDecoration(border: Border.all(color: AppColors.border, width: 2)), child: Icon(Icons.style, size: 28, color: AppColors.textMuted)),
          SizedBox(height: 12),
          Text(name.toUpperCase(),
              style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.text, height: 1.1),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          SizedBox(height: 4),
          Text(team.toUpperCase(),
              style: GoogleFonts.dmSans(fontSize: 8, color: AppColors.textMuted, fontWeight: FontWeight.bold),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const Spacer(),
          if (panini != null)
            Text('#$panini',
                style: GoogleFonts.spaceGrotesk(fontSize: 12, color: AppColors.text, fontWeight: FontWeight.w900)),
          if (rarity.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.borderLight),
              child: Text(rarity.toUpperCase(),
                  style: GoogleFonts.spaceGrotesk(fontSize: 8, color: AppColors.text, fontWeight: FontWeight.w900)),
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
          child: SizedBox(width: 100, height: 140, child: card),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: card),
      child: card,
    );
  }
}
