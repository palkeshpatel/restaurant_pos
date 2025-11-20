import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.backgroundColor ?? Theme.of(context).colorScheme.primary;

    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty && !_imageError) {
      return CircleAvatar(
        radius: widget.radius,
        backgroundColor: bgColor,
        backgroundImage: NetworkImage(widget.imageUrl!),
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

