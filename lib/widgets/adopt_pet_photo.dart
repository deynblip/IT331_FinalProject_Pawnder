import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Shows a pet photo. Sample pets use asset images ("assets/..."). Newly
/// posted pets use a picked photo: a file on Android, a blob URL on web.
class PetPhoto extends StatelessWidget {
  final String path;
  final Widget fallback;

  const PetPhoto({super.key, required this.path, required this.fallback});

  @override
  Widget build(BuildContext context) {
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      );
    }
    if (kIsWeb) {
      // On web, the picked photo's path is a browser URL, not a real file.
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      );
    }
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallback,
    );
  }
}