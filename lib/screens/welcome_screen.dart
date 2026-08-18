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
    final size = MediaQuery.of(context).size;

    final bool isMobile = size.width < 600 || size.height < 700;
    final double horizontalPadding = isMobile ? 16.0 : 24.0;
    final double verticalSpacing = isMobile ? 10.0 : 16.0;

    return Scaffold(
      backgroundColor: AppColors.getBg(isDark),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background graphic elements
          Positioned(
            top: 20,
            left: -60,
            child: Container(
              width: isMobile ? 160 : 220,
              height: isMobile ? 160 : 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryTeal.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            right: -80,
            child: Container(
              width: isMobile ? 240 : 350,
              height: isMobile ? 240 : 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryBlue.withOpacity(0.12),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: isMobile ? 12.0 : 20.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: isMobile ? 8 : 16),

                      // 1. App Branding Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(isMobile ? 6 : 8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryTeal.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.health_and_safety_rounded,
                              color: AppColors.primaryTeal,
                              size: isMobile ? 24 : 30,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'HealthGuard AI',
                            style: TextStyle(
                              fontSize: isMobile ? 19 : 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.getTextPrimary(isDark),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: verticalSpacing * 1.2),

                      // 2. Hero Section Card with Responsive Illustration
                      GlassCard(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 16.0 : 24.0,
                          vertical: isMobile ? 14.0 : 22.0,
                        ),
                        borderRadius: isMobile ? 16.0 : 20.0,
                        child: Column(
                          children: [
                            CustomPaint(
                              size: Size(double.infinity, isMobile ? 85 : 130),
                              painter: _MedicalIllustrationPainter(isDark: isDark),
                            ),
                            SizedBox(height: isMobile ? 10 : 16),
                            Text(
                              'Your Intelligent Healthcare Assistant',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isMobile ? 16.5 : 20.0,
                                fontWeight: FontWeight.bold,
                                color: AppColors.getTextPrimary(isDark),
                                height: 1.25,
                              ),
                            ),
                            SizedBox(height: isMobile ? 6 : 10),
                            Text(
                              'Assess disease risks, monitor lifestyle metrics, and connect with medical professionals instantly using advanced AI forecasts.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isMobile ? 12.0 : 13.0,
                                color: AppColors.getTextSecondary(isDark),
                                height: 1.38,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: verticalSpacing * 1.2),

                      // 3. Action Buttons Section
                      // Email Login Button
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/login');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryTeal,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                        ),
                        child: Text(
                          'Log In with Email',
                          style: TextStyle(
                            fontSize: isMobile ? 14.5 : 16.0,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      SizedBox(height: isMobile ? 10 : 12),

                      // Create New Account Button
                      OutlinedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/register');
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.getTextPrimary(isDark),
                          side: BorderSide(color: AppColors.getBorder(isDark), width: 1.5),
                          padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Create New Account',
                          style: TextStyle(
                            fontSize: isMobile ? 14.5 : 16.0,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      SizedBox(height: isMobile ? 12 : 16),

                      // Divider
                      Row(
                        children: [
                          Expanded(child: Divider(color: AppColors.getBorder(isDark))),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14.0),
                            child: Text(
                              'OR',
                              style: TextStyle(
                                color: AppColors.getTextSecondary(isDark),
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: AppColors.getBorder(isDark))),
                        ],
                      ),
                      SizedBox(height: isMobile ? 12 : 16),

                      // Google Sign-In Button
                      ElevatedButton(
                        onPressed: () async {
                          final ok = await state.loginWithGoogle();
                          if (ok && context.mounted) {
                            if (state.currentUser!.isAdmin) {
                              Navigator.pushNamedAndRemoveUntil(context, '/admin-dashboard', (route) => false);
                            } else {
                              Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
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
                          padding: EdgeInsets.symmetric(
                            vertical: isMobile ? 10 : 12,
                            horizontal: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: isDark ? Colors.transparent : Colors.grey.withOpacity(0.3),
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: isMobile ? 24 : 28,
                              height: isMobile ? 24 : 28,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'G',
                                style: TextStyle(
                                  color: const Color(0xFF4285F4),
                                  fontWeight: FontWeight.bold,
                                  fontSize: isMobile ? 15 : 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Sign in with Google',
                              style: TextStyle(
                                fontSize: isMobile ? 14 : 15,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: isMobile ? 8 : 14),

                      // Admin Access Portal Button
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/admin-login');
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Access Admin Portal',
                            style: TextStyle(
                              color: AppColors.primaryTeal,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Responsive Vector Healthcare Nodes Illustration Painter
class _MedicalIllustrationPainter extends CustomPainter {
  final bool isDark;

  _MedicalIllustrationPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final double scale = size.height / 130.0;

    final paintLine = Paint()
      ..color = AppColors.primaryTeal.withOpacity(0.3)
      ..strokeWidth = 2.0 * scale;

    final paintMainNode = Paint()
      ..color = AppColors.primaryTeal
      ..style = PaintingStyle.fill;

    final paintSideNode = Paint()
      ..color = AppColors.primaryBlue
      ..style = PaintingStyle.fill;

    // Outer radar waves scaled
    canvas.drawCircle(
      center,
      40.0 * scale,
      Paint()
        ..color = AppColors.primaryTeal.withOpacity(0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 * scale,
    );

    canvas.drawCircle(
      center,
      60.0 * scale,
      Paint()
        ..color = AppColors.primaryTeal.withOpacity(0.05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0 * scale,
    );

    // Nodes Coordinates scaled
    final pLeft = Offset(center.dx - 70 * scale, center.dy - 18 * scale);
    final pRight = Offset(center.dx + 70 * scale, center.dy + 12 * scale);
    final pTop = Offset(center.dx - 25 * scale, center.dy - 38 * scale);
    final pBottom = Offset(center.dx + 35 * scale, center.dy + 38 * scale);

    // Draw connecting paths
    canvas.drawLine(center, pLeft, paintLine);
    canvas.drawLine(center, pRight, paintLine);
    canvas.drawLine(center, pTop, paintLine);
    canvas.drawLine(center, pBottom, paintLine);
    canvas.drawLine(pLeft, pTop, paintLine);
    canvas.drawLine(pRight, pBottom, paintLine);

    // Draw nodes
    canvas.drawCircle(center, 16.0 * scale, paintMainNode);

    // Draw medical icon inside center node
    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.bolt.codePoint),
        style: TextStyle(
          fontSize: 19 * scale,
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
    canvas.drawCircle(pLeft, 9 * scale, paintSideNode);
    canvas.drawCircle(pRight, 11 * scale, paintSideNode);
    canvas.drawCircle(pTop, 7 * scale, paintMainNode);
    canvas.drawCircle(pBottom, 8 * scale, paintSideNode);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
