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
  bool _isFlashing = false;
  double _flashTimer = 0;
  final Random _random = Random();

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

  void _triggerFlash() {
    _isFlashing = true;
    _flashTimer = 0.15;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_isFlashing) {
      _flashTimer -= dt;
      if (_flashTimer <= 0) _isFlashing = false;
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Ball) {
      final game = findGame()! as BallBounceBlitz;
      
      if (isHard) {
        hits--;
        if (hits > 0) {
          _triggerFlash();
          // Emit hit particles
          game.particleEmitter.emitBurst(position + size / 2, const Color(0xFFFFFFFF), count: 5);
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

    // Flash effect when hit but not destroyed
    if (_isFlashing) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        Paint()..color = Colors.white.withOpacity(0.8),
      );
      return;
    }

    // Base color - darker if damaged hard brick
    final baseColor = isHard && hits > 0 ? color.withOpacity(0.6) : color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      Paint()..color = baseColor,
    );

    // Hard brick crack pattern with depth
    if (isHard && hits > 0) {
      final crackPaint = Paint()
        ..color = Colors.black.withOpacity(0.5)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(size.x * 0.2, 0),
        Offset(size.x * 0.5, size.y),
        crackPaint,
      );
      canvas.drawLine(
        Offset(size.x * 0.8, 0),
        Offset(size.x * 0.4, size.y),
        crackPaint,
      );
      canvas.drawLine(
        Offset(size.x * 0.3, size.y * 0.3),
        Offset(size.x * 0.7, size.y * 0.7),
        crackPaint..strokeWidth = 2,
      );
      // Shadow effect
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        Paint()..color = Colors.black.withOpacity(0.3),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.deflate(2), const Radius.circular(3)),
        Paint()..color = baseColor,
      );
    }

    // Top highlight gradient
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x55FFFFFF), Color(0x00000000)],
        ).createShader(rect),
    );

    // Border with glow for hard bricks
    final borderPaint = Paint()
      ..color = isHard ? Colors.white.withOpacity(0.4) : Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isHard ? 2 : 1;
    if (isHard) {
      borderPaint.maskFilter = const MaskFilter.blur(BlurStyle.outer, 3);
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      borderPaint,
    );
  }
}