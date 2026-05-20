class ScoreManager {
  int _score = 0;
  int _multiplier = 1;
  double _timeSinceLastBrick = 0;

  int get score => _score;
  int get multiplier => _multiplier;

  void addScore(int points) {
    _score += points * _multiplier;
    _multiplier = (_multiplier + 1).clamp(1, 10);
    _timeSinceLastBrick = 0;
  }

  void update(double dt) {
    _timeSinceLastBrick += dt;
    if (_timeSinceLastBrick > 3) {
      _multiplier = 1;
    }
  }

  void reset() {
    _score = 0;
    _multiplier = 1;
    _timeSinceLastBrick = 0;
  }
}