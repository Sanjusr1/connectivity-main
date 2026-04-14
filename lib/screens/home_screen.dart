import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'sensor_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [SensorListScreen(), DashboardScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _GlossyTechBackground(
        child: SafeArea(child: _screens[_selectedIndex]),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.sensors), label: 'Sensors'),
          NavigationDestination(
            icon: Icon(Icons.monitor_heart),
            label: 'Dashboard',
          ),
        ],
      ),
    );
  }
}

class _GlossyTechBackground extends StatelessWidget {
  const _GlossyTechBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: Stack(
        children: [
          const Positioned(
            top: -120,
            right: -110,
            child: _GlowOrb(
              size: 270,
              color: AppTheme.accentCyan,
              opacity: 0.18,
            ),
          ),
          const Positioned(
            top: 220,
            left: -130,
            child: _GlowOrb(
              size: 260,
              color: AppTheme.accentPurple,
              opacity: 0.12,
            ),
          ),
          const Positioned(
            bottom: -150,
            right: -100,
            child: _GlowOrb(
              size: 300,
              color: AppTheme.accentTeal,
              opacity: 0.12,
            ),
          ),
          Positioned.fill(
            child: CustomPaint(painter: _CircuitTexturePainter()),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppTheme.glossOverlayGradient,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.size,
    required this.color,
    required this.opacity,
  });

  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: opacity * 0.35),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _CircuitTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppTheme.accentCyan.withValues(alpha: 0.045)
      ..strokeWidth = 1;
    final nodePaint = Paint()
      ..color = AppTheme.accentCyan.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    for (var y = 70.0; y < size.height; y += 120) {
      canvas.drawLine(Offset(22, y), Offset(size.width * 0.32, y), linePaint);
      canvas.drawLine(
        Offset(size.width * 0.32, y),
        Offset(size.width * 0.44, y + 26),
        linePaint,
      );
      canvas.drawCircle(Offset(size.width * 0.44, y + 26), 2.2, nodePaint);
    }

    for (var x = 60.0; x < size.width; x += 130) {
      canvas.drawLine(
        Offset(x, size.height - 36),
        Offset(x + 54, size.height - 86),
        linePaint,
      );
      canvas.drawCircle(Offset(x + 54, size.height - 86), 2, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
