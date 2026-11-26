import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import 'floating_doc_card.dart';

/// Lavender hero panel with three floating document cards and a check badge.
class WelcomeIllustration extends StatelessWidget {
  const WelcomeIllustration({super.key, this.height = 330});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -70,
            top: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: const BoxDecoration(
                color: AppColors.primarySofter,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const Positioned(
            left: 40,
            top: 62,
            child: FloatingDocCard(
              icon: Icons.menu_book_outlined,
              color: AppColors.education,
              width: 180,
              height: 116,
              angleDegrees: -8,
            ),
          ),
          const Positioned(
            left: 150,
            top: 132,
            child: FloatingDocCard(
              icon: Icons.favorite_border,
              color: AppColors.health,
              width: 190,
              height: 120,
              angleDegrees: 6,
              lineWidths: [120, 84],
            ),
          ),
          const Positioned(
            left: 60,
            top: 218,
            child: FloatingDocCard(
              icon: Icons.account_balance_outlined,
              color: AppColors.government,
              width: 150,
              height: 82,
              angleDegrees: -3,
              horizontal: true,
              lineWidths: [70, 46],
            ),
          ),
          Positioned(
            right: 26,
            top: 34,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(Icons.check_rounded,
                  color: AppColors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}
