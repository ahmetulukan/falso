import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

class Paddle extends PositionComponent with DragCallbacks, HasGameRef {
  double speed = 500;
  bool isWide = false;
  double originalWidth = 100;

  Paddle() : super(size: Vector2(100, 15));

  void expand() {
    originalWidth = size.x;
    size.x = (size.x * 1.4).clamp(60, 180);
    isWide = true;
  }

  void shrink() {
    size.x = (size.x * 0.7).clamp(60, 180);
  }

  void restore() {
    size.x = originalWidth;
    isWide = false;
  }

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
    
    // Gradient fill
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF00D9FF),
        const Color(0xFF0099CC),
      ],
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      Paint()..shader = gradient.createShader(rect),
    );
    
    // Glow effect when wide
    if (isWide) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        Paint()
          ..color = const Color(0xFF00FF88).withOpacity(0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 8),
      );
    }
    
    // Top highlight
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x55FFFFFF), Color(0x00000000)],
        ).createShader(rect),
    );
  }
}