import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_swipe_detector/flutter_swipe_detector.dart';

import 'components/button.dart';
import 'components/empy_board.dart';
import 'components/score_board.dart';
import 'components/tile_board.dart';
import 'const/colors.dart';
import 'managers/board.dart';

class Game extends ConsumerStatefulWidget {
  const Game({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _GameState();
}

class _GameState extends ConsumerState<Game>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // The contoller used to move the the tiles
  late final AnimationController _moveController = AnimationController(
    duration: const Duration(milliseconds: 100),
    vsync: this,
  )..addStatusListener((status) {
      // When the movement finishes merge the tiles and start the scale animation which gives the pop effect.
      if (status == AnimationStatus.completed) {
        ref.read(boardManager.notifier).merge();
        _scaleController.forward(from: 0.0);
      }
    });

  // The curve animation for the move animation controller.
  late final CurvedAnimation _moveAnimation = CurvedAnimation(
    parent: _moveController,
    curve: Curves.easeInOut,
  );

  // The contoller used to show a popup effect when the tiles get merged
  late final AnimationController _scaleController = AnimationController(
    duration: const Duration(milliseconds: 200),
    vsync: this,
  )..addStatusListener((status) {
      // When the scale animation finishes end the round and if there is a queued movement start the move controller again for the next direction.
      if (status == AnimationStatus.completed) {
        if (ref.read(boardManager.notifier).endRound()) {
          _moveController.forward(from: 0.0);
        }
      }
    });

  // The curve animation for the scale animation controller.
  late final CurvedAnimation _scaleAnimation = CurvedAnimation(
    parent: _scaleController,
    curve: Curves.easeInOut,
  );

  void info() {
    showDialog(
      context: context,
      builder: (context) => const AlertDialog(
        backgroundColor: darkColor,
        title: Text(
          "Hint",
          style: TextStyle(
            fontFamily: "Quicksand",
            fontWeight: FontWeight.w500,
            fontSize: 20,
            color: textColorWhite
          ),
        ),
        content: Text(
          "Swipe to move the tiles. When two tiles with the same number touch, they merge into one!",
          style: TextStyle(
            fontFamily: "Quicksand",
            fontWeight: FontWeight.w500,
            color: textColorWhite
          )
        ),
      ),
    );
  }

  @override
  void initState() {
    // Add an Observer for the Lifecycles of the App
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      autofocus: true,
      focusNode: FocusNode(),
      onKey: (RawKeyEvent event) {
        // Move the tile with the arrows on the keyboard on Desktop
        if (ref.read(boardManager.notifier).onKey(event)) {
          _moveController.forward(from: 0.0);
        }
      },
      child: SwipeDetector(
        onSwipe: (direction, offset) {
          if (ref.read(boardManager.notifier).move(direction)) {
            _moveController.forward(from: 0.0);
          }
        },
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            leading: Padding(
              padding: const EdgeInsets.all(10.0),
              child: IconButton(
                  onPressed: info,
                  icon: const Icon(
                    Icons.info_outline_rounded,
                    color: textColorWhite,
                  )),
            ),
          ),
          backgroundColor: backgroundColor,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '2048',
                          style: TextStyle(
                            color: titleColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 52.0,
                            fontFamily: 'Quicksand',
                          ),
                        ),
                        Text(
                          'Join the numbers and get to the ',
                          style: TextStyle(
                            color: titleColor,
                            fontFamily: 'Quicksand',
                            fontSize: 13.0,
                          ),
                        ),
                        Text(
                          '2048 tile! ',
                          style: TextStyle(
                            color: titleColor,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Quicksand'
                          ),
                        ),
                      ],
                    ),

                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const ScoreBoard(),
                        const SizedBox(
                          height: 32.0,
                        ),
                        Row(
                          children: [
                            Stack(
                              children: [
                                ButtonWidget(
                                  icon: Icons.undo,
                                  onPressed: () {
                                    // Undo the round.
                                    ref.read(boardManager.notifier).undo();
                                  },
                                ),
                                const Positioned(
                                  right: 0,
                                  child: Icon(   
                                    Icons.movie_filter_outlined,
                                    color: Colors.white,
                                    size: 20.0,
                                  ),
                                ),
                              ]
                            ),
                            const SizedBox(
                              width: 10.0,
                            ),
                            ButtonWidget(
                              icon: Icons.refresh,
                              onPressed: () {
                                // Restart the game
                                ref.read(boardManager.notifier).newGame();
                              },
                            )
                          ],
                        )
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(
                height: 32.0,
              ),
              Stack(
                children: [
                  const EmptyBoardWidget(),
                  TileBoardWidget(
                      moveAnimation: _moveAnimation,
                      scaleAnimation: _scaleAnimation)
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Save current state when the app becomes inactive
    if (state == AppLifecycleState.inactive) {
      ref.read(boardManager.notifier).save();
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    // Remove the Observer for the Lifecycles of the App
    WidgetsBinding.instance.removeObserver(this);

    // Dispose the animations.
    _moveAnimation.dispose();
    _scaleAnimation.dispose();
    _moveController.dispose();
    _scaleController.dispose();
    super.dispose();
  }
}
