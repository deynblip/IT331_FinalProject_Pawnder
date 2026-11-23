import 'package:flutter/material.dart';

/// The rounded banner card cropped from assets/home_banner.png (message and
/// row of paws). Shared by the user Home and the Admin Home so both look the
/// same. If the crop looks off, adjust _x/_y/_w/_h (pixels in the image).
class PawBanner extends StatelessWidget {
  const PawBanner({super.key});

  static const double _imgW = 991; // full image size
  static const double _imgH = 525;
  static const double _x = 97; // card position inside the image
  static const double _y = 97;
  static const double _w = 796;
  static const double _h = 328;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final double scale = c.maxWidth / _w;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33E0662E),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              width: c.maxWidth,
              height: _h * scale,
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned(
                    left: -_x * scale,
                    top: -_y * scale,
                    width: _imgW * scale,
                    height: _imgH * scale,
                    child: Image.asset(
                      'assets/home_banner.png',
                      fit: BoxFit.fill,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}