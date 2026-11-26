import 'package:flutter/material.dart';
import '../utils/app_colors.dart';


class ReportImage extends StatelessWidget {
  final String? asset;
  final double width;
  final double height;

  const ReportImage({super.key, this.asset, required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: width,
      height: height,
      color: kPeach,
      child: const Icon(Icons.pets, color: Color(0xFF8A746C)),
    );

    final String? src = asset;
    final Widget image;
    if (src == null || src.isEmpty) {
      image = fallback;
    } else if (src.startsWith('http')) {
      image = Image.network(
        src,
        width: width,
        height: height,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) =>
        progress == null ? child : fallback,
        errorBuilder: (_, _, _) => fallback,
      );
    } else {
      image = Image.asset(
        src,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: image,
    );
  }
}