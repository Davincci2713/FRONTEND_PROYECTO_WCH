import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/album_provider.dart';
import '../providers/theme_provider.dart';
import '../services/album_service.dart';
import '../services/auth/auth.dart';
import '../utils/theme.dart';

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
      if (mounted) {
        setState(() {
          _packBalance = (data['pack_balance'] as num?)?.toInt() ?? 0;
          _loadingInfo = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingInfo = false);
    }
  }

  Future<void> _openPack() async {
    final uid = _uid;
    if (uid == null) {
      setState(() => _error = 'DEBES INICIAR SESIÓN PARA ABRIR SOBRES.');
      return;
    }
    setState(() {
      _opening = true;
      _error = null;
    });
    try {
      final data = await context.read<AlbumProvider>().openPack();
      if (mounted) {
        setState(() {
          _stickers = data['stickers'] ?? [];
          _packsToday = (data['packs_today'] as num?)?.toInt() ?? 0;
          _packsRemaining =
              (data['packs_remaining_today'] as num?)?.toInt() ?? 0;
          _packBalance = (data['pack_balance'] as num?)?.toInt() ?? 0;
          _opening = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '').toUpperCase();
          _opening = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'ABRIR SOBRE',
          style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -1),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.inverseSurface,
        elevation: 0,
        shape: Border(bottom: BorderSide(color: AppColors.onPrimary, width: 2)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.go('/album'),
        ),
      ),
      body: _loadingInfo
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _opening == true
          ? _buildLoading()
          : _opening == false && _stickers.isNotEmpty
          ? _buildResult()
          : _buildLobby(),
    );
  }

  // ── Lobby (cinematic dark but brutalist) ───────────────────────────────────
  Widget _buildLobby() {
    final noSession = _uid == null;
    final noPacks   = _packBalance <= 0;

    return Container(
      color: AppColors.background,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Animated pack icon ─────────────────────────────────
                _PulsingPackIcon(hasPacks: !noPacks),
                SizedBox(height: 48),

                // ── Available count ────────────────────────────────────
                Text('$_packBalance',
                  style: GoogleFonts.spaceGrotesk(color: AppColors.text, fontSize: 96,
                      fontWeight: FontWeight.w900, height: 1, letterSpacing: -4)),
                SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    border: Border.all(color: AppColors.onPrimary, width: 2),
                  ),
                  child: Text('SOBRE${_packBalance != 1 ? 'S' : ''} DISPONIBLE${_packBalance != 1 ? 'S' : ''}',
                    style: GoogleFonts.dmSans(color: AppColors.onPrimary, fontSize: 12,
                        fontWeight: FontWeight.w900, letterSpacing: 2)),
                ),
                SizedBox(height: 48),

                // ── Daily quota dots ───────────────────────────────────
                _DailyQuota(used: _packsToday, total: 3),
                SizedBox(height: 48),

                // ── Error ──────────────────────────────────────────────
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      border: Border.all(color: AppColors.onPrimary, width: 2),
                    ),
                    child: Text(_error!,
                      style: GoogleFonts.dmSans(color: AppColors.text, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                      textAlign: TextAlign.center),
                  ),
                ],

                // ── Action button ──────────────────────────────────────
                if (noSession)
                  _OpenButton(label: 'INICIAR SESIÓN', onTap: () => context.go('/login'))
                else if (noPacks)
                  Opacity(opacity: 0.4,
                    child: _OpenButton(label: 'SIN SOBRES DISPONIBLES', onTap: null))
                else
                  _OpenButton(label: 'ABRIR SOBRE', onTap: _openPack, primary: true),

                if (!noPacks && !noSession) ...[
                  SizedBox(height: 24),
                  Text('$_packsRemaining SOBRE${_packsRemaining != 1 ? 'S' : ''} MÁS DISPONIBLE${_packsRemaining != 1 ? 'S' : ''} HOY',
                    style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2),
                    textAlign: TextAlign.center),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() => Container(
    color: AppColors.background,
    child: Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        SizedBox(
          width: 60, height: 60,
          child: CircularProgressIndicator(
            strokeWidth: 4, color: AppColors.primary,
            backgroundColor: AppColors.borderLight,
          ),
        ),
        SizedBox(height: 32),
        Text('ABRIENDO SOBRE...', style: GoogleFonts.spaceGrotesk(color: AppColors.text, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -1)),
      ]),
    ),
  );

  // ── Sticker reveal ────────────────────────────────────────────────────────
  Widget _buildResult() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              color: AppColors.primary,
              border: Border.all(color: AppColors.onPrimary, width: 2),
            ),
            child: Column(children: [
              Text('¡${_stickers.length} LÁMINAS!',
                style: GoogleFonts.spaceGrotesk(color: AppColors.onPrimary, fontSize: 40,
                    fontWeight: FontWeight.w900, letterSpacing: -2)),
              SizedBox(height: 8),
              Text('$_packsRemaining SOBRE${_packsRemaining != 1 ? 'S' : ''} MÁS DISPONIBLE${_packsRemaining != 1 ? 'S' : ''} HOY',
                style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            ]),
          ),
          SizedBox(height: 48),

          // Sticker cards with staggered animation
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: _stickers.asMap().entries.map((e) =>
              _AnimatedStickerCard(sticker: e.value, index: e.key)
            ).toList(),
          ),
          SizedBox(height: 64),

          // Actions
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (_packsRemaining > 0 && _packBalance > 0)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _openPack,
                  icon: Icon(Icons.style_rounded, size: 20),
                  label: Text('ABRIR OTRO'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20)),
                ),
              ),
            if (_packsRemaining > 0 && _packBalance > 0)
              SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.go('/album'),
                icon: Icon(Icons.auto_stories_rounded, size: 20),
                label: Text('VER ÁLBUM'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20)),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

