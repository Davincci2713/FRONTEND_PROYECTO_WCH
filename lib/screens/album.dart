import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/album_provider.dart';
import '../utils/theme.dart';
import '../config.dart';

class AlbumScreen extends StatefulWidget {
  const AlbumScreen({super.key});

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  static String get _proxyBase => '$kBaseUrl/proxy/image?url=';

  static Widget _buildFlag(String? rawUrl, {double size = 40}) {
    if (rawUrl == null || rawUrl.isEmpty) {
      return Icon(Icons.flag, size: size, color: AppColors.border);
    }
    final url = '$_proxyBase${Uri.encodeComponent(rawUrl)}';
    if (rawUrl.endsWith('.svg')) {
      return SvgPicture.network(
        url, width: size, height: size, fit: BoxFit.contain,
        placeholderBuilder: (_) =>
            Icon(Icons.flag, size: size, color: AppColors.border),
      );
    }
    return Image.network(
      url, width: size, height: size, fit: BoxFit.contain,
      errorBuilder: (_, __, ___) =>
          Icon(Icons.flag, size: size, color: AppColors.border),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AlbumProvider>().fetchAlbum();
    });
  }

  @override
  Widget build(BuildContext context) {
    final albumProvider = context.watch<AlbumProvider>();

    if (albumProvider.isLoading) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
          SizedBox(height: 16),
          Text('CARGANDO COLECCIÓN...', style: GoogleFonts.dmSans(color: AppColors.textMuted, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ]),
      );
    }

    if (albumProvider.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(border: Border.all(color: AppColors.error, width: 2)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
              SizedBox(height: 12),
              Text('ERROR AL CARGAR', style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.text)),
              SizedBox(height: 8),
              Text(albumProvider.errorMessage!, textAlign: TextAlign.center, style: GoogleFonts.dmSans(color: AppColors.textMuted)),
            ]),
          ),
        ),
      );
    }

    final albumData = albumProvider.albumData;
    if (albumData == null) {
      return Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final collections = albumData['collections'] as List<dynamic>? ?? [];
    final pct = (albumData['completion_percentage'] as num?)?.toDouble() ?? 0.0;
    final totalStickers = albumData['total_owned'] ?? albumData['total_stickers'] ?? 0;
    final maxStickers   = albumData['total_unique'] ?? albumData['max_stickers'] ?? 0;
    final repeated      = albumData['repeated_stickers'] ?? 0;
    final packBalance   = albumData['pack_balance'] ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Hero header ────────────────────────────────────────────────
          _AlbumHero(pct: pct, packBalance: packBalance, onOpenPack: () => context.go('/open-pack')),

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Stats row ────────────────────────────────────────────
                LayoutBuilder(builder: (context, constraints) {
                  final formattedPct = '${pct.toStringAsFixed(1)}%';
                  if (constraints.maxWidth > 600) {
                    return Row(children: [
                      Expanded(child: _AlbumStatCard(
                        icon: Icons.check_circle_outline,
                        label: 'COMPLETADO',
                        value: formattedPct,
                        color: AppColors.primary,
                      )),
                      SizedBox(width: 16),
                      Expanded(child: _AlbumStatCard(
                        icon: Icons.style_rounded,
                        label: 'LÁMINAS',
                        value: '$totalStickers/$maxStickers',
                        color: const Color(0xFF00FFFF), // Cyan
                      )),
                      SizedBox(width: 16),
                      Expanded(child: _AlbumStatCard(
                        icon: Icons.copy_rounded,
                        label: 'REPETIDAS',
                        value: '$repeated',
                        color: const Color(0xFFFF00FF), // Magenta
                      )),
                    ]);
                  }
                  return Column(children: [
                    _AlbumStatCard(icon: Icons.check_circle_outline, label: 'COMPLETADO', value: formattedPct, color: AppColors.primary),
                    SizedBox(height: 16),
                    _AlbumStatCard(icon: Icons.style_rounded, label: 'LÁMINAS', value: '$totalStickers/$maxStickers', color: const Color(0xFF00FFFF)),
                    SizedBox(height: 16),
                    _AlbumStatCard(icon: Icons.copy_rounded, label: 'REPETIDAS', value: '$repeated', color: const Color(0xFFFF00FF)),
                  ]);
                }),

                SizedBox(height: 32),

                // ── Actions ──────────────────────────────────────────────
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/album-progress'),
                      icon: Icon(Icons.grid_view_rounded, size: 20),
                      label: Text('VER PROGRESO'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.go('/open-pack'),
                      icon: Icon(Icons.style_rounded, size: 20),
                      label: Text('ABRIR SOBRE'),
                    ),
                  ),
                ]),

                SizedBox(height: 48),

                // ── Collections header ───────────────────────────────────
                Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('COLECCIONES.', style: GoogleFonts.spaceGrotesk(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.text, letterSpacing: -1)),
                      SizedBox(height: 4),
                      Text('${collections.length} EQUIPOS • TOCA PARA VER DETALLE',
                          style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ]),
                  ),
                ]),
                SizedBox(height: 24),

                // ── Collections grid ─────────────────────────────────────
                if (collections.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(color: AppColors.border, width: 2),
                    ),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.book_outlined, size: 48, color: AppColors.border),
                      SizedBox(height: 16),
                      Text('ABRE SOBRES PARA EMPEZAR',
                          style: GoogleFonts.dmSans(color: AppColors.textMuted, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ]),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 180,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: collections.length,
                    itemBuilder: (ctx, i) {
                      final col      = collections[i];
                      final teamName = col['name'] as String? ?? '';
                      final count    = col['count'] as int? ?? 0;
                      final flagUrl  = col['flagUrl'] as String?;
                      return _TeamCard(
                        teamName: teamName,
                        count: count,
                        flagUrl: flagUrl,
                        onTap: () => context.push('/album-progress', extra: teamName),
                        buildFlag: (url, size) => _buildFlag(url, size: size),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}

// ── Album hero with circular progress ────────────────────────────────────────
class _AlbumHero extends StatelessWidget {
  final double pct;
  final int packBalance;
  final VoidCallback onOpenPack;
  const _AlbumHero({required this.pct, required this.packBalance, required this.onOpenPack});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 48),
      decoration: BoxDecoration(
        color: AppColors.primary,
        border: Border(bottom: BorderSide(color: AppColors.onPrimary, width: 2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MI ÁLBUM.', style: GoogleFonts.spaceGrotesk(fontSize: 48, height: 0.9, color: AppColors.onPrimary, fontWeight: FontWeight.w900, letterSpacing: -2)),
                SizedBox(height: 8),
                Text('FIFA WORLD CUP 2026', style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)),
                SizedBox(height: 32),
                if (packBalance > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.onPrimary,
                      border: Border.all(color: AppColors.onPrimary, width: 2),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.inventory_2_rounded, color: AppColors.primary, size: 16),
                      SizedBox(width: 12),
                      Text('$packBalance SOBRE${packBalance > 1 ? 'S' : ''} DISPONIBLE${packBalance > 1 ? 'S' : ''}',
                          style: GoogleFonts.dmSans(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    ]),
                  ),
              ],
            ),
          ),
          // Circular progress — Negro sobre lima: ratio 19.5:1 (WCAG AAA)
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 110,
                  height: 110,
                  child: CircularProgressIndicator(
                    value: pct / 100,
                    strokeWidth: 12,
                    backgroundColor: Colors.black.withOpacity(0.18),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                ),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('${pct.toStringAsFixed(0)}%',
                      style: GoogleFonts.spaceGrotesk(color: Colors.black, fontSize: 22, fontWeight: FontWeight.w900)),
                  Text('LISTO', style: GoogleFonts.dmSans(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat card ─────────────────────────────────────────────────────────────────
class _AlbumStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _AlbumStatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
            ),
            child: Icon(icon, color: AppColors.onPrimary, size: 24),
          ),
          SizedBox(height: 24),
          Text(value, style: GoogleFonts.spaceGrotesk(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.text, letterSpacing: -1)),
          SizedBox(height: 4),
          Text(label, style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

// ── Team collection card ──────────────────────────────────────────────────────
class _TeamCard extends StatefulWidget {
  final String teamName;
  final int count;
  final String? flagUrl;
  final VoidCallback onTap;
  final Widget Function(String?, double) buildFlag;
  const _TeamCard({required this.teamName, required this.count, this.flagUrl, required this.onTap, required this.buildFlag});
  @override
  State<_TeamCard> createState() => _TeamCardState();
}

class _TeamCardState extends State<_TeamCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1, end: 0.95).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(color: AppColors.border, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  color: AppColors.surface,
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    widget.buildFlag(widget.flagUrl, 48),
                    SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                      ),
                      child: Text(
                        '${widget.count} CARTAS',
                        style: GoogleFonts.spaceGrotesk(fontSize: 12, color: AppColors.onPrimary, fontWeight: FontWeight.w900, letterSpacing: 1),
                      ),
                    ),
                  ]),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.border, width: 2)),
                ),
                child: Text(
                  widget.teamName.toUpperCase(),
                  style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.text),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
