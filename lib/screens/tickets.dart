import 'package:flutter/material.dart';
import '../services/ticket_service.dart';
import '../services/auth/auth.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  final TicketService _ticketService = TicketService();
  List<dynamic> _tickets = [];
  bool _isLoading = true;

  int get _currentUserId => AuthService().currentUserId ?? 1;

  @override
  void initState() {
    super.initState();
    _fetchTickets();
  }

  Future<void> _fetchTickets() async {
    try {
      final data = await _ticketService.getUserTickets(_currentUserId);
      setState(() {
        _tickets = data;
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
    
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 48, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mis Entradas', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 24),
          
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_tickets.isEmpty)
            const Center(child: Text("No tienes entradas adquiridas."))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _tickets.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                return _buildTicketCard(context, _tickets[index]);
              },
            ),
            
          const SizedBox(height: 32),
          Center(
            child: ElevatedButton(
              onPressed: () {},
              child: const Text('Comprar Nuevas Entradas'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(BuildContext context, dynamic ticket) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 10,
              decoration: BoxDecoration(
                color: ticket['status'] == 'Pagada' ? Colors.green : const Color(0xFF00341C),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PARTIDO ${ticket['matchId'] ?? ''} - ${ticket['status']?.toUpperCase() ?? ''}', style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(ticket['match_details'] ?? 'Partido', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(ticket['stadium'] ?? 'Estadio por confirmar', style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(ticket['date_display'] ?? 'Fecha por confirmar', style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: Colors.grey[200]!, width: 2, style: BorderStyle.none)),
              ),
              child: const Center(
                child: Icon(Icons.qr_code, size: 64),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
