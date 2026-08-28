import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/catalog/catalog_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';

/// First screen after sign-in: loads and pre-sorts the whole catalog while
/// showing what it's doing, then fades into the dashboard.
///
/// This exists because the catalog work is genuinely slow on a real
/// provider — see [CatalogController]. The screen is not decoration: it
/// gives that work somewhere to happen so the dashboard only ever renders
/// data that's already been fetched, sorted and cached.
class InitializationScreen extends ConsumerStatefulWidget {
  const InitializationScreen({super.key});

  @override
  ConsumerState<InitializationScreen> createState() => _InitializationScreenState();
}

class _InitializationScreenState extends ConsumerState<InitializationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  /// Guards against pushing the dashboard twice if the provider emits
  /// `ready` more than once (e.g. a rebuild mid-transition).
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);

    // Kick the load after first frame so the animation is already on screen
    // when the work starts.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(catalogControllerProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _goToDashboard() {
    if (_navigated || !mounted) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 550),
        pageBuilder: (_, _, _) => const DashboardScreen(),
        // Cross-fade rather than a slide: the splash and the dashboard
        // share the same dark ground, so a fade reads as one continuous
        // surface instead of two stacked pages.
        transitionsBuilder: (_, animation, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(catalogControllerProvider);

    ref.listen(catalogControllerProvider, (_, next) {
      if (next.isReady) _goToDashboard();
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Soft brand glow bleeding from behind the mark.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.25),
                  radius: 0.9,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.20),
                    AppColors.background,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),
                _PulsingLogo(animation: _pulse),
                const SizedBox(height: 22),
                const Text(
                  AppStrings.appName,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                ),
                const SizedBox(height: 6),
                const Text(
                  AppStrings.appTagline,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const Spacer(flex: 2),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: state.hasFailed
                      ? _FailureBlock(
                          message: state.error ?? 'Could not load your catalog.',
                          onRetry: () => ref.read(catalogControllerProvider.notifier).load(),
                          onSkip: _goToDashboard,
                        )
                      : Column(
                          children: [
                            _ProgressBar(value: state.progress),
                            const SizedBox(height: 16),
                            // Keyed so AnimatedSwitcher cross-fades between
                            // phases instead of snapping the text.
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Text(
                                state.phase.label,
                                key: ValueKey(state.phase),
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Brand mark with a continuous breathing pulse and a matching glow.
class _PulsingLogo extends StatelessWidget {
  final Animation<double> animation;
  const _PulsingLogo({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(animation.value);
        final scale = 0.94 + (t * 0.12);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 108,
            height: 108,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.brandGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.30 + (t * 0.35)),
                  blurRadius: 34 + (t * 26),
                  spreadRadius: t * 8,
                ),
              ],
            ),
            child: const Icon(Icons.satellite_alt_rounded, color: Colors.white, size: 52),
          ),
        );
      },
    );
  }
}

/// Slim gradient track that fills as phases complete — deliberately not a
/// [CircularProgressIndicator].
class _ProgressBar extends StatelessWidget {
  final double value;
  const _ProgressBar({required this.value});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        height: 5,
        child: Stack(
          children: [
            const Positioned.fill(child: ColoredBox(color: AppColors.surfaceElevated)),
            LayoutBuilder(
              builder: (context, constraints) => AnimatedContainer(
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOutCubic,
                width: constraints.maxWidth * value.clamp(0.0, 1.0),
                decoration: const BoxDecoration(gradient: AppColors.brandGradient),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown when preparation fails. "Continue anyway" matters: the dashboard
/// degrades gracefully to empty rails, so a dead section shouldn't trap the
/// user on the splash.
class _FailureBlock extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onSkip;

  const _FailureBlock({required this.message, required this.onRetry, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.cloud_off_rounded, color: AppColors.textSecondary, size: 34),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(onPressed: onSkip, child: const Text('Continue anyway')),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(onPressed: onRetry, child: const Text(AppStrings.retry)),
            ),
          ],
        ),
      ],
    );
  }
}
