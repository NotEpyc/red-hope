import 'package:flutter/material.dart';
import 'dart:io';
import '../../theme/theme.dart';
import '../../utils/responsive_utils.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final String? imagePath;
  final VoidCallback? onProfileTap;
  final VoidCallback? onNotificationTap;
  final bool showNotificationBadge;
  final int notificationCount;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.subtitle,
    this.imagePath,
    this.onProfileTap,
    this.onNotificationTap,
    this.showNotificationBadge = true,
    this.notificationCount = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.05),
      titleSpacing: 0,
      automaticallyImplyLeading: false,
      leadingWidth: 0,
      title: Row(
        children: [
          GestureDetector(
            onTap: onProfileTap,
            child: Container(
              margin: const EdgeInsets.only(left: 16),
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.lightDividerColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
                image: imagePath != null
                    ? DecorationImage(
                        image: FileImage(File(imagePath!)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: imagePath == null
                  ? Icon(
                      Icons.person,
                      color: AppTheme.primaryColor,
                      size: 24,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: ResponsiveUtils.getSmallTextSize(context),
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: AppTheme.labelTextStyle.copyWith(
                    fontSize: ResponsiveUtils.getBodySize(context),
                    color: Colors.black87,
                  ),
                ),
            ],
          ),
        ],
      ),
      actions: [
        if (onNotificationTap != null)
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                onPressed: onNotificationTap,
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.black87,
                  size: 28,
                ),
              ),
              if (showNotificationBadge && notificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Text(
                      notificationCount > 9 ? '9+' : notificationCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
