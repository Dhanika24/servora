part of '../../main.dart';

class ServoraMark extends StatelessWidget {
  final double size;

  const ServoraMark({
    this.size = 44,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.28),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF008F80),
              Color(0xFF004D45),
            ],
          ),
        ),
        child: CustomPaint(
          painter: _ServoraMarkPainter(),
        ),
      ),
    );
  }
}

class _ServoraMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();

    canvas.scale(
      size.width / 40,
      size.height / 40,
    );

    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white,
          Color(0xFFD9F5EC),
          Colors.white,
        ],
      ).createShader(
        const Rect.fromLTWH(0, 0, 40, 40),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(29, 10)
      ..lineTo(18, 10)
      ..cubicTo(7, 10, 7, 20, 18, 20)
      ..lineTo(22, 20)
      ..cubicTo(33, 20, 33, 30, 22, 30)
      ..lineTo(11, 30);

    canvas.drawPath(path, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(
    covariant _ServoraMarkPainter oldDelegate,
  ) {
    return false;
  }
}

class ServoraBrand extends StatelessWidget {
  final double markSize;
  final bool showTagline;

  const ServoraBrand({
    this.markSize = 42,
    this.showTagline = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ServoraMark(size: markSize),
        const SizedBox(width: 11),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Servora',
                style: TextStyle(
                  color: colors.primary,
                  fontSize: markSize * 0.65,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
              if (showTagline)
                Text(
                  'Trusted services, simplified.',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
