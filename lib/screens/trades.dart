import 'package:flutter/material.dart';
import 'package:frontend_proyecto/config.dart';
import 'package:frontend_proyecto/services/auth/auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
        setState(() { _error = 'Error al cargar intercambios'; _loading = false; });
      }
    } catch (_) {
      if (mounted) setState(() { _error = 'Sin conexión'; _loading = false; });
    }
  }

  Future<void> _accept(int tradeId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Aceptar intercambio'),
        content: const Text('¿Confirmas el intercambio? Las láminas se intercambiarán inmediatamente.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00341C)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Aceptar', style: TextStyle(color: Colors.white)),
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
          const SnackBar(content: Text('¡Intercambio completado!'), backgroundColor: Color(0xFF00341C)),
        );
        _load();
      } else {
        final msg = jsonDecode(r.body)['message'] ?? 'Error al aceptar';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error de conexión')));
    }
  }

  Future<void> _reject(int tradeId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rechazar intercambio'),
        content: const Text('¿Seguro que quieres rechazar esta solicitud?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Rechazar', style: TextStyle(color: Colors.white)),
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
          const SnackBar(content: Text('Solicitud rechazada')),
        );
        _load();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al rechazar')));
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error de conexión')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitudes de intercambio'),
        backgroundColor: const Color(0xFF00341C),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_error!, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: _load, child: const Text('Reintentar')),
                ]))
              : _pending.isEmpty
                  ? const Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.swap_horiz, size: 64, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('No tienes solicitudes pendientes', style: TextStyle(color: Colors.grey)),
                      ]),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _pending.length,
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
    final offered = trade['offered_sticker'];
    final requested = trade['requested_sticker'];
    final proposerName = trade['proposer_name'] ?? trade['proposer_email'] ?? 'Usuario';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.person, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '$proposerName quiere intercambiar contigo',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _StickerInfo(label: 'Te ofrece', sticker: offered, color: const Color(0xFF00341C))),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.swap_horiz, color: Colors.grey),
                ),
                Expanded(child: _StickerInfo(label: 'Pide tu', sticker: requested, color: Colors.orange.shade800)),
              ],
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  child: const Text('Rechazar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00341C),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Aceptar'),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _StickerInfo extends StatelessWidget {
  final String label;
  final dynamic sticker;
  final Color color;

  const _StickerInfo({required this.label, required this.sticker, required this.color});

  @override
  Widget build(BuildContext context) {
    if (sticker == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        if (sticker['photo_url'] != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(sticker['photo_url'], height: 70, width: 50, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(height: 70, width: 50, color: Colors.grey.shade200,
                child: const Icon(Icons.person, color: Colors.grey)),
            ),
          )
        else
          Container(height: 70, width: 50, decoration: BoxDecoration(
            color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
            child: Icon(Icons.sports_soccer, color: color, size: 28),
          ),
        const SizedBox(height: 6),
        Text(sticker['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
        Text(sticker['team'] ?? '', style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
        Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
          child: Text(sticker['rarity'] ?? '', style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
