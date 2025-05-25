import 'package:flutter/material.dart';

class NotificationIcon extends StatelessWidget {
  final int unreadNotifications;
  final VoidCallback onTap;

  const NotificationIcon({
    super.key,
    required this.unreadNotifications,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        // Trigger the onTap callback when the icon is tapped
        onTap();
      },
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            radius: 24,
            child: Icon(
              Icons.notifications_none,
              color: theme.colorScheme.primary,
            ),
          ),
          if (unreadNotifications > 0)
            Positioned(
              right: 4,
              top: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                child: Text(
                  '$unreadNotifications',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
