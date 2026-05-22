import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';

class Particle extends PositionComponent {
  final Vector2 velocity;
  final double life;
  double _age = 0;
  final Color color;
  final double radius;

  Particle({
    required Vector2 position,
    required this.velocity,
    required this.life,
    required this.color,
    this.radius = 4,
  }) : super(position: position, size: Vector2.all(radius * 2));

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    if (_age >= life) {
      removeFromParent();
      return;
    }
    position += velocity * dt;
    velocity *= 0.95;
  }

  @override
  void render(Canvas canvas) {
    final alpha = (1 - _age / life).clamp(0.0, 1.0);
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      radius * (1 - _age / life),
      Paint()..color = color.withOpacity(alpha),
    );
  }
}

class ParticleEmitter {
  final FlameGame game;
  final Random _random = Random();

  ParticleEmitter(this.game);

  void emitBurst(Vector2 position, Color color, {int count = 12}) {
    for (int i = 0; i < count; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = 50 + _random.nextDouble() * 150;
      final particle = Particle(
        position: position.clone(),
        velocity: Vector2(cos(angle), sin(angle)) * speed,
        life: 0.3 + _random.nextDouble() * 0.4,
        color: color,
        radius: 2 + _random.nextDouble() * 4,
      );
      game.add(particle);
    }
  }
}