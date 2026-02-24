  import 'package:flutter/material.dart';

  String withCacheBuster(
    String? rawUrl, {
    String? cacheKey,
  }) {
    final url = rawUrl?.trim() ?? '';
    if (url.isEmpty) return '';
    if (cacheKey == null || cacheKey.isEmpty) return url;

    final uri = Uri.tryParse(url);
    if (uri == null) return url;

    final updatedQuery = Map<String, String>.from(uri.queryParameters)
      ..['v'] = cacheKey;
    return uri.replace(queryParameters: updatedQuery).toString();
  }

  ImageProvider<Object>? buildOptimizedNetworkImageProvider(
    String? rawUrl, {
    int? cacheWidth,
    int? cacheHeight,
    String? cacheKey,
  }) {
    final resolvedUrl = withCacheBuster(rawUrl, cacheKey: cacheKey);
    if (resolvedUrl.isEmpty) return null;

    final baseProvider = NetworkImage(resolvedUrl);
    if (cacheWidth == null && cacheHeight == null) {
      return baseProvider;
    }

    return ResizeImage(
      baseProvider,
      width: cacheWidth,
      height: cacheHeight,
    );
  }
