import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../game/ball_bounce_blitz.dart';
import 'ball.dart';

class Enemy extends PositionComponent with CollisionCallbacks {
  final double baseSpeed;
  final Vector2 direction;
  final Random _random = Random();
  double _huntTimer = 0;
  bool _isHunting = false;
  Vector2? _targetPosition;

  Enemy({required Vector2 position, required double speed})
      : baseSpeed = speed,
        direction = Vector2(_random.nextDouble() * 2 - 1, _random.nextDouble() * 2 - 1)..normalize(),
        super(position: position, size: Vector2(30, 30));

  @override
  Future<void> onLoad() async {
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    _huntTimer += dt;
    
    // Smart AI: Sometimes target the ball
    if (_random.nextDouble() < 0.005) {
      _isHunting = !_isHunting;
    }
    
    if (_isHunting && _huntTimer > 2) {
      _huntTimer = 0;
      _isHunting = false;
    }
    
    // Move
    position += direction * baseSpeed * dt;
    
    // Bounce off walls
    if (position.x <= 0 || position.x >= (findGame()?.size.x ?? 400) - size.x) {
      direction.x *= -1;
    }
    if (position.y <= 0 || position.y >= (findGame()?.size.y ?? 600) - size.y) {
      direction.y *= -1;
    }
    
    // Slight homing towards ball when hunting
    if (_isHunting) {
      final game = findGame() as BallBounceBlitz?;
      if (game != null && game.ball.isLaunched) {
        final toBall = game.ball.position - position;
        if (toBall.length > 0) {
          final homingStrength = 0.02;
          direction = (direction + toBall.normalized() * homingStrength)..normalize();
        }
      }
    }
    
    position.x = position.x.clamp(0, (findGame()?.size.x ?? 400) - size.x);
    position.y = position.y.clamp(0, (findGame()?.size.y ?? 600) - size.y);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Ball) {
      final game = findGame() as BallBounceBlitz;
      game.lives--;
      other.reset();
      if (game.lives <= 0) {
        game.isGameOver = true;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    // Enemy with pulsing glow
    final pulse = sin(_random.nextDouble() * 3) * 0.2 + 0.8;
    
    // Outer glow
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 2 + 4,
      Paint()..color = const Color(0xFFFF4444).withOpacity(0.3 * pulse),
    );
    
    // Main body
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 2,
      Paint()..color = const Color(0xFFFF4444),
    );
    
    // Eyes that look at ball
    final game = findGame() as BallBounceBlitz?;
    Vector2 lookDir = direction;
    if (game != null && game.ball.isLaunched) {
      lookDir = (game.ball.position - position).normalized();
    }
    
    final eyeOffset = lookDir * 3;
    canvas.drawCircle(
      Offset(size.x * 0.3 + eyeOffset.x, size.y * 0.35 + eyeOffset.y),
      4,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(size.x * 0.7 + eyeOffset.x, size.y * 0.35 + eyeOffset.y),
      4,
      Paint()..color = Colors.white,
    );
    
    // Angry eyebrows
    canvas.drawLine(
      Offset(size.x * 0.2, size.y * 0.25),
      Offset(size.x * 0.4, size.y * 0.3),
      Paint()..color = Colors.black..strokeWidth = 2,
    );
    canvas.drawLine(
      Offset(size.x * 0.8, size.y * 0.25),
      Offset(size.x * 0.6, size.y * 0.3),
      Paint()..color = Colors.black..strokeWidth = 2,
    );
  }
}