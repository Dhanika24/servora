part of '../../main.dart';

class ServoraHeroBanner extends StatelessWidget {
  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback onPressed;
  final bool provider;
  final bool compact;

  const ServoraHeroBanner({
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onPressed,
    this.provider = false,
    this.compact = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF007D70),
            Color(0xFF005D53),
            Color(0xFF003F38),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -65,
            top: -85,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(13),
              ),
            ),
          ),
          Positioned(
            right: -40,
            bottom: -100,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(10),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(compact ? 16 : 20),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final showArtwork = constraints.maxWidth >= 270 &&
                    MediaQuery.textScalerOf(context).scale(16) <= 21;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(30),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              provider ? 'SERVORA PRO' : 'YOUR SERVICE PARTNER',
                              style: const TextStyle(
                                color: Color(0xFFD9F5EC),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          SizedBox(height: compact ? 8 : 14),
                          Text(
                            title,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: compact ? 21 : 24,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: compact ? 6 : 10),
                          Text(
                            description,
                            style: const TextStyle(
                              color: Color(0xFFE0F5ED),
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                          SizedBox(height: compact ? 12 : 18),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF005D53),
                              minimumSize: const Size(0, 48),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: onPressed,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    buttonLabel,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (showArtwork) ...[
                      const SizedBox(width: 12),
                      ExcludeSemantics(
                        child: SizedBox(
                          width: compact
                              ? (constraints.maxWidth >= 340 ? 108 : 84)
                              : (constraints.maxWidth >= 340 ? 135 : 100),
                          height: compact ? 132 : 170,
                          child: CustomPaint(
                            painter: _HeroArtworkPainter(
                              provider: provider,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroArtworkPainter extends CustomPainter {
  final bool provider;

  const _HeroArtworkPainter({required this.provider});

  Paint _fill(Color color) => Paint()..color = color;

  Paint _shade(Rect bounds, Color light, Color dark) => Paint()
    ..shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [light, dark],
    ).createShader(bounds);

  void _box(Canvas c, Rect rect, double radius, Color light, [Color? dark]) {
    c.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      dark == null ? _fill(light) : _shade(rect, light, dark),
    );
  }

  void _line(Canvas c, Offset a, Offset b, Color color, double width) {
    c.drawLine(
        a,
        b,
        Paint()
          ..color = color
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round);
  }

  void _outline(Canvas c, Path path, Color color, double width) {
    c.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 140;
    final sy = size.height / 170;
    final scale = sx < sy ? sx : sy;
    canvas.save();
    canvas.translate(
        (size.width - 140 * scale) / 2, (size.height - 170 * scale) / 2);
    canvas.scale(scale);

    const halo = Rect.fromLTWH(8, 13, 124, 124);
    canvas.drawOval(
        halo,
        Paint()
          ..shader = const RadialGradient(
            colors: [Color(0x557FE5C8), Color(0x087FE5C8)],
          ).createShader(halo));
    canvas.drawCircle(
        const Offset(70, 75),
        59,
        Paint()
          ..color = const Color(0x337FE5C8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);
    canvas.drawOval(
        const Rect.fromLTWH(11, 147, 118, 13), _fill(const Color(0x35001916)));
    _line(canvas, const Offset(16, 29), const Offset(24, 29),
        const Color(0xA0D9F5EC), 1.6);
    _line(canvas, const Offset(20, 25), const Offset(20, 33),
        const Color(0xA0D9F5EC), 1.6);
    canvas.drawCircle(
        const Offset(125, 78), 2.6, _fill(const Color(0xB0D9F5EC)));

    if (provider) {
      _drawBusiness(canvas);
    } else {
      _drawProfessional(canvas);
    }
    canvas.restore();
  }

  void _drawProfessional(Canvas c) {
    final shoulders = Path()
      ..moveTo(25, 149)
      ..lineTo(29, 113)
      ..quadraticBezierTo(31, 92, 55, 89)
      ..lineTo(83, 89)
      ..quadraticBezierTo(107, 92, 111, 113)
      ..lineTo(115, 149)
      ..close();
    c.drawPath(
        shoulders,
        _shade(const Rect.fromLTWH(25, 89, 90, 60), const Color(0xFF56C8B3),
            const Color(0xFF006A60)));
    _box(c, const Rect.fromLTWH(57, 77, 24, 26), 9, const Color(0xFFC78D68),
        const Color(0xFF9E6046));
    c.drawOval(
        const Rect.fromLTWH(43, 34, 52, 53), _fill(const Color(0xFF173C34)));
    c.drawOval(
        const Rect.fromLTWH(42, 54, 12, 16), _fill(const Color(0xFFC98C68)));
    c.drawOval(
        const Rect.fromLTWH(86, 54, 12, 16), _fill(const Color(0xFFC98C68)));
    _box(c, const Rect.fromLTWH(48, 39, 42, 49), 19, const Color(0xFFF0C3A0),
        const Color(0xFFC58B65));
    final hair = Path()
      ..moveTo(47, 47)
      ..quadraticBezierTo(48, 34, 65, 34)
      ..quadraticBezierTo(87, 32, 91, 50)
      ..lineTo(82, 47)
      ..quadraticBezierTo(66, 51, 55, 43)
      ..lineTo(49, 55)
      ..close();
    c.drawPath(hair, _fill(const Color(0xFF173C34)));
    final helmet = Path()
      ..moveTo(40, 43)
      ..quadraticBezierTo(40, 15, 69, 15)
      ..quadraticBezierTo(98, 15, 98, 43)
      ..close();
    c.drawPath(
        helmet,
        _shade(const Rect.fromLTWH(40, 15, 58, 28), const Color(0xFFFFE1A0),
            const Color(0xFFE6A02C)));
    _box(c, const Rect.fromLTWH(63, 16, 11, 27), 5, const Color(0xFFFFE7B1),
        const Color(0xFFF5BC51));
    _box(c, const Rect.fromLTWH(34, 39, 70, 8), 4, const Color(0xFFFFD16E),
        const Color(0xFFE5A12B));
    _line(c, const Offset(56, 56), const Offset(63, 55),
        const Color(0xFF624331), 1.7);
    _line(c, const Offset(75, 55), const Offset(82, 56),
        const Color(0xFF624331), 1.7);
    c.drawCircle(const Offset(60, 61), 2.1, _fill(const Color(0xFF23362D)));
    c.drawCircle(const Offset(79, 61), 2.1, _fill(const Color(0xFF23362D)));
    _outline(
        c,
        Path()
          ..moveTo(63, 73)
          ..quadraticBezierTo(69, 79, 76, 73),
        const Color(0xFF884F3A),
        2);
    final bib = Path()
      ..moveTo(48, 92)
      ..lineTo(57, 92)
      ..lineTo(60, 112)
      ..lineTo(79, 112)
      ..lineTo(83, 92)
      ..lineTo(92, 92)
      ..lineTo(96, 149)
      ..lineTo(44, 149)
      ..close();
    c.drawPath(
        bib,
        _shade(const Rect.fromLTWH(44, 92, 52, 57), const Color(0xFF146D62),
            const Color(0xFF123E36)));
    c.drawCircle(const Offset(55, 111), 2.6, _fill(const Color(0xFFFFD16E)));
    c.drawCircle(const Offset(85, 111), 2.6, _fill(const Color(0xFFFFD16E)));
    _box(c, const Rect.fromLTWH(61, 120, 18, 15), 4, const Color(0xFF328C7C),
        const Color(0xFF00584D));
    c.save();
    c.translate(84, 111);
    c.scale(0.42);
    _toolbox(c);
    c.restore();
  }

  void _drawBusiness(Canvas c) {
    final house = Path()
      ..moveTo(16, 70)
      ..lineTo(70, 24)
      ..lineTo(124, 70)
      ..moveTo(30, 61)
      ..lineTo(30, 119)
      ..lineTo(110, 119)
      ..lineTo(110, 61);
    _outline(c, house, const Color(0xA0C0F3E4), 3);
    c.save();
    c.translate(18, 48);
    c.scale(0.98);
    _toolbox(c);
    c.restore();
    const badge = Rect.fromLTWH(94, 29, 34, 34);
    c.drawOval(
        badge, _shade(badge, const Color(0xFFE0F8ED), const Color(0xFF91DCC5)));
    _outline(
        c,
        Path()
          ..moveTo(102, 46)
          ..lineTo(109, 53)
          ..lineTo(120, 40),
        const Color(0xFF005D53),
        3.8);
  }

  void _toolbox(Canvas c) {
    _box(c, const Rect.fromLTWH(31, 0, 39, 32), 8, const Color(0xFFB0D9CF),
        const Color(0xFF284D47));
    _box(c, const Rect.fromLTWH(39, 7, 23, 20), 4, const Color(0xFF17453C));
    _box(c, const Rect.fromLTWH(0, 22, 102, 65), 12, const Color(0xFF258F7C),
        const Color(0xFF123B34));
    _box(c, const Rect.fromLTWH(0, 22, 102, 26), 9, const Color(0xFFFFD679),
        const Color(0xFFD99128));
    _line(c, const Offset(10, 28), const Offset(91, 28),
        const Color(0xFFFFEAC0), 2);
    _box(c, const Rect.fromLTWH(41, 41, 20, 15), 4, const Color(0xFFFFF0C1),
        const Color(0xFFE2AE54));
    _box(c, const Rect.fromLTWH(12, 59, 78, 17), 5, const Color(0xFF1C7567),
        const Color(0xFF17463C));
    _line(c, const Offset(20, 64), const Offset(82, 64),
        const Color(0xFF70B8A5), 1.4);
  }

  @override
  bool shouldRepaint(covariant _HeroArtworkPainter oldDelegate) =>
      oldDelegate.provider != provider;
}
