import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/ball_bounce_blitz.dart';
import 'ball.dart';
import 'enemy.dart';

/// Shield Barrier - protects from one enemy hit
class ShieldBarrier extends PositionComponent with CollisionCallbacks {
  double _pulseTimer = 0;
  final Random _random = Random();
  bool _isActive = true;
  int _hitsRemaining = 1;

  ShieldBarrier() : super(size: Vector2(60, 20));

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    _pulseTimer += dt;
    
    // Pulsing animation
    final pulse = sin(_pulseTimer * 8) * 0.15 + 1;
    size = Vector2(60 * pulse, 20);
    
    // Follow ball position (centered above ball)
    final game = findGame() as BallBounceBlitz?;
    if (game != null && game.ball.isLaunched) {
      position = game.ball.position + Vector2(-30, -40);
    }
    
    if (!_isActive) {
      removeFromParent();
    }
  }

  void hit() {
    _hitsRemaining--;
    if (_hitsRemaining <= 0) {
      _isActive = false;
      final game = findGame() as BallBounceBlitz;
      game.particleEmitter.emitBurst(position + size / 2, const Color(0xFF00FFFF), count: 20);
    } else {
      // Flash and tint
      _pulseTimer = 0;
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Enemy) {
      // Absorb enemy hit
      other.removeFromParent();
      hit();
    }
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final center = Offset(size.x / 2, size.y / 2);
    
    // Outer glow
    final glowPaint = Paint()
      ..color = const Color(0xFF00FFFF).withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(10)),
      glowPaint,
    );
    
    // Shield gradient
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF00FFFF).withOpacity(0.9),
        const Color(0xFF0088CC).withOpacity(0.7),
      ],
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(10)),
      Paint()..shader = gradient.createShader(rect),
    );
    
    // Inner highlight
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(3), const Radius.circular(8)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x77FFFFFF), Color(0x00000000)],
        ).createShader(rect.deflate(3)),
    );
    
    // Border
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(10)),
      Paint()
        ..color = Colors.white.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    
    // Shield icon
    final textPainter = TextPainter(
      text: const TextSpan(
        text: '🛡',
        style: TextStyle(fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );
  }
}

/// Lightning Bolt - destroys all enemies in path
class LightningBolt extends PositionComponent {
  double _lifetime = 0;
  double _flickerTimer = 0;
  bool _isActive = true;
  final Vector2 targetPosition;
  final Random _random = Random();
  late List<Offset> _boltPoints;

  LightningBolt({required Vector2 start, required this.targetPosition}) 
      : super(position: start);

  @override
  Future<void> onLoad() async {
    _generateBolt();
  }

  void _generateBolt() {
    _boltPoints = [];
    final steps = 8;
    final dx = (targetPosition.x - position.x) / steps;
    final dy = (targetPosition.y - position.y) / steps;
    
    for (int i = 0; i <= steps; i++) {
      final jitter = (i > 0 && i < steps) ? (_random.nextDouble() - 0.5) * 30 : 0.0;
      _boltPoints.add(Offset(
        position.x + dx * i + jitter,
        position.y + dy * i,
      ));
    }
    
    // Destroy enemies along the bolt
    final game = findGame() as BallBounceBlitz?;
    if (game != null) {
      for (int i = game.enemies.length - 1; i >= 0; i--) {
        final enemy = game.enemies[i];
        // Check if enemy is near any bolt segment
        for (int j = 0; j < _boltPoints.length - 1; j++) {
          final p1 = _boltPoints[j];
          final p2 = _boltPoints[j + 1];
          final dist = _distToSegment(enemy.position.toOffset(), p1, p2);
          if (dist < 40) {
            game.particleEmitter.emitBurst(enemy.position + enemy.size / 2, const Color(0xFFFFEE00), count: 15);
            enemy.removeFromParent();
            game.enemies.removeAt(i);
            game.score += 50;
            break;
          }
        }
      }
    }
  }

  double _distToSegment(Offset p, Offset a, Offset b) {
    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;
    final lenSq = dx * dx + dy * dy;
    if (lenSq == 0) return (p - a).distance;
    var t = ((p.dx - a.dx) * dx + (p.dy - a.dy) * dy) / lenSq;
    t = t.clamp(0, 1);
    return Offset(a.dx + t * dx, a.dy + t * dy).distance;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _lifetime += dt;
    _flickerTimer += dt;
    
    if (_flickerTimer > 0.05) {
      _flickerTimer = 0;
      _generateBolt(); // Regenerate for flicker effect
    }
    
    if (_lifetime > 0.4) {
      _isActive = false;
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    if (_boltPoints.length < 2) return;
    
    final alpha = (1 - _lifetime / 0.4).clamp(0.0, 1.0);
    
    // Glow layer
    final glowPaint = Paint()
      ..color = const Color(0xFFAAFFFF).withOpacity(alpha * 0.5)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 8);
    
    final path = Path()..moveTo(_boltPoints[0].dx, _boltPoints[0].dy);
    for (int i = 1; i < _boltPoints.length; i++) {
      path.lineTo(_boltPoints[i].dx, _boltPoints[i].dy);
    }
    canvas.drawPath(path, glowPaint);
    
    // Core layer
    final corePaint = Paint()
      ..color = const Color(0xFFFFFFFF).withOpacity(alpha)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, corePaint);
  }
}

/// Magnet PowerUp - attracts nearby power-ups
class MagnetField extends PositionComponent {
  double _lifetime = 0;
  double _rotateAngle = 0;
  final double _radius = 100;

  MagnetField() : super(size: Vector2(200, 200));

  @override
  void update(double dt) {
    super.update(dt);
    _lifetime += dt;
    _rotateAngle += dt * 2;
    
    // Follow paddle
    final game = findGame() as BallBounceBlitz?;
    if (game != null) {
      position = game.paddle.position + Vector2(-50, -50);
    }
    
    // Attract nearby power-ups
    if (game != null) {
      for (final pu in game.powerUps) {
        final toMagnet = position + size / 2 - pu.position;
        final dist = toMagnet.length;
        if (dist < _radius && dist > 5) {
          pu.position += toMagnet.normalized() * 200 * dt;
        }
      }
    }
    
    if (_lifetime > 5) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    final alpha = (1 - _lifetime / 5) * 0.3;
    
    // Draw magnetic field lines
    for (int i = 0; i < 4; i++) {
      final angle = _rotateAngle + i * pi / 2;
      final paint = Paint()
        ..color = const Color(0xFFFF88DC).withOpacity(alpha)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: _radius * (0.3 + i * 0.2)),
        angle,
        pi * 1.5,
        false,
        paint,
      );
    }
    
    // Center glow
    canvas.drawCircle(
      center,
      15,
      Paint()..color = const Color(0xFFFF88DC).withOpacity(alpha * 0.5),
    );
  }
}