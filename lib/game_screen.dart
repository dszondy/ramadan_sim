import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FallingObjectGameScreen extends StatefulWidget {
  const FallingObjectGameScreen({
    super.key,
    required this.onGameOver,
    required this.playerAssetPath,
  });

  final ValueChanged<double> onGameOver;
  final String playerAssetPath;

  @override
  State<FallingObjectGameScreen> createState() =>
      _FallingObjectGameScreenState();
}

class _FallingObjectGameScreenState extends State<FallingObjectGameScreen> {
  static const double _playerBottomOffset = 24;
  static const int _obstacleCount = 8;
  static const double _playerAcceleration = 3000;
  static const double _playerMaxSpeed = 560;
  static const double _playerDrag = 2400;
  static const double _playerAspectRatio = 0.62;
  static const double _backgroundAspectRatio = 8.0;
  static const double _obstacleSize = 72;
  static const double _baseObstacleSpeed = 200;
  static const double _obstacleSpeedVariance = 130;
  static const double _difficultyRampPerSecond = 14;
  static const double _playerHitboxWidthFactor = 0.46;
  static const double _playerHitboxHeightFactor = 0.78;
  static const double _obstacleHitboxWidthFactor = 0.68;
  static const double _obstacleHitboxHeightFactor = 0.68;

  final math.Random _random = math.Random();
  final Stopwatch _stopwatch = Stopwatch();
  final FocusNode _keyboardFocusNode = FocusNode();

  Timer? _loopTimer;
  List<_FallingObstacle> _obstacles = const [];
  double _viewportWidth = 600;
  double _viewportHeight = 420;
  double _worldWidth = 1320;
  double _playerWorldX = 300;
  double _playerVelocity = 0;
  double _elapsedSeconds = 0;
  bool _gameOverTriggered = false;
  bool _moveLeftPressed = false;
  bool _moveRightPressed = false;
  double? _touchTargetWorldX;

