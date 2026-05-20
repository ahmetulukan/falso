import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'components/paddle.dart';

class Ball extends PositionComponent with HasGameRef, TapCallbacks {
  final Paddle paddle;
  double speed = 300;
  Vector2 velocity = Vector2.zero();
  bool isLaunched = false;
  
  Ball({required this.paddle});

  @override
  Future<void> onLoad() async {
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isLaunched) {
      position = paddle.position + Vector2(0, -20);
      return;
    }
    
    position += velocity * dt;
    
    // Wall collisions
    if (position.x <= 10 || position.x >= gameRef.size.x - 10) {
      velocity.x *= -1;
      position.x = position.x.clamp(10, gameRef.size.x - 10);
    }
    if (position.y <= 10) {
      velocity.y *= -1;
      position.y = 10;
    }
    
    // Bottom - lose life
    if (position.y >= gameRef.size.y) {
      gameRef.loseLife();
      reset();
    }
  }

  void launch() {
    if (isLaunched) return;
    isLaunched = true;
    final random = Random();
    final angle = -pi / 4 - random.nextDouble() * pi / 2;
    velocity = Vector2(cos(angle), sin(angle)) * speed;
  }

  void reset() {
    isLaunched = false;
    position = paddle.position + Vector2(0, -20);
    velocity = Vector2.zero();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    size.x = 20;
    size.y = 20;
  }

  @override
  bool onTapDown(TapDownEvent event) {
    if (!isLaunched) launch();
    return true;
  }
}