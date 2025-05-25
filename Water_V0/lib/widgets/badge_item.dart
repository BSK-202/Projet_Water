import 'package:flutter/material.dart';

class BadgeItem extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;
  final bool isEarned;
  final bool isLocked;
  final double? progress;
  
  const BadgeItem({
    Key? key,
    required this.name,
    required this.icon,
    required this.color,
    required this.isEarned,
    this.isLocked = false,
    this.progress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Badge background
            Container(
              width: 75,
              height: 75,
              decoration: BoxDecoration(
                color: isEarned 
                    ? color.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isLocked
                    ? Icon(
                        Icons.lock,
                        color: Colors.grey,
                        size: 30,
                      )
                    : Icon(
                        icon,
                        color: isEarned ? color : Colors.grey,
                        size: 36,
                      ),
              ),
            ),
            
            // Progress indicator (if in progress)
            if (progress != null && !isEarned && !isLocked)
              SizedBox(
                width: 75,
                height: 75,
                child: CircularProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeWidth: 3,
                ),
              ),
              
            // Checkmark for earned badges
            if (isEarned)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
       Positioned(
        top: 20,
        left: 14,
        bottom: 4,
        child:
        
       Text(        
          name,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isEarned ? color : Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),)
      ],
    );
  }
}

