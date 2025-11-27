import 'package:flutter/material.dart';

/// Fallback para plataformas não-web: usa [Image.network] normalmente.
Widget buildHtmlImage(
  String src, {
  String? viewId,
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  BorderRadius? borderRadius,
}) {
  final image = Image.network(
    src,
    width: width,
    height: height,
    fit: fit,
  );

  if (borderRadius != null) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: image,
    );
  }

  return image;
}

