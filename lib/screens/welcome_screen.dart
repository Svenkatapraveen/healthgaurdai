import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../widgets/glass_card.dart';
import '../state/app_state.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final state = AppStateProvider.of(context);

    return Scaffold(
      backgroundColor: AppColors.getBg(isDark),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background graphic elements
          Positioned(
            top: 40,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryTeal.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: 150,
            right: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryBlue.withOpacity(0.12),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 30),
                  // App Branding
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.health_and_safety, color: AppColors.primaryTeal, size: 32),
                      const SizedBox(width: 8),
                      Text(
                        'HealthGuard AI',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.getTextPrimary(isDark),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  
                  // Interactive Inline Vector Drawing of Healthcare Nodes (Glass Card style)
                  GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        CustomPaint(
                          size: const Size(double.infinity, 140),
                          painter: _MedicalIllustrationPainter(isDark: isDark),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Your Intelligent Healthcare Assistant',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.getTextPrimary(isDark),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Assess disease risks, monitor lifestyle metrics, and connect with medical professionals instantly using advanced AI forecasts.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.getTextSecondary(isDark),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),
                  // Logins/Authentication buttons
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 4,
                    ),
                    child: const Text(
                      'Log In with Email',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/register');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.getTextPrimary(isDark),
                      side: BorderSide(color: AppColors.getBorder(isDark), width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Create New Account',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: AppColors.getBorder(isDark))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            color: AppColors.getTextSecondary(isDark),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: AppColors.getBorder(isDark))),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Google Login Button
                  ElevatedButton(
                    onPressed: () async {
                      final ok = await state.loginWithGoogle();
                      if (ok && context.mounted) {
                        if (state.currentUser!.isAdmin) {
                          Navigator.pushReplacementNamed(context, '/admin-dashboard');
                        } else {
                          Navigator.pushReplacementNamed(context, '/dashboard');
                        }
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Google Sign-In failed or was canceled.')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF4285F4) : Colors.white,
                      foregroundColor: isDark ? Colors.white : Colors.black87,
                      elevation: 1,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: isDark ? Colors.transparent : Colors.grey.withOpacity(0.3),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'G',
                            style: TextStyle(
                              color: Color(0xFF4285F4),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Sign in with Google',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  // Admin access portal trigger
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/admin-login');
                      },
                      child: Text(
                        'Access Admin Portal',
                        style: TextStyle(
                          color: AppColors.primaryTeal,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


}

// Vector healthcare nodes illustration painter
class _MedicalIllustrationPainter extends CustomPainter {
  final bool isDark;

  _MedicalIllustrationPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paintLine = Paint()
      ..color = AppColors.primaryTeal.withOpacity(0.3)
      ..strokeWidth = 2.0;

    final paintMainNode = Paint()
      ..color = AppColors.primaryTeal
      ..style = PaintingStyle.fill;

    final paintSideNode = Paint()
      ..color = AppColors.primaryBlue
      ..style = PaintingStyle.fill;

    // Outer radar waves
    canvas.drawCircle(
      center,
      45.0,
      Paint()
        ..color = AppColors.primaryTeal.withOpacity(0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    canvas.drawCircle(
      center,
      65.0,
      Paint()
        ..color = AppColors.primaryTeal.withOpacity(0.05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Nodes Coordinates
    final pLeft = Offset(center.dx - 80, center.dy - 20);
    final pRight = Offset(center.dx + 80, center.dy + 15);
    final pTop = Offset(center.dx - 30, center.dy - 45);
    final pBottom = Offset(center.dx + 40, center.dy + 45);

    // Draw connecting paths
    canvas.drawLine(center, pLeft, paintLine);
    canvas.drawLine(center, pRight, paintLine);
    canvas.drawLine(center, pTop, paintLine);
    canvas.drawLine(center, pBottom, paintLine);
    canvas.drawLine(pLeft, pTop, paintLine);
    canvas.drawLine(pRight, pBottom, paintLine);

    // Draw nodes
    canvas.drawCircle(center, 18.0, paintMainNode);
    // Draw medical icon inside center node
    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.bolt.codePoint),
        style: TextStyle(
          fontSize: 22,
          fontFamily: Icons.bolt.fontFamily,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    iconPainter.layout();
    iconPainter.paint(
      canvas,
      Offset(center.dx - iconPainter.width / 2, center.dy - iconPainter.height / 2),
    );

    // Draw secondary nodes
    canvas.drawCircle(pLeft, 10, paintSideNode);
    canvas.drawCircle(pRight, 12, paintSideNode);
    canvas.drawCircle(pTop, 8, paintMainNode);
    canvas.drawCircle(pBottom, 9, paintSideNode);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
