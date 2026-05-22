import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'ball.dart';
import 'paddle.dart';

class ScorePopup extends PositionComponent {
  final int score;
  double _age = 0;
  final double lifetime = 0.8;

  ScorePopup({required Vector2 position, required this.score})
      : super(position: position);

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    position.y -= 30 * dt; // Float up
    
    if (_age >= lifetime) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final progress = _age / lifetime;
    final alpha = (1 - progress).clamp(0.0, 1.0);
    final scale = 1.0 + progress * 0.3;
    
    // Glow background
    final rect = Rect.fromCircle(center: position, radius: 20 + progress * 10);
    final gradient = RadialGradient(
      colors: [
        const Color(0xFFFFE66D).withOpacity(alpha * 0.5),
        Color(0x00000000),
      ],
    );
    canvas.drawCircle(position, 25 + progress * 10, Paint()..shader = gradient.createShader(rect));
    
    final textPainter = TextPainter(
      text: TextSpan(
        text: '+$score',
        style: TextStyle(
          color: const Color(0xFFFFE66D).withOpacity(alpha),
          fontSize: 18 * scale,
          fontWeight: FontWeight.bold,
          shadows: const [
            Shadow(color: Color(0xFFFF8800), blurRadius: 8),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );
  }
}