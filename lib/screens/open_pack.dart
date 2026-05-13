import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend_proyecto/utils/theme.dart';

class Sticker {
  final String id;
  final String name;
  final String country;
  final String rarity; // 'common' | 'rare' | 'legendary'
  final bool isNew;
  final bool isRepeated;

  const Sticker({
    required this.id,
    required this.name,
    required this.country,
    required this.rarity,
    required this.isNew,
    this.isRepeated = false,
  });

  bool get isSpecial => rarity == 'legendary';
}

class OpenPackScreen extends StatefulWidget {
  const OpenPackScreen({super.key});

  @override
  State<OpenPackScreen> createState() => _OpenPackScreenState();
}

enum _PackPhase { idle, opening, revealing, done }

class _OpenPackScreenState extends State<OpenPackScreen>
    with TickerProviderStateMixin {
  _PackPhase _phase = _PackPhase.idle;

  late AnimationController _shakeCtrl;
  late AnimationController _openCtrl;
  late Animation<double> _openAnim;

  final List<Sticker> _stickers = const [
    Sticker(id: '1', name: 'L. Messi', country: 'Argentina', rarity: 'legendary', isNew: true),
    Sticker(id: '2', name: 'A. Davies', country: 'Canadá', rarity: 'rare', isNew: true),
    Sticker(id: '3', name: 'H. Lozano', country: 'México', rarity: 'common', isNew: false, isRepeated: true),
    Sticker(id: '4', name: 'C. Pulisic', country: 'USA', rarity: 'rare', isNew: true),
    Sticker(id: '5', name: 'Trofeo Oficial', country: 'Especial', rarity: 'legendary', isNew: true),
  ];

  int _revealedCount = 0;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat(reverse: true);
    _openCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _openAnim = CurvedAnimation(parent: _openCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _openCtrl.dispose();
    super.dispose();
  }

  Future<void> _tapPack() async {
    if (_phase != _PackPhase.idle) return;
    setState(() => _phase = _PackPhase.opening);
    _shakeCtrl.stop();
    await _openCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) setState(() => _phase = _PackPhase.revealing);
  }

  void _onCardRevealed() {
    if (!mounted) return;
    setState(() {
      _revealedCount++;
      if (_revealedCount >= _stickers.length) _phase = _PackPhase.done;
    });
  }

  void _resetPack() {
    setState(() {
      _phase = _PackPhase.idle;
      _revealedCount = 0;
    });
    _openCtrl.reset();
    _shakeCtrl.repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceCard,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('ABRIR SOBRE',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 15)),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/album')),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.divider),
        ),
      ),
      body: SafeArea(
        child: _phase == _PackPhase.idle || _phase == _PackPhase.opening
            ? _PackView(
                shakeCtrl: _shakeCtrl,
                openAnim: _openAnim,
                phase: _phase,
                onTap: _tapPack,
                count: _stickers.length,
              )
            : _RevealView(
                stickers: _stickers,
                phase: _phase,
                revealedCount: _revealedCount,
                onCardRevealed: _onCardRevealed,
                onReset: _resetPack,
              ),
      ),
    );
  }
}

class _PackView extends StatelessWidget {
  final AnimationController shakeCtrl;
  final Animation<double> openAnim;
  final _PackPhase phase;
  final VoidCallback onTap;
  final int count;

  const _PackView({
    required this.shakeCtrl,
    required this.openAnim,
    required this.phase,
    required this.onTap,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (phase == _PackPhase.idle)
            const Text('¡TAP PARA ABRIR!',
                style: TextStyle(
                    color: AppTheme.accentYellow,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                    fontSize: 12)),
          const SizedBox(height: 28),
          AnimatedBuilder(
            animation: Listenable.merge([shakeCtrl, openAnim]),
            builder: (context, _) {
              final shake =
                  phase == _PackPhase.idle ? sin(shakeCtrl.value * pi) * 6.0 : 0.0;
              return GestureDetector(
                onTap: onTap,
                child: Transform.translate(
                  offset: Offset(shake, 0),
                  child: SizedBox(
                    width: 190,
                    height: 270,
                    child: CustomPaint(
                        painter: _PackPainter(openProgress: openAnim.value)),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 36),
          if (phase == _PackPhase.idle)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Text('$count láminas te esperan',
                  style:
                      TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 13)),
            )
          else
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppTheme.accentYellow),
              ),
            ),
        ],
      ),
    );
  }
}

class _RevealView extends StatelessWidget {
  final List<Sticker> stickers;
  final _PackPhase phase;
  final int revealedCount;
  final VoidCallback onCardRevealed;
  final VoidCallback onReset;

