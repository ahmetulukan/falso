import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import '../game/ball_bounce_blitz.dart';
import 'ball.dart';
import 'paddle.dart';
import 'shield.dart';

enum PowerUpType { expandPaddle, shrinkBall, multiBall, slowMotion, extraLife, shield, lightning, magnet }

class PowerUp extends PositionComponent with CollisionCallbacks {
  final PowerUpType type;
  final Random _random = Random();
  double speed = 100;

  static final _colors = {
    PowerUpType.expandPaddle: const Color(0xFF00FF88),
    PowerUpType.shrinkBall: const Color(0xFFFF6B6B),
    PowerUpType.multiBall: const Color(0xFF4ECDC4),
    PowerUpType.slowMotion: const Color(0xFFFFE66D),
    PowerUpType.extraLife: const Color(0xFFFF88DC),
    PowerUpType.shield: const Color(0xFF00FFFF),
    PowerUpType.lightning: const Color(0xFFFFEE00),
    PowerUpType.magnet: const Color(0xFFFF44AA),
  };

  static final _labels = {
    PowerUpType.expandPaddle: '➕',
    PowerUpType.shrinkBall: '➖',
    PowerUpType.multiBall: '✦',
    PowerUpType.slowMotion: '⏱',
    PowerUpType.extraLife: '❤',
    PowerUpType.shield: '🛡',
    PowerUpType.lightning: '⚡',
    PowerUpType.magnet: '🧲',
  };

  PowerUp({required Vector2 position})
      : type = PowerUpType.values[_random.nextInt(PowerUpType.values.length)],
        super(position: position, size: Vector2(28, 28));

  @override
  Future<void> onLoad() async {
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y += speed * dt;
    if (position.y > (findGame()?.size.y ?? 800)) {
      removeFromParent();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Paddle) {
      _applyEffect();
      removeFromParent();
    }
  }

  void _applyEffect() {
    final game = findGame() as BallBounceBlitz;
    switch (type) {
      case PowerUpType.expandPaddle:
        game.paddle.size.x = (game.paddle.size.x * 1.4).clamp(60, 180);
        break;
      case PowerUpType.shrinkBall:
        game.ball.speed = (game.ball.speed * 0.85).clamp(150, 600);
        break;
      case PowerUpType.multiBall:
        for (int i = 0; i < 2; i++) {
          final extraBall = Ball(paddle: game.paddle);
          extraBall.position = game.ball.position.clone();
          extraBall.velocity = Vector2(
            (Random().nextDouble() - 0.5) * 400,
            -Random().nextDouble() * 300,
          )..normalize() * extraBall.speed;
          extraBall.isLaunched = true;
          game.add(extraBall);
        }
        break;
      case PowerUpType.slowMotion:
        for (final enemy in game.enemies) {
          enemy.speed *= 0.4;
        }
        break;
      case PowerUpType.extraLife:
        game.lives = (game.lives + 1).clamp(1, 5);
        break;
      case PowerUpType.shield:
        final shield = ShieldBarrier();
        game.add(shield);
        break;
      case PowerUpType.lightning:
        final enemies = game.enemies.toList();
        if (enemies.isNotEmpty) {
          final target = enemies[_random.nextInt(enemies.length)].position;
          final bolt = LightningBolt(start: game.ball.position.clone(), targetPosition: target);
          game.add(bolt);
        } else {
          // If no enemies, strike random position
          final randomPos = Vector2(
            _random.nextDouble() * game.size.x,
            _random.nextDouble() * 200 + 50,
          );
          final bolt = LightningBolt(start: game.ball.position.clone(), targetPosition: randomPos);
          game.add(bolt);
        }
        break;
      case PowerUpType.magnet:
        final magnet = MagnetField();
        game.add(magnet);
        break;
    }
  }

  @override
  void render(Canvas canvas) {
    final color = _colors[type]!;
    final label = _labels[type]!;

    // Glow effect
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 2 + 4,
      Paint()..color = color.withOpacity(0.4)..maskFilter = const MaskFilter.blur(BlurStyle.outer, 6),
    );
    
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 2,
      Paint()..color = color.withOpacity(0.9),
    );
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 2 - 2,
      Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final textPainter = TextPainter(
      text: TextSpan(text: label, style: const TextStyle(fontSize: 14, color: Colors.white)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(size.x / 2 - textPainter.width / 2, size.y / 2 - textPainter.height / 2),
    );
  }
}