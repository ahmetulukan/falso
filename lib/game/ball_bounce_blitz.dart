import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/collisions.dart';
import 'components/ball.dart';
import 'components/paddle.dart';
import 'components/brick.dart';
import 'components/enemy.dart';
import 'systems/score_manager.dart';
import 'systems/level_manager.dart';

class BallBounceBlitz extends FlameGame with TapEvents, HasCollisionDetection {
  late Ball ball;
  late Paddle paddle;
  final List<Brick> bricks = [];
  final List<Enemy> enemies = [];
  final ScoreManager scoreManager = ScoreManager();
  final LevelManager levelManager = LevelManager();
  final Random _random = Random();
  
  int score = 0;
  int lives = 3;
  int level = 1;
  bool isGameOver = false;
  bool isPaused = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _initLevel();
  }

  void _initLevel() {
    // Clear existing
    bricks.clear();
    enemies.clear();
    
    // Add paddle
    paddle = Paddle();
    paddle.anchor = Anchor.bottomCenter;
    paddle.position = Vector2(size.x / 2, size.y - 30);
    add(paddle);

    // Add ball
    ball = Ball(paddle: paddle);
    ball.position = Vector2(size.x / 2, size.y - 60);
    add(ball);

    // Add bricks grid
    _generateBricks();
    
    // Add enemies
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
    final colors = [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.purple,
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

  @override
  void onTapDown(TapDownEvent event) {
    if (isGameOver) {
      _restart();
    }
  }

  void _restart() {
    score = 0;
    lives = 3;
    level = 1;
    isGameOver = false;
    scoreManager.reset();
    levelManager.reset();
    removeAll(children.where((c) => c != paddle && c != ball));
    _initLevel();
  }

  void nextLevel() {
    level++;
    levelManager.levelUp();
    removeAll(children.where((c) => c is Ball || c is Brick || c is Enemy));
    ball = Ball(paddle: paddle);
    ball.position = Vector2(size.x / 2, size.y - 60);
    add(ball);
    _generateBricks();
    _spawnEnemies();
  }

  void loseLife() {
    lives--;
    if (lives <= 0) {
      isGameOver = true;
    } else {
      ball.reset();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isPaused || isGameOver) return;
    scoreManager.update(dt);
  }

  @override
  void render(Canvas canvas) {
    // Background
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), Paint()..color = const Color(0xFF1A1A2E));
    
    // Score & Lives UI
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    
    textPainter.text = TextSpan(
      text: 'Score: $score | Lives: $lives | Level: $level',
      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, Vector2(10, 10).toOffset());
    
    if (isGameOver) {
      textPainter.text = const TextSpan(
        text: 'GAME OVER\nTap to Restart',
        style: TextStyle(color: Colors.red, fontSize: 32, fontWeight: FontWeight.bold),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(size.x / 2 - 100, size.y / 2 - 50));
    }
  }
}

extension on Vector2 {
  Offset toOffset() => Offset(x, y);
}