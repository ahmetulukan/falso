import 'dart:math';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'components/ball.dart';
import 'components/paddle.dart';
import 'components/brick.dart';
import 'components/enemy.dart';
import 'components/power_up.dart';
import 'components/particle.dart';
import 'systems/score_manager.dart';
import 'systems/level_manager.dart';

class BallBounceBlitz extends FlameGame with TapEvents, HasCollisionDetection {
  late Ball ball;
  late Paddle paddle;
  final List<Brick> bricks = [];
  final List<Enemy> enemies = [];
  final List<PowerUp> powerUps = [];
  final ScoreManager scoreManager = ScoreManager();
  final LevelManager levelManager = LevelManager();
  final Random _random = Random();
  late ParticleEmitter particleEmitter;

  int score = 0;
  int lives = 3;
  int level = 1;
  bool isGameOver = false;
  bool isPaused = false;
  double screenShake = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    particleEmitter = ParticleEmitter(this);
    _initLevel();
  }

  void _initLevel() {
    bricks.clear();
    enemies.clear();
    powerUps.clear();

    paddle = Paddle();
    paddle.anchor = Anchor.bottomCenter;
    paddle.position = Vector2(size.x / 2, size.y - 30);
    add(paddle);

    ball = Ball(paddle: paddle);
    ball.position = Vector2(size.x / 2, size.y - 60);
    add(ball);

    _generateBricks();
    _spawnEnemies();
  }

  void _generateBricks() {
    final rows = 4 + (level ~/ 2);
    final cols = 6;
    final brickWidth = (size.x - 40) / cols;
    final brickHeight = 25.0;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final brick = Brick(
          position: Vector2(20 + c * brickWidth, 60 + r * brickHeight),
          size: Vector2(brickWidth - 4, brickHeight),
          color: _getBrickColor(r),
          points: (rows - r) * 10,
        );
        bricks.add(brick);
        add(brick);
      }
    }
  }

  Color _getBrickColor(int row) {
    const colors = [
      Color(0xFFE74C3C),
      Color(0xFFE67E22),
      Color(0xFFF1C40F),
      Color(0xFF2ECC71),
      Color(0xFF3498DB),
      Color(0xFF9B59B6),
    ];
    return colors[row % colors.length];
  }

  void _spawnEnemies() {
    final enemyCount = min(2 + level, 8);
    for (int i = 0; i < enemyCount; i++) {
      final enemy = Enemy(
        position: Vector2(
          50 + _random.nextDouble() * (size.x - 100),
          50 + _random.nextDouble() * 200,
        ),
        speed: 50 + _random.nextDouble() * 50 * level,
      );
      enemies.add(enemy);
      add(enemy);
    }
  }

  void _spawnPowerUp(Vector2 position) {
    if (_random.nextDouble() < 0.25) {
      final powerUp = PowerUp(position: position);
      powerUps.add(powerUp);
      add(powerUp);
    }
  }

  void _onBrickDestroyed(Brick brick) {
    particleEmitter.emitBurst(brick.position + brick.size / 2, brick.color, count: 15);
    _spawnPowerUp(brick.position + brick.size / 2);
    bricks.remove(brick);
    remove(brick);
    score += brick.points * scoreManager.multiplier;
    scoreManager.addScore(brick.points);

    if (bricks.isEmpty) {
      nextLevel();
    }
  }

  void _onBallLost() {
    screenShake = 0.3;
    lives--;
    if (lives <= 0) {
      isGameOver = true;
    } else {
      ball.reset();
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (isGameOver) {
      _restart();
    } else if (!ball.isLaunched) {
      ball.launch();
    }
  }

  void _restart() {
    score = 0;
    lives = 3;
    level = 1;
    isGameOver = false;
    scoreManager.reset();
    levelManager.reset();
    removeAll(children.where((c) =>
        c is Ball || c is Brick || c is Enemy || c is PowerUp || c is Particle));
    bricks.clear();
    enemies.clear();
    powerUps.clear();
    paddle.size.x = 100;
    _initLevel();
  }

  void nextLevel() {
    level++;
    levelManager.levelUp();
    paddle.size.x = (paddle.size.x * 0.9).clamp(60, 180);
    ball.speed = (ball.speed + 20).clamp(250, 600);
    removeAll(children.where((c) => c is Ball || c is Brick || c is Enemy || c is PowerUp));
    bricks.clear();
    enemies.clear();
    powerUps.clear();

    ball = Ball(paddle: paddle);
    ball.position = Vector2(size.x / 2, size.y - 60);
    add(ball);

    _generateBricks();
    _spawnEnemies();
  }

  void loseLife() => _onBallLost();

  @override
  void update(double dt) {
    super.update(dt);
    if (isPaused || isGameOver) return;
    scoreManager.update(dt);

    // Decay screen shake
    if (screenShake > 0) {
      screenShake -= dt;
    }
  }

  @override
  void render(Canvas canvas) {
    // Background with subtle gradient
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = const Color(0xFF1A1A2E),
    );

    // Grid lines for atmosphere
    final gridPaint = Paint()..color = Colors.white.withOpacity(0.03);
    for (double x = 0; x < size.x; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.y), gridPaint);
    }
    for (double y = 0; y < size.y; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.x, y), gridPaint);
    }

    // Apply screen shake offset
    if (screenShake > 0) {
      final shakeX = (_random.nextDouble() - 0.5) * 8 * screenShake;
      final shakeY = (_random.nextDouble() - 0.5) * 8 * screenShake;
      canvas.save();
      canvas.translate(shakeX, shakeY);
    }

    // Children render automatically

    if (screenShake > 0) {
      canvas.restore();
    }

    // UI Overlay
    _renderUI(canvas);
  }

  void _renderUI(Canvas canvas) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Top bar
    textPainter.text = TextSpan(
      text: '▶ Score: $score  |  ❤ Lives: $lives  |  ⭐ Level: $level',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(12, 10));

    // Multiplier indicator
    if (scoreManager.multiplier > 1) {
      textPainter.text = TextSpan(
        text: 'x${scoreManager.multiplier} COMBO!',
        style: TextStyle(
          color: const Color(0xFFFFE66D),
          fontSize: 18,
          fontWeight: FontWeight.bold,
          shadows: const [Shadow(color: Colors.orange, blurRadius: 10)],
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(size.x / 2 - textPainter.width / 2, 10));
    }

    if (isGameOver) {
      // Dark overlay
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.x, size.y),
        Paint()..color = Colors.black.withOpacity(0.7),
      );

      textPainter.text = const TextSpan(
        text: 'GAME OVER',
        style: TextStyle(
          color: Color(0xFFE74C3C),
          fontSize: 40,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(size.x / 2 - textPainter.width / 2, size.y / 2 - 60));

      textPainter.text = TextSpan(
        text: 'Final Score: $score',
        style: const TextStyle(color: Colors.white, fontSize: 24),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(size.x / 2 - textPainter.width / 2, size.y / 2));

      textPainter.text = const TextSpan(
        text: 'Tap to Restart',
        style: TextStyle(color: Color(0xFF00D9FF), fontSize: 18),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(size.x / 2 - textPainter.width / 2, size.y / 2 + 50));
    }
  }
}
