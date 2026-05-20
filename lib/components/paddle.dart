import 'package:flame/components.dart';
import 'package:flame/events.dart';

class Paddle extends PositionComponent with DragCallbacks, HasGameRef {
  double speed = 500;

  Paddle() : super(size: Vector2(100, 15));

  @override
  void update(double dt) {
    super.update(dt);
    position.x = position.x.clamp(0, gameRef.size.x - size.x);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    position.x += event.localDelta.x;
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      Paint()..color: const Color(0xFF00D9FF),
    );
  }
}