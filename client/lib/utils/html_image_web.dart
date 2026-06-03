import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import 'dart:ui_web' as ui_web;

final Set<String> _registeredViews = <String>{};

Widget buildHtmlImage(
  String src, {
  String? viewId,
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  BorderRadius? borderRadius,
}) {
  final id = viewId ?? 'html-img-${src.hashCode}';

  if (!_registeredViews.contains(id)) {
    ui_web.platformViewRegistry.registerViewFactory(id, (int _) {
      final img = web.HTMLImageElement()
        ..src = src
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = _mapFit(fit)
        ..style.objectPosition = 'center';

      return img;
    });

    _registeredViews.add(id);
  }

  Widget widget = HtmlElementView(viewType: id);

  if (borderRadius != null) {
    widget = ClipRRect(
      borderRadius: borderRadius,
      child: widget,
    );
  }

  return SizedBox(
    width: width,
    height: height,
    child: widget,
  );
}

String _mapFit(BoxFit fit) {
  switch (fit) {
    case BoxFit.contain:
      return 'contain';
    case BoxFit.cover:
      return 'cover';
    case BoxFit.fill:
      return 'fill';
    case BoxFit.fitHeight:
      return '100% 100%';
    case BoxFit.fitWidth:
      return '100%';
    case BoxFit.none:
    case BoxFit.scaleDown:
    default:
      return 'contain';
  }
}

