class LevelManager {
  int _level = 1;
  double _difficultyMultiplier = 1.0;

  int get level => _level;
  double get difficulty => _difficultyMultiplier;

  void levelUp() {
    _level++;
    _difficultyMultiplier = 1.0 + (_level - 1) * 0.2;
  }

  void reset() {
    _level = 1;
    _difficultyMultiplier = 1.0;
  }
}