// ── Pulsing pack icon ─────────────────────────────────────────────────────────
class _PulsingPackIcon extends StatefulWidget {
  final bool hasPacks;
  const _PulsingPackIcon({required this.hasPacks});
  @override
  State<_PulsingPackIcon> createState() => _PulsingPackIconState();
}

class _PulsingPackIconState extends State<_PulsingPackIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.95, end: 1.05).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _pulse,
      child: Container(
        width: 140, height: 140,
        decoration: BoxDecoration(
          color: widget.hasPacks ? AppColors.primary : AppColors.borderLight,
          border: Border.all(color: widget.hasPacks ? Colors.white : AppColors.border, width: 4),
        ),
        child: Center(
          child: Icon(Icons.style_rounded, size: 64,
              color: widget.hasPacks ? Colors.black : AppColors.border),
        ),
      ),
    );
  }
}

// ── Daily quota dots ──────────────────────────────────────────────────────────
class _DailyQuota extends StatelessWidget {
  final int used, total;
  const _DailyQuota({required this.used, required this.total});

  @override
  Widget build(BuildContext context) => Column(children: [
    Text('APERTURA DIARIA', style: GoogleFonts.dmSans(color: AppColors.textMuted,
        fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2.5)),
    SizedBox(height: 12),
    Row(mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) => Container(
        width: 16, height: 16,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: i < used ? AppColors.primary : Colors.transparent,
          border: Border.all(color: i < used ? AppColors.primary : AppColors.border, width: 2),
        ),
      )),
    ),
  ]);
}

// ── Open button ───────────────────────────────────────────────────────────────
class _OpenButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final bool primary;
  const _OpenButton({required this.label, required this.onTap, this.primary = false});
  @override
  State<_OpenButton> createState() => _OpenButtonState();
}

class _OpenButtonState extends State<_OpenButton> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1, end: 0.95).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => _ctrl.forward() : null,
      onTapUp: widget.onTap != null ? (_) { _ctrl.reverse(); widget.onTap!(); } : null,
      onTapCancel: widget.onTap != null ? () => _ctrl.reverse() : null,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: widget.primary ? AppColors.primary : Colors.transparent,
            border: Border.all(color: widget.primary ? AppColors.primary : AppColors.border, width: 2),
          ),
          child: Text(widget.label.toUpperCase(),
            style: GoogleFonts.spaceGrotesk(color: widget.primary ? Colors.black : AppColors.textMuted, fontSize: 20,
                fontWeight: FontWeight.w900, letterSpacing: 1),
            textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

// ── Sticker card with entrance animation ──────────────────────────────────────
class _AnimatedStickerCard extends StatefulWidget {
  final Map<String, dynamic> sticker;
  final int index;
  const _AnimatedStickerCard({required this.sticker, required this.index});
  @override
  State<_AnimatedStickerCard> createState() => _AnimatedStickerCardState();
}

class _AnimatedStickerCardState extends State<_AnimatedStickerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade, _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _fade  = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _scale = Tween<double>(begin: 0.8, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    Future.delayed(Duration(milliseconds: widget.index * 80), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _fade,
    child: ScaleTransition(scale: _scale, child: _StickerCard(sticker: widget.sticker)),
  );
}

// ── Sticker card ──────────────────────────────────────────────────────────────
class _StickerCard extends StatelessWidget {
  final Map<String, dynamic> sticker;
  const _StickerCard({required this.sticker});

  static Color _rarityColor(String r) => switch (r) {
    'Legendary' => const Color(0xFFFFCC00),
    'Epic'      => const Color(0xFFFF00FF),
    'Rare'      => const Color(0xFF00FFFF),
    _           => AppColors.text,
  };

  static Color _rarityBg(String r) => switch (r) {
    'Legendary' => const Color(0xFF332900),
    'Epic'      => const Color(0xFF330033),
    'Rare'      => const Color(0xFF003333),
    _           => AppColors.borderLight,
  };

  static String _rarityLabel(String r) => switch (r) {
    'Legendary' => 'LEGENDARIA',
    'Epic'      => 'ÉPICA',
    'Rare'      => 'RARA',
    _           => 'COMÚN',
  };

  @override
  Widget build(BuildContext context) {
    final rarity  = sticker['rarity'] as String? ?? 'Common';
    final color   = _rarityColor(rarity);
    final bg      = _rarityBg(rarity);
    final name    = sticker['name'] as String? ?? '—';
    final team    = sticker['team'] as String? ?? '—';
    final code    = sticker['paniniCode'] as String?;
    final special = rarity == 'Legendary' || rarity == 'Epic';

    return Container(
      width: 140,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: special ? color : AppColors.border, width: 2),
      ),
      child: Column(
        children: [
          // Rarity accent bar
          Container(height: 8, color: color),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 20, 12, 20),
            child: Column(
              children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(color: bg, border: Border.all(color: color, width: 2)),
                  child: Icon(Icons.person_rounded, size: 32, color: color),
                ),
                SizedBox(height: 16),
                Text(name.toUpperCase(),
                  style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.text, height: 1.1),
                  textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                SizedBox(height: 4),
                Text(team.toUpperCase(),
                  style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                  textAlign: TextAlign.center),
                SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: color),
                  child: Text(_rarityLabel(rarity),
                    style: GoogleFonts.spaceGrotesk(fontSize: 10, color: AppColors.onPrimary, fontWeight: FontWeight.w900, letterSpacing: 1)),
                ),
                if (code != null) ...[
                  SizedBox(height: 8),
                  Text('#$code', style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
