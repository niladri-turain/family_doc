import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// "No members yet" illustration and text.
class EmptyFamilyView extends StatelessWidget {
  const EmptyFamilyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 200,
          height: 170,
          child: Stack(
            children: [
              Positioned(
                left: 20,
                top: 10,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: const BoxDecoration(
                    color: AppColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const Positioned(
                left: 30,
                top: 58,
                child: _DashedPerson(size: 66),
              ),
              Positioned(
                left: 68,
                top: 30,
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 26,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person_add_alt_outlined,
                    color: AppColors.white,
                    size: 32,
                  ),
                ),
              ),
              const Positioned(
                left: 118,
                top: 82,
                child: _DashedPerson(size: 60),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'No members yet',
          style: AppTextStyles.title.copyWith(fontSize: 22),
        ),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Text(
            'Start by adding yourself, then add your family to keep '
            "everyone's documents organised.",
            textAlign: TextAlign.center,
            style: AppTextStyles.body,
          ),
        ),
      ],
    );
  }
}

class _DashedPerson extends StatelessWidget {
  const _DashedPerson({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedCirclePainter(),
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.person_outline_rounded,
          size: size * 0.4,
          color: AppColors.primary.withValues(alpha: 0.75),
        ),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.dashedBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final rect = (Offset.zero & size).deflate(1);
    const dashes = 18;
    const sweep = 2 * math.pi / dashes;
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(rect, i * sweep, sweep * 0.55, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
