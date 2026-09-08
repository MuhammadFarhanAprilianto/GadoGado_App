import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import 'warung_logo_bytes.dart';

class WarungLogo extends StatelessWidget {
  final double height;
  final BoxFit fit;
  final bool showText;
  final Color? color;

  const WarungLogo({
    super.key,
    this.height = 38,
    this.fit = BoxFit.contain,
    this.showText = true,
    this.color,
  });

  Widget _buildLogoImage(double imgHeight) {
    return Image.memory(
      warungLogoBytes,
      height: imgHeight,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => Image.asset(
        'assets/images/logo_header.png',
        height: imgHeight,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => Image.asset(
          'assets/images/logo_header.webp',
          height: imgHeight,
          fit: fit,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = color ?? AppColors.primary;

    if (!showText) {
      return _buildLogoImage(height);
    }

    final iconHeight = height * 0.95;
    final topFontSize = height * 0.46;
    final bottomFontSize = height * 0.32;

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildLogoImage(iconHeight),
          SizedBox(width: height * 0.2),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                children: [
                  Text(
                    'W A R U N G',
                    style: GoogleFonts.questrial(
                      fontSize: topFontSize,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.2,
                      height: 1.05,
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 1.3
                        ..strokeCap = StrokeCap.round
                        ..strokeJoin = StrokeJoin.round
                        ..color = primaryColor,
                    ),
                  ),
                  Text(
                    'W A R U N G',
                    style: GoogleFonts.questrial(
                      fontSize: topFontSize,
                      fontWeight: FontWeight.w900,
                      color: primaryColor,
                      letterSpacing: 2.2,
                      height: 1.05,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Stack(
                children: [
                  Text(
                    'Gado Gado Mpo Lemez',
                    style: GoogleFonts.questrial(
                      fontSize: bottomFontSize,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.2,
                      height: 1.05,
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 1.1
                        ..strokeCap = StrokeCap.round
                        ..strokeJoin = StrokeJoin.round
                        ..color = primaryColor,
                    ),
                  ),
                  Text(
                    'Gado Gado Mpo Lemez',
                    style: GoogleFonts.questrial(
                      fontSize: bottomFontSize,
                      fontWeight: FontWeight.w900,
                      color: primaryColor,
                      letterSpacing: 0.2,
                      height: 1.05,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
