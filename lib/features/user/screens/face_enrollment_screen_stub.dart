import 'package:flutter/widgets.dart';

/// Stub pour les plateformes non-web (Android, iOS, Desktop).
/// buildCameraView() n'est jamais appelé sur ces plateformes (kIsWeb = false).
Widget buildCameraView() {
  return const SizedBox.shrink();
}

