import 'package:flutter/material.dart';

Widget getWebCameraView() {
  return const Center(
    child: Icon(Icons.videocam_rounded, size: 80, color: Colors.white24),
  );
}

/// Заглушка для не-веб платформ
String? captureCurrentFrame() => null;
