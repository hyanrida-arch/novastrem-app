import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

/// Placeholder brand mark for NovaStream: gradient icon badge + tagline
/// (no wordmark text — the app bar/login copy already say "NovaStream").
///
/// Swap the `Icon` inside the gradient badge for `Image.asset(
/// 'assets/images/novastream_logo.png')` once real artwork is dropped into
/// `assets/images/` (already declared in pubspec.yaml).
class NovaStreamLogo extends StatelessWidget {
  final double size;

  const NovaStreamLogo({super.key, this.size = 88});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            gradient: AppColors.brandGradient,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.satellite_alt_rounded, color: Colors.white, size: size * 0.48),
        ),
        const SizedBox(height: 12),
        const Text(
          AppStrings.appTagline,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      ],
    );
  }
}
