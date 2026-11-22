import 'package:flutter/material.dart';

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
      color: const Color(0xFFFFE8D6),
      child: const Icon(Icons.pets, color: Color(0xFF8A746C)),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: asset == null
          ? fallback
          : Image.asset(
        asset!,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }
}