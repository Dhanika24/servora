part of '../../main.dart';

class ServiceCategoryIcon extends StatelessWidget {
  final String category;
  final double size;

  const ServiceCategoryIcon({
    required this.category,
    this.size = 64,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final tint = switch (category) {
      'Plumbing' => const Color(0xFFABDCD9),
      'Electrical' => const Color(0xFFFFDEA0),
      'Painting' => const Color(0xFFA9DCD0),
      'Carpentry' => const Color(0xFFE9CDB0),
      'Masonry' => const Color(0xFFF2C6B5),
      'Gardening' => const Color(0xFFB8E4BB),
      'Cleaning' => const Color(0xFFB9E3E8),
      'Mechanic' => const Color(0xFFBDD5DD),
      _ => const Color(0xFFABDCD9),
    };
    final top = dark
        ? Color.lerp(const Color(0xFF172C27), tint, 0.16)!
        : Color.lerp(Colors.white, tint, 0.30)!;
    final bottom = dark
        ? Color.lerp(const Color(0xFF172C27), tint, 0.27)!
        : Color.lerp(Colors.white, tint, 0.72)!;
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.11),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [top, bottom],
        ),
        borderRadius: BorderRadius.circular(size * 0.30),
        border: Border.all(color: tint.withAlpha(dark ? 46 : 100)),
      ),
      child: CustomPaint(
        painter: _ServiceIconPainter(category: category, dark: dark),
      ),
    );
  }
}

class _ServiceIconPainter extends CustomPainter {
  final String category;
  final bool dark;

  const _ServiceIconPainter({
    required this.category,
    required this.dark,
  });

  static const teal = Color(0xFF008C80);
  static const deepTeal = Color(0xFF005D54);
  static const mint = Color(0xFF6BD8BF);
  static const gold = Color(0xFFFFC338);
  static const amber = Color(0xFFE69B23);
  static const brown = Color(0xFFB97735);
  static const brick = Color(0xFFD96C42);
  static const green = Color(0xFF259B55);
  static const lightGreen = Color(0xFF6BD15E);

  Color get metal => dark ? const Color(0xFFB6D3CE) : const Color(0xFF365654);

  Paint fill(Color color) {
    return Paint()
      ..color = color
      ..isAntiAlias = true;
  }

  Paint stroke(Color color, double width) {
    return Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;
  }