  @override
  void initState() {
    super.initState();
    _resetGame();
    _stopwatch.start();
    _loopTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      _tick();
    });
  }

  @override
  void dispose() {
    _loopTimer?.cancel();
    _stopwatch.stop();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _resetGame() {
    _worldWidth = math.max(
      _viewportHeight * 0.5 * _backgroundAspectRatio,
      _viewportWidth + 1,
    );
    _playerWorldX = _worldWidth / 2;
    _playerVelocity = 0;
    _elapsedSeconds = 0;
    _gameOverTriggered = false;
    _moveLeftPressed = false;
    _moveRightPressed = false;
    _touchTargetWorldX = null;
    _obstacles = List.generate(_obstacleCount, _createObstacle);
  }

  double get _playerHeight => _viewportHeight * 0.25;

  double get _playerWidth => _playerHeight * _playerAspectRatio;

  Rect _playerHitbox(double playerCenterX) {
    final hitboxWidth = _playerWidth * _playerHitboxWidthFactor;
    final hitboxHeight = _playerHeight * _playerHitboxHeightFactor;
    final playerTop = _viewportHeight - _playerHeight - _playerBottomOffset;
    final hitboxLeft = playerCenterX - hitboxWidth / 2;
    final hitboxTop = playerTop + (_playerHeight - hitboxHeight);

    return Rect.fromLTWH(
      hitboxLeft,
      hitboxTop,
      hitboxWidth,
      hitboxHeight,
    );
  }

  Rect _obstacleHitbox(_FallingObstacle obstacle) {
    final hitboxWidth = obstacle.width * _obstacleHitboxWidthFactor;
    final hitboxHeight = obstacle.height * _obstacleHitboxHeightFactor;
    final left = obstacle.x + (obstacle.width - hitboxWidth) / 2;
    final top = obstacle.y + (obstacle.height - hitboxHeight) / 2;

    return Rect.fromLTWH(left, top, hitboxWidth, hitboxHeight);
  }

  _FallingObstacle _createObstacle(int index) {
    final spacing = _viewportHeight / _obstacleCount;
    final initialY =
        (index * spacing * 0.9) -
        _viewportHeight * 0.8 -
        _random.nextDouble() * 40;
    final initialSpeed = _nextObstacleSpeed(_elapsedSeconds);

    return _FallingObstacle(
      x: _random.nextDouble() * (_worldWidth - _obstacleSize),
      y: initialY,
      width: _obstacleSize,
      height: _obstacleSize,
      speed: initialSpeed,
      assetPath: _fallingObjectAssets[index % _fallingObjectAssets.length],
    );
  }

  double _nextObstacleSpeed(double elapsedSeconds) {
    final ramp = elapsedSeconds * _difficultyRampPerSecond;
    return _baseObstacleSpeed + ramp + _random.nextDouble() * _obstacleSpeedVariance;
  }

  void _tick() {
    final elapsed =
        _stopwatch.elapsedMicroseconds / Duration.microsecondsPerSecond;
    _stopwatch
      ..reset()
      ..start();

    if (!mounted || _gameOverTriggered || elapsed <= 0) {
      return;
    }

    final keyboardIntent =
        (_moveRightPressed ? 1.0 : 0.0) - (_moveLeftPressed ? 1.0 : 0.0);
    var steeringIntent = keyboardIntent;

    if (_touchTargetWorldX != null) {
      final deltaToTarget = _touchTargetWorldX! - _playerWorldX;
      if (deltaToTarget.abs() < 6) {
        _touchTargetWorldX = null;
      } else {
        steeringIntent += deltaToTarget.sign;
      }
    }

    if (steeringIntent != 0) {
      _playerVelocity +=
          steeringIntent.clamp(-1.0, 1.0) * _playerAcceleration * elapsed;
    } else {
      final dragAmount = _playerDrag * elapsed;
      if (_playerVelocity.abs() <= dragAmount) {
        _playerVelocity = 0;
      } else {
        _playerVelocity -= _playerVelocity.sign * dragAmount;
      }
    }

    _playerVelocity = _playerVelocity.clamp(-_playerMaxSpeed, _playerMaxSpeed);

    final nextPlayerX = (_playerWorldX + _playerVelocity * elapsed).clamp(
      _playerWidth / 2,
      _worldWidth - _playerWidth / 2,
    );

    if (nextPlayerX == _playerWidth / 2 ||
        nextPlayerX == _worldWidth - _playerWidth / 2) {
      _playerVelocity = 0;
    }

    final nextObstacles = <_FallingObstacle>[];

    for (final obstacle in _obstacles) {
      var nextY = obstacle.y + obstacle.speed * elapsed;
      var nextX = obstacle.x;
      var nextSpeed = obstacle.speed;
      var nextAssetPath = obstacle.assetPath;

      if (nextY > _viewportHeight + 40) {
        nextX = _random.nextDouble() * (_worldWidth - _obstacleSize);
        nextY = -_obstacleSize - _random.nextDouble() * 180;
        nextSpeed = _nextObstacleSpeed(_elapsedSeconds);
        nextAssetPath =
            _fallingObjectAssets[_random.nextInt(_fallingObjectAssets.length)];
      }

      nextObstacles.add(
        _FallingObstacle(
          x: nextX,
          y: nextY,
          width: _obstacleSize,
          height: _obstacleSize,
          speed: nextSpeed,
          assetPath: nextAssetPath,
        ),
      );
    }

    final playerRect = _playerHitbox(nextPlayerX);

    final hit = nextObstacles.any((obstacle) {
      final obstacleRect = _obstacleHitbox(obstacle);
      return playerRect.overlaps(obstacleRect);
    });

    if (hit) {
      _gameOverTriggered = true;
      widget.onGameOver(_elapsedSeconds + elapsed);
      return;
    }

    setState(() {
      _playerWorldX = nextPlayerX;
      _elapsedSeconds += elapsed;
      _obstacles = nextObstacles;
    });
  }

  KeyEventResult _handleKeyEvent(KeyEvent event) {
    final isLeftKey =
        event.logicalKey == LogicalKeyboardKey.arrowLeft ||
        event.logicalKey == LogicalKeyboardKey.keyA;
    final isRightKey =
        event.logicalKey == LogicalKeyboardKey.arrowRight ||
        event.logicalKey == LogicalKeyboardKey.keyD;

    if (!isLeftKey && !isRightKey) {
      return KeyEventResult.ignored;
    }

    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      setState(() {
        if (isLeftKey) {
          _moveLeftPressed = true;
        }
        if (isRightKey) {
          _moveRightPressed = true;
        }
        _touchTargetWorldX = null;
      });
      return KeyEventResult.handled;
    }

    if (event is KeyUpEvent) {
      setState(() {
        if (isLeftKey) {
          _moveLeftPressed = false;
        }
        if (isRightKey) {
          _moveRightPressed = false;
        }
      });
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _updateViewport(Size size) {
    final nextWidth = size.width;
    final nextHeight = size.height;
    final previousWorldWidth = _worldWidth;
    final nextWorldWidth = math.max(
      nextHeight * 0.5 * _backgroundAspectRatio,
      nextWidth + 1,
    );

    if ((nextWidth - _viewportWidth).abs() < 0.1 &&
        (nextHeight - _viewportHeight).abs() < 0.1) {
      return;
    }

    final widthRatio = _worldWidth == 0 ? 0.5 : _playerWorldX / _worldWidth;

    setState(() {
      _viewportWidth = nextWidth;
      _viewportHeight = nextHeight;
      _worldWidth = nextWorldWidth;
      _playerWorldX = (_worldWidth * widthRatio).clamp(
        _playerWidth / 2,
        _worldWidth - _playerWidth / 2,
      );
      _obstacles = _obstacles
          .map(
            (obstacle) => obstacle.copyWith(
              x:
                  (obstacle.x / math.max(1, previousWorldWidth)) *
                  nextWorldWidth,
            ),
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC9C1A6),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _updateViewport(size);
              }
            });

            final cameraX = (_playerWorldX - _viewportWidth / 2).clamp(
              0.0,
              _worldWidth - _viewportWidth,
            );
            final playerScreenX = _playerWorldX - cameraX - _playerWidth / 2;
            final playerTop =
                _viewportHeight - _playerHeight - _playerBottomOffset;

            return KeyboardListener(
              focusNode: _keyboardFocusNode,
              autofocus: true,
              onKeyEvent: _handleKeyEvent,
              child: GestureDetector(
                onTap: () {
                  if (!_keyboardFocusNode.hasFocus) {
                    _keyboardFocusNode.requestFocus();
                  }
                },
                onHorizontalDragStart: (_) {
                  if (!_keyboardFocusNode.hasFocus) {
                    _keyboardFocusNode.requestFocus();
                  }
                },
                onHorizontalDragDown: (details) {
                  setState(() {
                    _touchTargetWorldX = details.localPosition.dx + cameraX;
                  });
                },
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    _touchTargetWorldX = details.localPosition.dx + cameraX;
                  });
                },
                onHorizontalDragEnd: (_) {
                  _touchTargetWorldX = null;
                },
                onTapDown: (details) {
                  setState(() {
                    _touchTargetWorldX = details.localPosition.dx + cameraX;
                  });
                },
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ColoredBox(color: const Color(0xFF01B6F7)),
                    ),
                    Positioned(
                      left: -cameraX,
                      top: _viewportHeight * 0.5,
                      child: Image.asset(
                        'assets/rs_bg.webp',
                        width: _worldWidth,
                        height: _viewportHeight * 0.5,
                        fit: BoxFit.fill,
                        errorBuilder: (context, error, stackTrace) {
                          return SizedBox(
                            width: _worldWidth,
                            height: _viewportHeight * 0.5,
                            child: const ColoredBox(color: Color(0xFF7ED957)),
                          );
                        },
                      ),
                    ),
                    for (final obstacle in _obstacles)
                      Positioned(
                        left: obstacle.x - cameraX,
                        top: obstacle.y,
                        child: SizedBox(
                          width: obstacle.width,
                          height: obstacle.height,
                          child: Image.asset(
                            obstacle.assetPath,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(color: const Color(0xFFFF6B6B));
                            },
                          ),
                        ),
                      ),
                    Positioned(
                      left: playerScreenX,
                      top: playerTop,
                      child: Image.asset(
                        widget.playerAssetPath,
                        width: _playerWidth,
                        height: _playerHeight,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: _playerWidth,
                            height: _playerHeight,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1C47A8),
                              border: Border.all(color: Colors.black, width: 3),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FallingObstacle {
  const _FallingObstacle({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.speed,
    required this.assetPath,
  });

  final double x;
  final double y;
  final double width;
  final double height;
  final double speed;
  final String assetPath;

  _FallingObstacle copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
    double? speed,
    String? assetPath,
  }) {
    return _FallingObstacle(
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      speed: speed ?? this.speed,
      assetPath: assetPath ?? this.assetPath,
    );
  }
}

const List<String> _fallingObjectAssets = [
  'assets/rs_fall_1.webp',
  'assets/rs_fall_2.webp',
  'assets/rs_fall_3.webp',
  'assets/rs_fall_4.webp',
  'assets/rs_fall_5.webp',
  'assets/rs_fall_6.webp',
  'assets/rs_fall_7.webp',
];
