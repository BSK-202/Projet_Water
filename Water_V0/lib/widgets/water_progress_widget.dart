import 'package:flutter/material.dart';
import 'dart:math' as math;

class WaterProgressWidget extends StatelessWidget {
  final int currentAmount;
  final int goalAmount;

  const WaterProgressWidget({
    Key? key,
    required this.currentAmount,
    required this.goalAmount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = (currentAmount / goalAmount).clamp(0.0, 1.0);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withOpacity(0.8),
            theme.colorScheme.secondary.withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Consommation d\'eau',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(percentage * 100).toInt()}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Cercle d'arrière-plan
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
                
                // Indicateur de progression
                CustomPaint(
                  size: const Size(180, 180),
                  painter: WaterProgressPainter(
                    percentage: percentage,
                    color: Colors.white,
                  ),
                ),
                
                // Contenu central
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$currentAmount',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'ml',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Objectif: $goalAmount ml',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WaterProgressPainter extends CustomPainter {
  final double percentage;
  final Color color;

  WaterProgressPainter({
    required this.percentage,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    
    // Dessiner l'arc de progression
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12.0
      ..strokeCap = StrokeCap.round;
    
    // Dessiner l'arc de progression (de haut en sens horaire)
    canvas.drawArc(
      rect,
      -math.pi / 2, // Commencer à midi
      2 * math.pi * percentage, // Angle basé sur le pourcentage
      false,
      paint,
    );
    
    // Ajouter des gouttes d'eau animées (simulées ici)
    if (percentage > 0.1) {
      final dropPaint = Paint()
        ..color = color.withOpacity(0.7)
        ..style = PaintingStyle.fill;
      
      // Dessiner quelques gouttes à différentes positions sur l'arc
      for (int i = 0; i < 5; i++) {
        final angle = -math.pi / 2 + (2 * math.pi * percentage * i / 5);
        final dropCenter = Offset(
          center.dx + (radius - 6) * math.cos(angle),
          center.dy + (radius - 6) * math.sin(angle),
        );
        
        canvas.drawCircle(dropCenter, 4, dropPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

