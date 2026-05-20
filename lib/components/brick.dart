import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import '../game/ball_bounce_blitz.dart';
import 'ball.dart';

class Brick extends PositionComponent with CollisionCallbacks {
  final int points;
  final Color color;

  Brick({
    required Vector2 position,
    required Vector2 size,
    required this.color,
    required this.points,
  }) : super(position: position, size: size);

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox());
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Ball) {
      final game = findGame()! as BallBounceBlitz;
      game.score += points;
      game.bricks.remove(this);
      removeFromParent();
      
      if (intersectionPoints.length >= 2) {
        final p1 = intersectionPoints.elementAt(0);
        final p2 = intersectionPoints.elementAt(1);
        final normal = (p2 - p1).normalized();
        final dot = other.velocity.dot(normal);
        if (dot < 0) {
          other.velocity = (other.velocity - normal * dot * 2)..normalize() * other.speed;
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      Paint()..color = color,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white.withOpacity(0.3), Colors.transparent],
        ).createShader(rect),
    );
  }
}