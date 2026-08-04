// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

// Глобальная ссылка на видеоэлемент для захвата кадра
html.VideoElement? _globalVideoElement;

/// Захватить текущий кадр с камеры в формате base64 JPEG
String? captureCurrentFrame() {
  final video = _globalVideoElement;
  if (video == null || video.videoWidth == 0 || video.videoHeight == 0) {
    return null;
  }
  try {
    final canvas = html.CanvasElement(
      width: video.videoWidth,
      height: video.videoHeight,
    );
    canvas.context2D.drawImage(video, 0, 0);
    // Возвращает data:image/jpeg;base64,...
    return canvas.toDataUrl('image/jpeg', 0.85);
  } catch (e) {
    debugPrint('captureCurrentFrame error: $e');
    return null;
  }
}

class _WebCamWidget extends StatefulWidget {
  const _WebCamWidget();

  @override
  State<_WebCamWidget> createState() => _WebCamWidgetState();
}

class _WebCamWidgetState extends State<_WebCamWidget> {
  late String _viewType;
  html.VideoElement? _videoElement;

  @override
  void initState() {
    super.initState();
    _viewType = 'trendum-web-cam-${DateTime.now().microsecondsSinceEpoch}';
    _videoElement = html.VideoElement()
      ..autoplay = true
      ..muted = true
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover';

    _globalVideoElement = _videoElement;

    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) => _videoElement!,
    );

    html.window.navigator.mediaDevices?.getUserMedia({'video': true, 'audio': false}).then((stream) {
      if (_videoElement != null) {
        _videoElement!.srcObject = stream;
      }
    }).catchError((err) {
      debugPrint('Web camera error: $err');
    });
  }

  @override
  void dispose() {
    if (_globalVideoElement == _videoElement) {
      _globalVideoElement = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}

Widget getWebCameraView() {
  return const _WebCamWidget();
}