  const _RevealView({
    required this.stickers,
    required this.phase,
    required this.revealedCount,
    required this.onCardRevealed,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final allDone = phase == _PackPhase.done;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('LÁMINAS OBTENIDAS',
                      style: TextStyle(
                          color: AppTheme.onSurfaceMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2)),
                  Text('$revealedCount / ${stickers.length}',
                      style: const TextStyle(
                          color: AppTheme.accentYellow,
                          fontWeight: FontWeight.w900,
                          fontSize: 14)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: revealedCount / stickers.length,
                  backgroundColor: AppTheme.surfaceElevated,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppTheme.accentYellow),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: LayoutBuilder(builder: (context, constraints) {
            if (constraints.maxWidth < 600) {
              return PageView.builder(
                itemCount: stickers.length,
                controller: PageController(viewportFraction: 0.72),
                itemBuilder: (context, i) => Center(
                  child: _FlipCard(
                    sticker: stickers[i],
                    autoDelay: Duration(milliseconds: i * 180),
                  ),
                ),
              );
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Center(
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: stickers
                      .asMap()
                      .entries
                      .map((e) => _FlipCard(
                            sticker: e.value,
                            autoDelay: Duration(milliseconds: e.key * 200),
                            onRevealed: onCardRevealed,
                          ))
                      .toList(),
                ),
              ),
            );
          }),
        ),

        AnimatedSlide(
          offset: allDone ? Offset.zero : const Offset(0, 1.5),
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutBack,
          child: AnimatedOpacity(
            opacity: allDone ? 1 : 0,
            duration: const Duration(milliseconds: 300),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: LayoutBuilder(builder: (context, constraints) {
                final wide = constraints.maxWidth > 480;
                final b1 = ElevatedButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.style, size: 16),
                  label: const Text('ABRIR OTRO',
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentYellow,
                    foregroundColor: Colors.black,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                  ),
                );
                final b2 = OutlinedButton.icon(
                  onPressed: () => context.go('/album'),
                  icon: const Icon(Icons.auto_stories, size: 16, color: Colors.white),
                  label: const Text('IR AL ÁLBUM',
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          fontSize: 12,
                          color: Colors.white)),
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    side: const BorderSide(color: AppTheme.divider),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                  ),
                );
                if (wide) {
                  return Row(children: [
                    Expanded(child: b1),
                    const SizedBox(width: 12),
                    Expanded(child: b2)
                  ]);
                }
                return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  b1,
                  const SizedBox(height: 10),
                  b2
                ]);
              }),
            ),
          ),
        ),
      ],
    );
  }
}

