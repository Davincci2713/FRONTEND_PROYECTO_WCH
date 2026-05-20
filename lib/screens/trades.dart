import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend_proyecto/config.dart';
import 'package:frontend_proyecto/providers/theme_provider.dart';
import 'package:frontend_proyecto/services/auth/auth.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import '../utils/theme.dart';

class TradesScreen extends StatefulWidget {
  const TradesScreen({super.key});
  @override
  State<TradesScreen> createState() => _TradesScreenState();
}

class _TradesScreenState extends State<TradesScreen> {
  List<dynamic> _pending = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final uid = AuthService().currentUserId;
    if (uid == null) return;
    try {
      final r = await http.get(
        Uri.parse('$kBaseUrl/users/$uid/trades/pending'),
        headers: AuthService().getAuthHeaders(),
      );
      if (!mounted) return;
      if (r.statusCode == 200) {
        setState(() { _pending = jsonDecode(r.body); _loading = false; });
      } else {
        setState(() { _error = 'ERROR AL CARGAR INTERCAMBIOS'; _loading = false; });
      }
    } catch (_) {
      if (mounted) setState(() { _error = 'SIN CONEXIÓN'; _loading = false; });
    }
  }

  Future<void> _accept(int tradeId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: AppColors.border, width: 2)),
        title: Text('ACEPTAR INTERCAMBIO', style: GoogleFonts.spaceGrotesk(color: AppColors.text, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -1)),
        content: Text('¿CONFIRMAS EL INTERCAMBIO? LAS LÁMINAS SE INTERCAMBIARÁN INMEDIATAMENTE.', style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1, height: 1.5)),
        actionsPadding: const EdgeInsets.all(24),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(dlgCtx, false),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.text,
              side: BorderSide(color: AppColors.border, width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            child: Text('CANCELAR', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(dlgCtx, true),
            child: Text('ACEPTAR', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final r = await http.put(
        Uri.parse('$kBaseUrl/album/exchange/$tradeId/confirm'),
        headers: AuthService().getAuthHeaders(),
      );
      if (!mounted) return;
      if (r.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('¡INTERCAMBIO COMPLETADO!', style: GoogleFonts.dmSans(color: AppColors.onPrimary, fontWeight: FontWeight.bold)), backgroundColor: AppColors.primary),
        );
        _load();
      } else {
        final body = jsonDecode(r.body);
        final msg = body['message'] ?? body['error'] ?? 'Error al aceptar';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg.toString().toUpperCase(), style: GoogleFonts.dmSans(color: AppColors.onPrimary, fontWeight: FontWeight.bold)), backgroundColor: AppColors.error));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ERROR: ${e.toString().toUpperCase()}', style: GoogleFonts.dmSans(color: AppColors.onPrimary, fontWeight: FontWeight.bold)), backgroundColor: AppColors.error));
    }
  }

  Future<void> _reject(int tradeId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: AppColors.border, width: 2)),
        title: Text('RECHAZAR INTERCAMBIO', style: GoogleFonts.spaceGrotesk(color: AppColors.text, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -1)),
        content: Text('¿SEGURO QUE QUIERES RECHAZAR ESTA SOLICITUD?', style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
        actionsPadding: const EdgeInsets.all(24),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(dlgCtx, false),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.text,
              side: BorderSide(color: AppColors.border, width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            child: Text('CANCELAR', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.inverseSurface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(dlgCtx, true),
            child: Text('RECHAZAR', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final r = await http.put(
        Uri.parse('$kBaseUrl/album/exchange/$tradeId/reject'),
        headers: AuthService().getAuthHeaders(),
      );
      if (!mounted) return;
      if (r.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('SOLICITUD RECHAZADA', style: GoogleFonts.dmSans(color: AppColors.onPrimary, fontWeight: FontWeight.bold)), backgroundColor: AppColors.primary),
        );
        _load();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ERROR AL RECHAZAR', style: GoogleFonts.dmSans(color: AppColors.onPrimary, fontWeight: FontWeight.bold)), backgroundColor: AppColors.error));
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ERROR DE CONEXIÓN', style: GoogleFonts.dmSans(color: AppColors.onPrimary, fontWeight: FontWeight.bold)), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('SOLICITUDES DE INTERCAMBIO', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -1)),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        shape: Border(bottom: BorderSide(color: AppColors.onPrimary, width: 2)),
        actions: [
          IconButton(icon: Icon(Icons.refresh_rounded), onPressed: _load),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_error!, style: GoogleFonts.dmSans(color: AppColors.textMuted, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _load,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
                    child: Text('REINTENTAR', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900)),
                  ),
                ]))
              : _pending.isEmpty
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(border: Border.all(color: AppColors.border, width: 2)),
                          child: Icon(Icons.swap_horiz_rounded, size: 48, color: AppColors.textMuted),
                        ),
                        SizedBox(height: 24),
                        Text('NO TIENES SOLICITUDES PENDIENTES', style: GoogleFonts.dmSans(color: AppColors.textMuted, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ]),
                    )
                  : RefreshIndicator(
                      color: AppColors.onPrimary,
                      backgroundColor: AppColors.primary,
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(24),
                        itemCount: _pending.length,
                        separatorBuilder: (_, _) => SizedBox(height: 24),
                        itemBuilder: (_, i) => _TradeCard(
                          trade: _pending[i],
                          onAccept: () => _accept(_pending[i]['id']),
                          onReject: () => _reject(_pending[i]['id']),
                        ),
                      ),
                    ),
    );
  }
}

