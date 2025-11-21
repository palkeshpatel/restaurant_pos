import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class AvatarWidget extends StatefulWidget {
  final String? imageUrl;
  final String initials;
  final double radius;
  final Color? backgroundColor;

  const AvatarWidget({
    super.key,
    this.imageUrl,
    required this.initials,
    this.radius = 30,
    this.backgroundColor,
  });

  @override
  State<AvatarWidget> createState() => _AvatarWidgetState();
}

class _AvatarWidgetState extends State<AvatarWidget> {
  bool _imageError = false;
  String? _resolvedUrl;

  @override
  void initState() {
    super.initState();
    _resolveImageUrl();
  }

  @override
  void didUpdateWidget(covariant AvatarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _imageError = false;
      _resolvedUrl = null;
      _resolveImageUrl();
    }
  }

  Future<void> _resolveImageUrl() async {
    final originalUrl = widget.imageUrl;
    if (originalUrl == null || originalUrl.isEmpty) return;

    String resolvedUrl = originalUrl;
    if (originalUrl.contains('localhost')) {
      final storedBase = await StorageService.getBaseUrl();
      final fallbackBase = storedBase ?? 'http://10.0.2.2:8000';
      try {
        final avatarUri = Uri.parse(originalUrl);
        final baseUri = Uri.parse(fallbackBase);
        final normalized = avatarUri.replace(
          scheme: baseUri.scheme,
          host: baseUri.host,
          port: baseUri.hasPort ? baseUri.port : avatarUri.port,
        );
        resolvedUrl = normalized.toString();
      } catch (_) {
        resolvedUrl = originalUrl.replaceFirst('localhost', '10.0.2.2');
      }
    }

    if (mounted) {
      setState(() {
        _resolvedUrl = resolvedUrl;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor =
        widget.backgroundColor ?? Theme.of(context).colorScheme.primary;

    final displayUrl = _resolvedUrl ?? widget.imageUrl;

    if (displayUrl != null && displayUrl.isNotEmpty && !_imageError) {
      return CircleAvatar(
        radius: widget.radius,
        backgroundColor: bgColor,
        backgroundImage: NetworkImage(displayUrl),
        onBackgroundImageError: (exception, stackTrace) {
          if (mounted) {
            setState(() {
              _imageError = true;
            });
          }
        },
      );
    }

    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: bgColor,
      child: Text(
        widget.initials,
        style: TextStyle(
          fontSize: widget.radius * 0.6,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}