class _PackPainter extends CustomPainter {
  final double openProgress;
  _PackPainter({required this.openProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rr = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), const Radius.circular(12));

    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(6, 8, w, h), const Radius.circular(12)),
        Paint()
          ..color = Colors.black.withOpacity(0.45 * (1 - openProgress * 0.5))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14));

    canvas.drawRRect(
        rr,
        Paint()
          ..shader = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: const [
            Color(0xFF1a2a1a),
            Color(0xFF141414),
          ]).createShader(Rect.fromLTWH(0, 0, w, h)));

    canvas.drawRRect(
        rr,
        Paint()
          ..color = AppTheme.accentYellow.withOpacity(0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);

    final lp = Paint()
      ..color = AppTheme.accentYellow.withOpacity(0.12)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(20, h * 0.28), Offset(w - 20, h * 0.28), lp);
    canvas.drawLine(Offset(20, h * 0.72), Offset(w - 20, h * 0.72), lp);

    canvas.drawCircle(Offset(w / 2, h / 2),
        34 * (1 - openProgress * 0.6),
        Paint()..color = AppTheme.accentYellow.withOpacity(0.18 * (1 - openProgress)));

    if (openProgress < 0.8) {
      final tp = TextPainter(
        text: TextSpan(
            text: 'MUNDIAL\n2026',
            style: TextStyle(
                color: AppTheme.accentYellow.withOpacity((1 - openProgress * 1.2).clamp(0, 1)),
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
                height: 1.4)),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      tp.layout(maxWidth: w);
      tp.paint(canvas, Offset((w - tp.width) / 2, h * 0.53));
    }

    if (openProgress > 0) {
      final tearY = h * (0.30 + openProgress * 0.06);
      final path = Path()..moveTo(0, 0);
      double x = 0;
      while (x <= w) {
        path.lineTo(x + 10, tearY - 7 * openProgress);
        path.lineTo(x + 20, tearY + 3 * openProgress);
        x += 20;
      }
      path.lineTo(w, 0);
      path.close();
      canvas.drawPath(path, Paint()..color = AppTheme.surface);

      final glow = Path()..moveTo(0, tearY);
      x = 0;
      while (x <= w) {
        glow.lineTo(x + 10, tearY - 7 * openProgress);
        glow.lineTo(x + 20, tearY + 3 * openProgress);
        x += 20;
      }
      canvas.drawPath(
          glow,
          Paint()
            ..color = AppTheme.accentYellow.withOpacity(openProgress * 0.9)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5
            ..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(_PackPainter old) => old.openProgress != openProgress;
}

class _FlipCard extends StatefulWidget {
  final Sticker sticker;
  final Duration autoDelay;
  final VoidCallback? onRevealed;

  const _FlipCard({required this.sticker, required this.autoDelay, this.onRevealed});

  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _anim = Tween<double>(begin: 0, end: pi)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _anim.addListener(() {
      if (_anim.value >= pi / 2 && !_revealed) {
        setState(() => _revealed = true);
        widget.onRevealed?.call();
      }
    });
    Future.delayed(widget.autoDelay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final showBack = _anim.value < pi / 2;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(_anim.value),
          child: showBack ? _buildBack() : _buildFront(),
        );
      },
    );
  }

  Widget _buildBack() => _CardFrame(
        width: 148,
        height: 208,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF001a0e), Color(0xFF0a1020)],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.style, color: AppTheme.accentYellow.withOpacity(0.55), size: 44),
              const SizedBox(height: 10),
              Text('TAP PARA\nREVELAR',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppTheme.accentYellow.withOpacity(0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      height: 1.5)),
            ],
          ),
        ),
      );

  Widget _buildFront() {
    final s = widget.sticker;
    final rc = s.rarity == 'legendary'
        ? AppTheme.accentYellow
        : s.rarity == 'rare'
            ? AppTheme.accentBlue
            : AppTheme.onSurfaceMuted;

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..rotateY(pi),
      child: _CardFrame(
        width: 148,
        height: 208,
        glowColor: s.isSpecial ? AppTheme.accentYellow : null,
        borderColor: s.isSpecial
            ? AppTheme.accentYellow
            : s.isRepeated
                ? AppTheme.onSurfaceMuted.withOpacity(0.3)
                : AppTheme.accentBlue.withOpacity(0.45),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: s.isSpecial
                        ? [const Color(0xFF2a2000), AppTheme.surfaceCard]
                        : [const Color(0xFF0a1020), AppTheme.surfaceCard],
                  ),
                ),
                child: Stack(children: [
                  Center(
                      child: Icon(
                    s.isSpecial ? Icons.emoji_events : Icons.person,
                    size: 50,
                    color: rc.withOpacity(0.45),
                  )),
                  Positioned(
                    top: 5,
                    right: 5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      color: rc.withOpacity(0.2),
                      child: Text(s.rarity.toUpperCase(),
                          style: TextStyle(
                              color: rc, fontSize: 7, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    ),
                  ),
                  if (s.isNew)
                    Positioned(
                      top: 5,
                      left: 5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        color: AppTheme.accentBlue,
                        child: const Text('NUEVA',
                            style: TextStyle(
                                color: Colors.white, fontSize: 7, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      ),
                    ),
                  if (s.isRepeated)
                    Positioned(
                      top: 5,
                      left: 5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        color: AppTheme.surfaceElevated,
                        child: Text('REPETIDA',
                            style: TextStyle(
                                color: AppTheme.onSurfaceMuted,
                                fontSize: 7,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1)),
                      ),
                    ),
                  if (s.isSpecial)
                    const Positioned(
                        bottom: 5,
                        right: 5,
                        child: Icon(Icons.stars, color: AppTheme.accentYellow, size: 16)),
                ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(9),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.name,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(s.country,
                    style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 10)),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardFrame extends StatelessWidget {
  final Widget child;
  final double width;
  final double height;
  final Color? glowColor;
  final Color? borderColor;

  const _CardFrame(
      {required this.child,
      required this.width,
      required this.height,
      this.glowColor,
      this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: borderColor ?? AppTheme.divider, width: glowColor != null ? 2 : 1),
        boxShadow: glowColor != null
            ? [BoxShadow(color: glowColor!.withOpacity(0.45), blurRadius: 18, spreadRadius: 2)]
            : [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8)],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(10), child: child),
    );
  }
}
