import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:snake_game/highscore_tile.dart';
import 'food_pixel.dart';
import 'snake_pixel.dart';
import 'blank_pixel.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

enum SnakeDirection { up, down, left, right }

class _HomePageState extends State<HomePage> {
  // Grid dimensions
  static const int rowNum = 10;
  static const int columnNum = 10;
  static const int squareTotalNum = rowNum * columnNum;

  // Game setting
  bool isGameStarted = false;
  final _nameController = TextEditingController();
  // User score
  int currScore = 0;

  // Snake position
  List<int> snakePos = [
    0,
    1,
    2,
  ];

  // Snake direction is initially to the right
  var snakeCurrDir = SnakeDirection.right;

  // Food position
  int foodPos = 55;

  // highscore list
  List<String> highscoreDocIds = [];
  late final Future? letsGetDocIds;

  @override
  void initState() {
    letsGetDocIds = getDocId();
    super.initState();
  }

  Future getDocId() async {
    await FirebaseFirestore.instance
        .collection("highscores")
        .orderBy("score", descending: true)
        .limit(10)
        .get()
        .then(((value) => value.docs.forEach((element) {
              highscoreDocIds.add(element.reference.id);
            })));
  }

  // Start the game
  void startGame() {
    isGameStarted = true;

    Timer.periodic(const Duration(milliseconds: 200), (timer) {
      setState(() {
        // Keep the snake moving
        moveSnake();

        if (isGameOver()) {
          timer.cancel();

          // display a message to the user
          showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) {
                return AlertDialog(
                  title: const Text('Game over!'),
                  content: Column(
                    children: [
                      Text('Your score is: $currScore'),
                      TextField(
                        controller: _nameController,
                        decoration:
                            const InputDecoration(hintText: 'Enter name'),
                      ),
                    ],
                  ),
                  actions: [
                    MaterialButton(
                      onPressed: () {
                        Navigator.pop(context);
                        submitScore();
                        restartGame();
                      },
                      color: Colors.pink,
                      child: const Text('Submit'),
                    )
                  ],
                );
              });
        }
      });
    });
  }

  void submitScore() {
    // Get access to the collection
    var database = FirebaseFirestore.instance;

    // add data to firebase
    database.collection('highscores').add({
      "name": _nameController.text,
      "score": currScore,
    });
  }

  Future restartGame() async {
    highscoreDocIds = [];
    await getDocId();
    setState(() {
      // Snake position
      snakePos = [
        0,
        1,
        2,
      ];
      foodPos = 55;
      snakeCurrDir = SnakeDirection.right;
      isGameStarted = false;
      currScore = 0;
    });
  }

  void eatFood() {
    currScore++;
    // Make sure the new food is not where the snake is
    while (snakePos.contains(foodPos)) {
      foodPos = Random().nextInt(squareTotalNum);
    }
  }

  void moveSnake() {
    switch (snakeCurrDir) {
      case SnakeDirection.up:
        {
          // Add a new head
          // If snake hit the top wall, need to relocate on same column
          if (snakePos.last < rowNum) {
            snakePos.add(snakePos.last - rowNum + squareTotalNum);
          } else {
            snakePos.add(snakePos.last - rowNum);
          }
        }
        break;
      case SnakeDirection.down:
        {
          // Add a new head
          // If snake hit the bottom wall, need to relocate on same column
          if (snakePos.last + rowNum >= squareTotalNum) {
            snakePos.add(snakePos.last + rowNum - squareTotalNum);
          } else {
            snakePos.add(snakePos.last + rowNum);
          }
        }
        break;
      case SnakeDirection.left:
        {
          // Add a new head
          // If snake hit the left wall, need to relocate on same row
          if (snakePos.last % rowNum == 0) {
            snakePos.add(snakePos.last - 1 + rowNum);
          } else {
            snakePos.add(snakePos.last - 1);
          }
        }
        break;
      case SnakeDirection.right:
        {
          // Add a new head
          // If snake hit the right wall, need to relocate on same row
          if (snakePos.last % rowNum == 9) {
            snakePos.add(snakePos.last + 1 - rowNum);
          } else {
            snakePos.add(snakePos.last + 1);
          }
        }
        break;
      default:
    }
    // snake is eating food
    if (snakePos.last == foodPos) {
      eatFood();
    } else {
      // Remove the tail
      snakePos.removeAt(0);
    }
  }

  bool isGameOver() {
    // the game is over when the snake eat itself
    // this occurs when there is a duplicate position in the snakePos list

    // this list is the body of the snake (no head)
    List<int> bodySnake = snakePos.sublist(0, snakePos.length - 1);

    if (bodySnake.contains(snakePos.last)) {
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    // get the screen width
    double screenWidth = MediaQuery.of(context).size.width;
    // get the screen height
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: RawKeyboardListener(
        focusNode: FocusNode(),
        autofocus: true,
        onKey: (event) {
          if (event.isKeyPressed(LogicalKeyboardKey.arrowUp) &&
              snakeCurrDir != SnakeDirection.down) {
            snakeCurrDir = SnakeDirection.up;
          } else if (event.isKeyPressed(LogicalKeyboardKey.arrowDown) &&
              snakeCurrDir != SnakeDirection.up) {
            snakeCurrDir = SnakeDirection.down;
          } else if (event.isKeyPressed(LogicalKeyboardKey.arrowLeft) &&
              snakeCurrDir != SnakeDirection.right) {
            snakeCurrDir = SnakeDirection.left;
          } else if (event.isKeyPressed(LogicalKeyboardKey.arrowRight) &&
              snakeCurrDir != SnakeDirection.left) {
            snakeCurrDir = SnakeDirection.right;
          }
        },
        child: SizedBox(
          width: screenWidth > 428 ? 428 : screenWidth,
          height: screenHeight > 1000 ? 1000 : screenHeight,
          child: Column(
            children: [
              // Hige scores
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // player current score
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Current Score'),
                          Text(
                            currScore.toString(),
                            style: const TextStyle(fontSize: 36),
                          ),
                        ],
                      ),
                    ),

                    // high scores, top 5 or 10
                    Expanded(
                      child: isGameStarted
                          ? Container()
                          : Container(
                              padding: const EdgeInsets.only(
                                top: 10,
                                bottom: 10,
                              ),
                              child: FutureBuilder(
                                future: letsGetDocIds,
                                builder: (context, snapshot) {
                                  return ListView.builder(
                                    itemCount: highscoreDocIds.length,
                                    itemBuilder: (context, index) {
                                      return HighScoreTile(
                                          documentId: highscoreDocIds[index]);
                                    },
                                  );
                                },
                              ),
                            ),
                    )
                  ],
                ),
              ),

              // Game grid
              Expanded(
                flex: 4,
                child: GestureDetector(
                  onVerticalDragUpdate: (details) {
                    if (details.delta.dy < 0 &&
                        snakeCurrDir != SnakeDirection.down) {
                      snakeCurrDir = SnakeDirection.up;
                    } else if (details.delta.dy > 0 &&
                        snakeCurrDir != SnakeDirection.up) {
                      snakeCurrDir = SnakeDirection.down;
                    }
                  },
                  onHorizontalDragUpdate: (details) {
                    if (details.delta.dx > 0 &&
                        snakeCurrDir != SnakeDirection.left) {
                      snakeCurrDir = SnakeDirection.right;
                    } else if (details.delta.dx < 0 &&
                        snakeCurrDir != SnakeDirection.right) {
                      snakeCurrDir = SnakeDirection.left;
                    }
                  },
                  child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: rowNum),
                      itemCount: squareTotalNum,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        if (snakePos.contains(index)) {
                          return const SnakePixel();
                        } else if (foodPos == index) {
                          return const FoodPixel();
                        } else {
                          return const BlankPixel();
                        }
                      }),
                ),
              ),

              // Play button
              Expanded(
                child: Center(
                  child: MaterialButton(
                    color: isGameStarted ? Colors.grey : Colors.pink,
                    onPressed: isGameStarted ? () {} : startGame,
                    child: const Text('PLAY'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
