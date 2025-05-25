import 'package:flutter/material.dart';

class TopNotificationBanner extends StatefulWidget {
  final String message;
  final VoidCallback onTap;

  const TopNotificationBanner({
    Key? key,
    required this.message,
    required this.onTap,
  }) : super(key: key);

  @override
  _TopNotificationBannerState createState() => _TopNotificationBannerState();
}

class _TopNotificationBannerState extends State<TopNotificationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _offsetAnimation = Tween<Offset>(
      begin: Offset(0.0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    // Hide after 5 seconds
    Future.delayed(Duration(seconds: 5), () {
      if (mounted) {
        _controller.reverse().then((_) {
          if (mounted) {
            // Notify parent to remove
            if (Navigator.canPop(context)) Navigator.pop(context);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SlideTransition(
        position: _offsetAnimation,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: double.infinity,
            margin: EdgeInsets.all(8),
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.green[700],
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.notifications, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.message,
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
