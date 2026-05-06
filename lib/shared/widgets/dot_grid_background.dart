import 'package:flutter/material.dart';

/// Fundo com grade de pontos — idêntico ao `main` do web
/// radial-gradient(circle, oklch(0.88 0.006 75) 1px, transparent 1px) 24x24px
class DotGridBackground extends StatelessWidget {
  const DotGridBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CustomPaint(
      painter: _DotGridPainter(isDark: isDark),
      child: child,
    );
  }
}

class _DotGridPainter extends CustomPainter {
  _DotGridPainter({required this.isDark});
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark
          ? const Color(0x22FFFFFF)   // pontos sutis no dark
          : const Color(0x33C5C7E0)  // pontos sutis no light
      ..style = PaintingStyle.fill;

    const spacing = 24.0;
    const dotRadius = 1.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter old) => old.isDark != isDark;
}
