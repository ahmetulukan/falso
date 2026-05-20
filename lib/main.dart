import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'game/ball_bounce_blitz.dart';

void main() {
  runApp(const MaterialApp(home: GameWidget(game: BallBounceBlitz())));
}