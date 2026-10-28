import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/app_user.dart';

class UserAvatar extends StatelessWidget {
  final AppUser? user;
  final String? name;
  final double radius;
  final bool showEditBadge;
  final VoidCallback? onEdit;
  final Color? borderColor;

  const UserAvatar({
    super.key,
    this.user,
    this.name,
    this.radius = 24,
    this.showEditBadge = false,
    this.onEdit,
    this.borderColor,
  });

  String get _initials {
    final effectiveName = user?.fullName ?? name ?? 'Utilisateur';
    final parts = effectiveName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'U';
  }

  // Consistent color based on user name
  Color get _avatarColor {
    final effectiveName = user?.fullName ?? name ?? '';
    final colors = [
      AppColors.primary,
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF0EA5E9), // Sky
      const Color(0xFF10B981), // Emerald
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFF59E0B), // Amber
    ];
    final hash = effectiveName.codeUnits.fold(0, (prev, elem) => prev + elem);
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final diameter = radius * 2;

    Widget avatarWidget = Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _avatarColor,
            _avatarColor.withValues(alpha: 0.8),
          ],
        ),
        border: Border.all(
          color: borderColor ?? Colors.white,
          width: borderColor != null ? 3 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          _initials,
          style: TextStyle(
            fontSize: radius * 0.75,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );

    if (showEditBadge) {
      avatarWidget = Stack(
        clipBehavior: Clip.none,
        children: [
          avatarWidget,
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: onEdit,
              child: Container(
                width: radius * 0.7,
                height: radius * 0.7,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.camera_alt,
                  size: radius * 0.38,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return avatarWidget;
  }
}
