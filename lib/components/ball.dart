import 'dart:math';
import 'package:flame/components.dart';
import 'components/paddle.dart';

class BallTrail extends PositionComponent {
  final Ball ball;
  final int trailLength;
  final List<Vector2> positions = [];
  final Random _random = Random();

  BallTrail({required this.ball, this.trailLength = 8});

  @override
  void update(double dt) {
    super.update(dt);
    if (ball.isLaunched) {
      positions.insert(0, ball.position.clone());
      if (positions.length > trailLength) {
        positions.removeLast();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (positions.isEmpty) return;
    
    for (int i = positions.length - 1; i >= 0; i--) {
      final pos = positions[i];
      final alpha = (1 - i / trailLength) * 0.6;
      final radius = 10 * (1 - i / trailLength);
      
      // Neon glow effect
      final gradient = RadialGradient(
        colors: [
          const Color(0xFF00D9FF).withOpacity(alpha),
          const Color(0xFF00D9FF).withOpacity(alpha * 0.3),
          Color(0x00000000),
        ],
        stops: const [0.0, 0.5, 1.0],
      );
      
      final rect = Rect.fromCircle(center: pos, radius: radius + 4);
      canvas.drawCircle(
        pos,
        radius + 4,
        Paint()..shader = gradient.createShader(rect),
      );
      canvas.drawCircle(
        pos,
        radius,
        Paint()..color = const Color(0xFF00D9FF).withOpacity(alpha),
      );
    }
  }
}

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