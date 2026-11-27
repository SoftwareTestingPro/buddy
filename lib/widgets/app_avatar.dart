import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// AppAvatar is a reliable, resilient avatar image widget that handles:
/// 1. Standard web/network URLs (Unsplash, CDN, etc.)
/// 2. Google OAuth profile pictures (lh3.googleusercontent.com) with referrer policies
/// 3. Uploaded/Camera captured data URIs (data:image/...;base64,...)
/// 4. Graceful letter or icon fallback on load error, 403, or empty URL
class AppAvatar extends StatelessWidget {
  final String avatarUrl;
  final String name;
  final double radius;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  const AppAvatar({
    super.key,
    required this.avatarUrl,
    this.name = '',
    this.radius = 20,
    this.width,
    this.height,
    this.borderRadius,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveWidth = width ?? (radius * 2);
    final effectiveHeight = height ?? (radius * 2);
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(radius);

    final cleanUrl = avatarUrl.trim();

    if (cleanUrl.isEmpty) {
      return _buildFallback(effectiveWidth, effectiveHeight, effectiveBorderRadius);
    }

    // 1. Check for data URI (base64 from camera capture / gallery file picker)
    if (cleanUrl.startsWith('data:') && cleanUrl.contains('base64,')) {
      try {
        final base64String = cleanUrl.split('base64,').last.trim();
        final bytes = base64Decode(base64String);
        return ClipRRect(
          borderRadius: effectiveBorderRadius,
          child: Image.memory(
            bytes,
            width: effectiveWidth,
            height: effectiveHeight,
            fit: fit,
            errorBuilder: (_, __, ___) => _buildFallback(effectiveWidth, effectiveHeight, effectiveBorderRadius),
          ),
        );
      } catch (e) {
        return _buildFallback(effectiveWidth, effectiveHeight, effectiveBorderRadius);
      }
    }

    // 2. Network image (Google avatar or external URL)
    return ClipRRect(
      borderRadius: effectiveBorderRadius,
      child: Image.network(
        cleanUrl,
        width: effectiveWidth,
        height: effectiveHeight,
        fit: fit,
        headers: const {
          'Accept': 'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildFallback(effectiveWidth, effectiveHeight, effectiveBorderRadius);
        },
      ),
    );
  }

  Widget _buildFallback(double w, double h, BorderRadius rad) {
    final initials = name.trim().isNotEmpty
        ? name.trim().split(' ').map((p) => p.isNotEmpty ? p[0].toUpperCase() : '').take(2).join()
        : '';

    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: AppTheme.secondary.withValues(alpha: 0.15),
        borderRadius: rad,
      ),
      alignment: Alignment.center,
      child: initials.isNotEmpty
          ? Text(
              initials,
              style: TextStyle(
                fontSize: (w * 0.4).clamp(10.0, 32.0),
                fontWeight: FontWeight.w800,
                color: AppTheme.secondary,
              ),
            )
          : Icon(
              Icons.person_rounded,
              size: (w * 0.55).clamp(14.0, 48.0),
              color: AppTheme.secondary,
            ),
    );
  }
}
