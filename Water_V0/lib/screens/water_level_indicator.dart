import 'package:flutter/material.dart';
import 'dart:math' as math;

class WaterLevelIndicator extends StatelessWidget {
  final double percentage;
  final double size;
  
  const WaterLevelIndicator({
    Key? key,
    required this.percentage,
    required this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.2),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Water level
          ClipPath(
            clipper: WaveClipper(percentage),
            child: Container(
              width: size - 10,
              height: size - 10,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
          ),
          
          // Percentage text
          Text(
            '${(percentage * 100).toInt()}%',
            style: TextStyle(
              fontSize: size * 0.2,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          
          // Label
          Positioned(
            bottom: size * 0.3,
            child: Text(
              'Efficiency',
              style: TextStyle(
                fontSize: size * 0.1,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WaveClipper extends CustomClipper<Path> {
  final double percentage;
  
  WaveClipper(this.percentage);
  
  @override
  Path getClip(Size size) {
    final path = Path();
    final radius = size.width / 2;
    final center = Offset(size.width / 2, size.height / 2);
    
    // Calculate water level height
    final waterLevel = size.height - (size.height * percentage);
    
    // Start from the left edge at water level
    path.moveTo(0, waterLevel);
    
    // Draw wave pattern
    for (double i = 0; i <= size.width; i++) {
      path.lineTo(
        i, 
        waterLevel + math.sin(i / 10) * 5
      );
    }
    
    // Complete the path
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    
    // Clip to circle
    final circlePath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    
    return Path.combine(PathOperation.intersect, path, circlePath);
  }
  
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}

