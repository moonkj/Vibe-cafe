import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/supabase_service.dart';
import '../data/auth_repository.dart';
import 'widgets/wave_to_spot_painter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Listen for OAuth deep-link completion (e.g. Kakao browser redirect)
    ref.listenManual(authStateProvider, (_, next) {
      next.whenData((state) {
        if (state.event == AuthChangeEvent.signedIn && mounted) {
          context.go('/map');
        }
      });
    });
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(flex: 2),
                // Wave → Spot animation
                SizedBox(
                  height: 108,
                  child: AnimatedBuilder(
                    animation: _waveController,
                    builder: (context, _) => CustomPaint(
                      painter: WaveToSpotPainter(
                        progress: _waveController.value,
                      ),
                      size: const Size(double.infinity, 108),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // App name
                Text(
                  AppStrings.appName,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    foreground: Paint()
                      ..shader = const LinearGradient(
                        colors: [AppColors.mintGreen, AppColors.skyBlue],
                      ).createShader(const Rect.fromLTWH(0, 0, 200, 50)),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 600.ms)
                    .slideY(begin: 0.2, end: 0),
                const SizedBox(height: 12),
                // Slogan
                Text(
                  AppStrings.appSlogan,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                )
                    .animate()
                    .fadeIn(delay: 700.ms, duration: 600.ms)
                    .slideY(begin: 0.2, end: 0),
                const Spacer(flex: 3),
                // Login Buttons
                _LoginButtons(
                  isLoading: _isLoading,
                  onKakao: _signInWithKakao,
                  onGoogle: _signInWithGoogle,
                )
                    .animate()
                    .fadeIn(delay: 1000.ms, duration: 600.ms)
                    .slideY(begin: 0.3, end: 0),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _signInWithKakao() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).signInWithKakao();
      // Auth completes asynchronously via deep link → authStateProvider listener
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      // Auth completes asynchronously via deep link → authStateProvider listener
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.dbVeryLoud,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _LoginButtons extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onKakao;
  final VoidCallback onGoogle;

  const _LoginButtons({
    required this.isLoading,
    required this.onKakao,
    required this.onGoogle,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.mintGreen),
      );
    }

    return Column(
      children: [
        // Kakao Sign In (brand: #FEE500 yellow, black text)
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: onKakao,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFEE500),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            icon: const _KakaoIcon(),
            label: const Text(
              AppStrings.loginWithKakao,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Google Sign In
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: onGoogle,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.divider, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const _GoogleIcon(),
            label: const Text(
              AppStrings.loginWithGoogle,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

/// Kakao talk-bubble icon (simplified)
class _KakaoIcon extends StatelessWidget {
  const _KakaoIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _KakaoLogoPainter()),
    );
  }
}

class _KakaoLogoPainter extends CustomPainter {
  const _KakaoLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF3C1E1E)  // Kakao dark brown
      ..style = PaintingStyle.fill;
    final cx = size.width / 2;
    final cy = size.height / 2 - size.height * 0.05;
    // Oval speech bubble
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy),
        width: size.width,
        height: size.height * 0.85,
      ),
      paint,
    );
    // Tail triangle at bottom-center
    final tail = Path()
      ..moveTo(cx - size.width * 0.12, cy + size.height * 0.30)
      ..lineTo(cx + size.width * 0.05, cy + size.height * 0.50)
      ..lineTo(cx + size.width * 0.18, cy + size.height * 0.28)
      ..close();
    canvas.drawPath(tail, paint);
  }

  @override
  bool shouldRepaint(_KakaoLogoPainter old) => false;
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Simplified Google G icon using paint
    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw coloured arcs to approximate Google logo
    final colors = [
      const Color(0xFF4285F4),
      const Color(0xFF34A853),
      const Color(0xFFFBBC05),
      const Color(0xFFEA4335),
    ];
    for (int i = 0; i < 4; i++) {
      paint.color = colors[i];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        (i * 1.5707963) - 0.7853982,
        1.5707963,
        true,
        paint,
      );
    }
    // White center
    paint.color = Colors.white;
    canvas.drawCircle(center, radius * 0.6, paint);
  }

  @override
  bool shouldRepaint(_GoogleLogoPainter oldDelegate) => false;
}
