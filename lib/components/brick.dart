import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../game/ball_bounce_blitz.dart';
import 'ball.dart';

class Brick extends PositionComponent with CollisionCallbacks {
  final int points;
  final Color color;
  int hits;
  final bool isHard;

  Brick({
    required Vector2 position,
    required Vector2 size,
    required this.color,
    required this.points,
    this.hits = 1,
    this.isHard = false,
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
      
      if (isHard) {
        hits--;
        if (hits > 0) {
          // Flash effect
          return;
        }
      }
      
      game._onBrickDestroyed(this);

      // Bounce ball
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

    // Base color
    final baseColor = isHard && hits > 0 ? color.withOpacity(0.5) : color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      Paint()..color = baseColor,
    );

    // Hard brick crack pattern
    if (isHard && hits > 0) {
      canvas.drawLine(
        Offset(size.x * 0.3, 0),
        Offset(size.x * 0.5, size.y),
        Paint()..color = Colors.black.withOpacity(0.4)..strokeWidth = 2,
      );
      canvas.drawLine(
        Offset(size.x * 0.7, 0),
        Offset(size.x * 0.4, size.y),
        Paint()..color = Colors.black.withOpacity(0.3)..strokeWidth = 2,
      );
    }

    // Highlight gradient
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x55FFFFFF), Color(0x00000000)],
        ).createShader(rect),
    );

    // Border
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      Paint()
        ..color = Colors.white.withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isHard ? 2 : 1,
    );
  }
}