  void box(
    Canvas canvas,
    double x,
    double y,
    double width,
    double height,
    Color color, {
    double radius = 3,
  }) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, width, height),
        Radius.circular(radius),
      ),
      fill(color),
    );
  }

  void line(
    Canvas canvas,
    Offset start,
    Offset end,
    Color color,
    double width,
  ) {
    canvas.drawLine(
      start,
      end,
      stroke(color, width),
    );
  }

  void sparkle(
    Canvas canvas,
    double x,
    double y,
    double radius,
    Color color,
  ) {
    final path = Path()
      ..moveTo(x, y - radius)
      ..lineTo(x + radius * 0.3, y - radius * 0.3)
      ..lineTo(x + radius, y)
      ..lineTo(x + radius * 0.3, y + radius * 0.3)
      ..lineTo(x, y + radius)
      ..lineTo(x - radius * 0.3, y + radius * 0.3)
      ..lineTo(x - radius, y)
      ..lineTo(x - radius * 0.3, y - radius * 0.3)
      ..close();

    canvas.drawPath(path, fill(color));
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();

    canvas.scale(
      size.width / 64,
      size.height / 64,
    );

    switch (category) {
      case 'Plumbing':
        plumbing(canvas);
        break;

      case 'Electrical':
        electrical(canvas);
        break;

      case 'Painting':
        painting(canvas);
        break;

      case 'Carpentry':
        carpentry(canvas);
        break;

      case 'Masonry':
        masonry(canvas);
        break;

      case 'Gardening':
        gardening(canvas);
        break;

      case 'Cleaning':
        cleaning(canvas);
        break;

      case 'Mechanic':
        mechanic(canvas);
        break;

      default:
        canvas.drawCircle(
          const Offset(32, 32),
          18,
          fill(teal),
        );
        break;
    }

    canvas.restore();
  }

  void plumbing(Canvas canvas) {
    box(canvas, 8, 22, 12, 20, deepTeal);
    box(canvas, 18, 26, 30, 12, teal);

    final pipe = Path()
      ..moveTo(43, 32)
      ..quadraticBezierTo(52, 32, 52, 43);

    canvas.drawPath(
      pipe,
      stroke(teal, 12),
    );

    box(canvas, 27, 16, 10, 13, deepTeal);
    box(canvas, 18, 10, 28, 7, teal);

    line(
      canvas,
      const Offset(23, 29),
      const Offset(42, 29),
      mint,
      3,
    );

    final drop = Path()
      ..moveTo(52, 47)
      ..cubicTo(42, 57, 46, 62, 52, 62)
      ..cubicTo(58, 62, 62, 57, 52, 47)
      ..close();

    canvas.drawPath(
      drop,
      fill(const Color(0xFF49BAD5)),
    );
  }

  void electrical(Canvas canvas) {
    final bolt = Path()
      ..moveTo(36, 3)
      ..lineTo(12, 36)
      ..lineTo(30, 36)
      ..lineTo(25, 61)
      ..lineTo(54, 25)
      ..lineTo(35, 25)
      ..close();

    canvas.drawPath(bolt, fill(gold));
    canvas.drawPath(bolt, stroke(amber, 1.5));

    final highlight = Path()
      ..moveTo(36, 6)
      ..lineTo(19, 32)
      ..lineTo(30, 32);

    canvas.drawPath(
      highlight,
      stroke(const Color(0xFFFFE795), 3),
    );
  }

  void painting(Canvas canvas) {
    box(canvas, 7, 8, 40, 17, deepTeal);
    box(canvas, 7, 8, 40, 12, teal);

    line(
      canvas,
      const Offset(12, 11),
      const Offset(42, 11),
      mint,
      3,
    );

    final handle = Path()
      ..moveTo(47, 16)
      ..lineTo(54, 16)
      ..quadraticBezierTo(58, 16, 58, 24)
      ..lineTo(58, 29)
      ..quadraticBezierTo(58, 34, 51, 34)
      ..lineTo(31, 40)
      ..lineTo(31, 48);

    canvas.drawPath(
      handle,
      stroke(metal, 4),
    );

    box(canvas, 25, 44, 12, 17, deepTeal);
    box(canvas, 27, 46, 5, 12, teal);
  }

  void carpentry(Canvas canvas) {
    canvas.save();

    canvas.translate(32, 32);
    canvas.rotate(0.60);
    canvas.translate(-32, -32);

    box(canvas, 27, 24, 11, 37, brown);
    box(canvas, 29, 27, 4, 28, gold);

    box(canvas, 13, 8, 37, 17, metal);
    box(canvas, 9, 6, 10, 21, deepTeal);

    final claw = Path()
      ..moveTo(45, 8)
      ..quadraticBezierTo(58, 7, 58, 23)
      ..lineTo(50, 21)
      ..lineTo(46, 16)
      ..close();

    canvas.drawPath(claw, fill(metal));

    line(
      canvas,
      const Offset(21, 11),
      const Offset(43, 11),
      const Color(0xFF90B9B3),
      3,
    );

    canvas.restore();
  }

  void masonry(Canvas canvas) {
    for (int row = 0; row < 3; row++) {
      final y = 12.0 + row * 15;

      if (row == 1) {
        box(canvas, 5, y, 16, 12, brick);
        box(canvas, 24, y, 17, 12, brick);
        box(canvas, 44, y, 15, 12, brick);
      } else {
        box(canvas, 5, y, 25, 12, brick);
        box(canvas, 33, y, 26, 12, brick);
      }
    }

    line(
      canvas,
      const Offset(9, 15),
      const Offset(25, 15),
      const Color(0xFFFFB394),
      2,
    );
  }

  void gardening(Canvas canvas) {
    line(
      canvas,
      const Offset(32, 58),
      const Offset(32, 25),
      green,
      5,
    );

    final leftLeaf = Path()
      ..moveTo(31, 40)
      ..cubicTo(5, 40, 5, 12, 8, 10)
      ..cubicTo(29, 10, 38, 24, 31, 40)
      ..close();

    final rightLeaf = Path()
      ..moveTo(33, 31)
      ..cubicTo(29, 11, 46, 4, 59, 6)
      ..cubicTo(61, 24, 49, 36, 33, 31)
      ..close();

    canvas.drawPath(leftLeaf, fill(green));
    canvas.drawPath(rightLeaf, fill(lightGreen));

    line(
      canvas,
      const Offset(32, 39),
      const Offset(15, 19),
      mint,
      2,
    );

    line(
      canvas,
      const Offset(34, 30),
      const Offset(51, 14),
      green,
      2,
    );
  }

  void cleaning(Canvas canvas) {
    line(
      canvas,
      const Offset(45, 6),
      const Offset(24, 39),
      deepTeal,
      7,
    );

    final brush = Path()
      ..moveTo(18, 33)
      ..lineTo(34, 43)
      ..lineTo(20, 62)
      ..lineTo(3, 49)
      ..close();

    canvas.drawPath(brush, fill(gold));
    canvas.drawPath(brush, stroke(amber, 1.5));

    line(
      canvas,
      const Offset(19, 41),
      const Offset(10, 52),
      amber,
      2,
    );

    line(
      canvas,
      const Offset(25, 46),
      const Offset(17, 57),
      amber,
      2,
    );

    sparkle(canvas, 48, 39, 8, teal);
    sparkle(canvas, 55, 54, 6, teal);
  }

  void mechanic(Canvas canvas) {
    final roof = Path()
      ..moveTo(10, 27)
      ..lineTo(16, 11)
      ..quadraticBezierTo(18, 7, 24, 7)
      ..lineTo(39, 7)
      ..quadraticBezierTo(44, 7, 46, 13)
      ..lineTo(51, 27)
      ..close();

    canvas.drawPath(roof, fill(teal));

    final windshield = Path()
      ..moveTo(16, 24)
      ..lineTo(21, 13)
      ..lineTo(40, 13)
      ..lineTo(45, 24)
      ..close();

    canvas.drawPath(
      windshield,
      fill(const Color(0xFFC9F0EA)),
    );

    box(canvas, 6, 25, 50, 20, deepTeal);
    box(canvas, 8, 39, 10, 13, metal);
    box(canvas, 44, 39, 10, 13, metal);

    box(canvas, 11, 29, 10, 6, Colors.white);
    box(canvas, 41, 29, 10, 6, Colors.white);

    box(canvas, 23, 36, 16, 4, mint);

    line(
      canvas,
      const Offset(36, 58),
      const Offset(54, 40),
      metal,
      8,
    );

    canvas.drawArc(
      const Rect.fromLTWH(45, 29, 19, 19),
      0.25,
      4.5,
      false,
      stroke(metal, 6),
    );

    canvas.drawCircle(
      const Offset(35, 59),
      3,
      fill(deepTeal),
    );
  }

  @override
  bool shouldRepaint(
    covariant _ServiceIconPainter oldDelegate,
  ) {
    return oldDelegate.category != category || oldDelegate.dark != dark;
  }
}

class ServiceCategoryTile extends StatelessWidget {
  final String category;
  final VoidCallback onTap;

  const ServiceCategoryTile({
    required this.category,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 8,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              ServiceCategoryIcon(
                category: category,
                size: 44,
              ),
              const SizedBox(height: 6),
              Text(
                category,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