class _TradeCard extends StatelessWidget {
  final dynamic trade;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _TradeCard({required this.trade, required this.onAccept, required this.onReject});

  @override
  Widget build(BuildContext context) {
    final offeredList = (trade['offered_stickers'] as List<dynamic>? ?? []);
    final requested = trade['requested_sticker'];
    final proposerName = trade['proposer_name'] ?? trade['proposer_email'] ?? 'Usuario';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.onPrimary,
              border: Border(bottom: BorderSide(color: AppColors.border, width: 2)),
            ),
            child: Row(children: [
              Icon(Icons.person_rounded, size: 16, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${proposerName.toString().toUpperCase()} QUIERE INTERCAMBIAR',
                  style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.white, letterSpacing: 1),
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.accentText, border: Border.all(color: AppColors.onPrimary, width: 2)),
                            child: Text('TE OFRECE', style: GoogleFonts.spaceGrotesk(fontSize: 10, color: AppColors.inverseSurface, fontWeight: FontWeight.w900, letterSpacing: 1)),
                          ),
                          SizedBox(height: 16),
                          ...offeredList.map((s) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _StickerInfo(sticker: s as Map<String, dynamic>?, color: AppColors.accentText),
                          )),
                          if (offeredList.isEmpty)
                            _StickerInfo(sticker: null, color: AppColors.accentText),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 36),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.transparent, border: Border.all(color: AppColors.border, width: 2)),
                        child: Icon(Icons.swap_horiz_rounded, color: AppColors.text, size: 24),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: const Color(0xFF00FFFF), border: Border.all(color: AppColors.onPrimary, width: 2)),
                            child: Text('PIDE TU', style: GoogleFonts.spaceGrotesk(fontSize: 10, color: AppColors.onPrimary, fontWeight: FontWeight.w900, letterSpacing: 1)),
                          ),
                          SizedBox(height: 16),
                          _StickerInfo(sticker: requested as Map<String, dynamic>?, color: const Color(0xFF00FFFF)),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 32),
                SizedBox(
                  height: 60,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onReject,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: BorderSide(color: AppColors.error, width: 2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                          ),
                          child: Text('RECHAZAR', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900)),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onAccept,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.onPrimary,
                            side: BorderSide(color: AppColors.primary, width: 2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                            elevation: 0,
                          ),
                          child: Text('ACEPTAR', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StickerInfo extends StatelessWidget {
  final Map<String, dynamic>? sticker;
  final Color color;
  final bool compact = false;

  const _StickerInfo({required this.sticker, required this.color});

  @override
  Widget build(BuildContext context) {
    if (sticker == null) return const SizedBox.shrink();
    final imgH = compact ? 60.0 : 100.0;
    final imgW = compact ? 44.0 : 75.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (sticker!['photo_url'] != null)
          Container(
            decoration: BoxDecoration(border: Border.all(color: AppColors.border, width: 2)),
            child: Image.network(sticker!['photo_url'], height: imgH, width: imgW, fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(height: imgH, width: imgW, color: AppColors.surface,
                child: Icon(Icons.person, color: AppColors.border)),
            ),
          )
        else
          Container(height: imgH, width: imgW, decoration: BoxDecoration(
            color: AppColors.surface, border: Border.all(color: color, width: 2)),
            child: Icon(Icons.sports_soccer, color: color, size: compact ? 20 : 32),
          ),
        SizedBox(height: 8),
        Text((sticker!['name'] ?? '').toString().toUpperCase(),
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, fontSize: compact ? 11 : 14, color: AppColors.text, height: 1.1),
          textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
        SizedBox(height: 4),
        Text((sticker!['team'] ?? '').toString().toUpperCase(),
          style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }
}
