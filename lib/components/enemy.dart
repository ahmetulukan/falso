import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

class Enemy extends PositionComponent with CollisionCallbacks {
  final double speed;
  final Vector2 direction;
  final Random _random = Random();

  Enemy({required Vector2 position, required this.speed})
      : direction = Vector2(_random.nextDouble() * 2 - 1, _random.nextDouble() * 2 - 1)..normalize(),
        super(position: position, size: Vector2(30, 30));

  @override
  Future<void> onLoad() async {
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // Random direction change
    if (_random.nextDouble() < 0.01) {
      direction.x = _random.nextDouble() * 2 - 1;
      direction.y = _random.nextDouble() * 2 - 1;
      direction.normalize();
    }
    
    position += direction * speed * dt;
    
    // Bounce off walls
    if (position.x <= 0 || position.x >= (findGame()?.size.x ?? 400) - size.x) {
      direction.x *= -1;
    }
    if (position.y <= 0 || position.y >= (findGame()?.size.y ?? 600) - size.y) {
      direction.y *= -1;
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
    // Enemy skull-like appearance
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 2,
      Paint()..color = const Color(0xFFFF4444),
    );
    // Eyes
    canvas.drawCircle(Offset(size.x * 0.3, size.y * 0.35), 4, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(size.x * 0.7, size.y * 0.35), 4, Paint()..color = Colors.white);
  }
}

