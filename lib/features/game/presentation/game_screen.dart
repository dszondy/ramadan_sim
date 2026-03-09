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
  static const double _baseObstacleSpeed = 180;
  static const double _obstacleSpeedVariance = 130;
  static const double _difficultyRampPerSecond = 12;
  static const double _playerHitboxWidthFactor = 0.46;
  static const double _playerHitboxHeightFactor = 0.78;
  static const double _obstacleHitboxWidthFactor = 0.68;
  static const double _obstacleHitboxHeightFactor = 0.68;
  static const double _touchDeadZone = 12;
  static const double _smallBackgroundBreakpoint = 480;
  static const double _mobileBackgroundBreakpoint = 700;
  static const double _mobileSpriteBreakpoint = 700;
  static const double _obstacleSizeFactor = 44 / 420;
  static const double _obstacleRespawnOffsetFactor = 180 / 420;
  static const double _obstacleCleanupOffsetFactor = 40 / 420;
  static const double _obstacleBaseSpeedFactor = _baseObstacleSpeed / 420;
  static const double _obstacleSpeedVarianceFactor =
      _obstacleSpeedVariance / 420;
  static const double _difficultyRampFactor = _difficultyRampPerSecond / 420;

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
  double? _touchPointerScreenX;
  String? _resolvedBackgroundAssetPath;
  int _backgroundLoadGeneration = 0;

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _queueBackgroundResolution();
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
    _touchPointerScreenX = null;
    _obstacles = List.generate(_obstacleCount, _createObstacle);
  }

  double get _playerHeight => _viewportHeight * 0.25;

  double get _playerWidth => _playerHeight * _playerAspectRatio;

  double get _obstacleSize => _viewportHeight * _obstacleSizeFactor;

  double get _obstacleRespawnOffset =>
      _viewportHeight * _obstacleRespawnOffsetFactor;

  double get _obstacleCleanupOffset =>
      _viewportHeight * _obstacleCleanupOffsetFactor;

  bool get _preferMobileSprites => _viewportWidth <= _mobileSpriteBreakpoint;

  List<String> get _backgroundAssetCandidates {
    if (_viewportWidth <= _smallBackgroundBreakpoint) {
      return const [
        'assets/rs_bg_small.webp',
        'assets/rs_bg_mobile.webp',
        'assets/rs_bg.webp',
      ];
    }

    if (_viewportWidth <= _mobileBackgroundBreakpoint) {
      return const [
        'assets/rs_bg_mobile.webp',
        'assets/rs_bg_small.webp',
        'assets/rs_bg.webp',
      ];
    }

    return const [
      'assets/rs_bg.webp',
      'assets/rs_bg_mobile.webp',
      'assets/rs_bg_small.webp',
    ];
  }

  String _spriteAssetPath(String assetPath) {
    if (!_preferMobileSprites || !assetPath.endsWith('.webp')) {
      return assetPath;
    }

    final mobileAssetPath = assetPath.replaceFirst('.webp', '_mobile.webp');
    if (_mobileSpriteAssets.contains(mobileAssetPath)) {
      return mobileAssetPath;
    }

    return assetPath;
  }

  void _queueBackgroundResolution() {
    if (!mounted) {
      return;
    }

    final generation = ++_backgroundLoadGeneration;
    unawaited(_resolveBackgroundAsset(generation));
  }

  Future<void> _resolveBackgroundAsset(int generation) async {
    for (final assetPath in _backgroundAssetCandidates) {
      try {
        await precacheImage(AssetImage(assetPath), context);

        if (!mounted || generation != _backgroundLoadGeneration) {
          return;
        }

        if (_resolvedBackgroundAssetPath != assetPath) {
          setState(() {
            _resolvedBackgroundAssetPath = assetPath;
          });
        }
        return;
      } catch (_) {
        // Try the next smaller background asset.
      }
    }

    if (!mounted || generation != _backgroundLoadGeneration) {
      return;
    }

    setState(() {
      _resolvedBackgroundAssetPath = null;
    });
  }

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
    final obstacleSize = _obstacleSize;
    final spacing = _viewportHeight / _obstacleCount;
    final initialY =
        (index * spacing * 0.9) -
        _viewportHeight * 0.8 -
        _random.nextDouble() * 40;
    final initialSpeed = _nextObstacleSpeed(_elapsedSeconds);

    return _FallingObstacle(
      x: _random.nextDouble() * (_worldWidth - obstacleSize),
      y: initialY,
      width: obstacleSize,
      height: obstacleSize,
      speed: initialSpeed,
      assetPath: _fallingObjectAssets[index % _fallingObjectAssets.length],
    );
  }

  double _nextObstacleSpeed(double elapsedSeconds) {
    final ramp = elapsedSeconds * (_viewportHeight * _difficultyRampFactor);
    return (_viewportHeight * _obstacleBaseSpeedFactor) +
        ramp +
        _random.nextDouble() * (_viewportHeight * _obstacleSpeedVarianceFactor);
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
    final currentCameraX = (_playerWorldX - _viewportWidth / 2).clamp(
      0.0,
      _worldWidth - _viewportWidth,
    );

    if (_touchPointerScreenX != null) {
      final playerScreenCenterX = _playerWorldX - currentCameraX;
      final deltaToTouch = _touchPointerScreenX! - playerScreenCenterX;
      if (deltaToTouch.abs() >= _touchDeadZone) {
        final touchIntent = (deltaToTouch / (_viewportWidth / 2)).clamp(
          -1.0,
          1.0,
        );
        steeringIntent += touchIntent;
        _playerVelocity = touchIntent * _playerMaxSpeed;
      } else {
        _playerVelocity = 0;
      }
    }

    if (_touchPointerScreenX != null) {
      _playerVelocity = _playerVelocity.clamp(-_playerMaxSpeed, _playerMaxSpeed);
    } else if (steeringIntent != 0) {
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
    final obstacleSize = _obstacleSize;

    for (final obstacle in _obstacles) {
      var nextY = obstacle.y + obstacle.speed * elapsed;
      var nextX = obstacle.x;
      var nextSpeed = obstacle.speed;
      var nextAssetPath = obstacle.assetPath;

      if (nextY > _viewportHeight + _obstacleCleanupOffset) {
        nextX = _random.nextDouble() * (_worldWidth - obstacleSize);
        nextY = -obstacleSize - _random.nextDouble() * _obstacleRespawnOffset;
        nextSpeed = _nextObstacleSpeed(_elapsedSeconds);
        nextAssetPath =
            _fallingObjectAssets[_random.nextInt(_fallingObjectAssets.length)];
      }

      nextObstacles.add(
        _FallingObstacle(
          x: nextX,
          y: nextY,
          width: obstacleSize,
          height: obstacleSize,
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
        _touchPointerScreenX = null;
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
    final previousViewportHeight = _viewportHeight;
    final nextWorldWidth = math.max(
      nextHeight * 0.5 * _backgroundAspectRatio,
      nextWidth + 1,
    );
    final nextObstacleSize = nextHeight * _obstacleSizeFactor;
    final heightRatio =
        previousViewportHeight == 0 ? 1.0 : nextHeight / previousViewportHeight;

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
              x: ((obstacle.x / math.max(1, previousWorldWidth)) *
                      nextWorldWidth)
                  .clamp(0.0, math.max(0.0, nextWorldWidth - nextObstacleSize)),
              y: obstacle.y * heightRatio,
              width: nextObstacleSize,
              height: nextObstacleSize,
              speed: obstacle.speed * heightRatio,
            ),
          )
          .toList();
    });

    _queueBackgroundResolution();
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
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (event) {
                  if (!_keyboardFocusNode.hasFocus) {
                    _keyboardFocusNode.requestFocus();
                  }
                  _touchPointerScreenX = event.localPosition.dx;
                },
                onPointerMove: (event) {
                  _touchPointerScreenX = event.localPosition.dx;
                },
                onPointerUp: (_) {
                  _touchPointerScreenX = null;
                },
                onPointerCancel: (_) {
                  _touchPointerScreenX = null;
                },
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ColoredBox(color: const Color(0xFF01B6F7)),
                    ),
                    Positioned(
                      left: -cameraX,
                      top: _viewportHeight * 0.5,
                      child: SizedBox(
                        width: _worldWidth,
                        height: _viewportHeight * 0.5,
                        child: _resolvedBackgroundAssetPath == null
                            ? const ColoredBox(color: Color(0xFF7ED957))
                            : Image.asset(
                                _resolvedBackgroundAssetPath!,
                                fit: BoxFit.fill,
                                errorBuilder: (context, error, stackTrace) {
                                  return const ColoredBox(
                                    color: Color(0xFF7ED957),
                                  );
                                },
                              ),
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
                            _spriteAssetPath(obstacle.assetPath),
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
                        _spriteAssetPath(widget.playerAssetPath),
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

const Set<String> _mobileSpriteAssets = {
  'assets/rs_man_mobile.webp',
  'assets/rs_woman_mobile.webp',
  'assets/rs_other_mobile.webp',
  'assets/rs_fall_1_mobile.webp',
  'assets/rs_fall_2_mobile.webp',
  'assets/rs_fall_3_mobile.webp',
  'assets/rs_fall_4_mobile.webp',
  'assets/rs_fall_5_mobile.webp',
  'assets/rs_fall_6_mobile.webp',
  'assets/rs_fall_7_mobile.webp',
};
