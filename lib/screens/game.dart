import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../constants/colors.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool oTurn = true;
  List<String> displayXO = List.filled(9, '');
  List<int> matchedIndexes = [];
  int attempts = 0;

  int oScore = 0;
  int xScore = 0;
  int filledBoxes = 0;
  String resultDeclaration = '';
  bool winnerFound = false;

  static const int maxSeconds = 60;
  int seconds = maxSeconds;
  Timer? timer;

  static const TextStyle customFontWhite = TextStyle(
    color: Colors.white,
    letterSpacing: 3,
    fontSize: 28,
    fontWeight: FontWeight.bold,
  );

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (seconds > 0) {
          seconds--;
        } else {
          stopTimer();
        }
      });
    });
  }

  void stopTimer() {
    resetTimer();
    timer?.cancel();
  }

  void resetTimer() {
    seconds = maxSeconds;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 67, 136, 214),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildScoreBoard(),
            const SizedBox(height: 20), // Adds space between score and grid
            _buildGameGrid(),
            const SizedBox(height: 20), // Adds space between grid and footer
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBoard() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildPlayerScore('Player O', oScore),
        _buildPlayerScore('Bot X', xScore),
      ],
    );
  }

  Widget _buildPlayerScore(String player, int score) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(player, style: customFontWhite),
        Text(score.toString(), style: customFontWhite),
      ],
    );
  }

  Widget _buildGameGrid() {
    return Expanded(
      flex: 3,
      child: GridView.builder(
        itemCount: 9,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10, // Adds spacing between grid items
          mainAxisSpacing: 10, // Adds spacing between grid items
        ),
        itemBuilder: (BuildContext context, int index) {
          return GestureDetector(
            onTap: () => _playerTapped(index),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(width: 3, color: MainColor.primaryColor),
                color: matchedIndexes.contains(index)
                    ? MainColor.accentColor
                    : MainColor.secondaryColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    offset: const Offset(2, 4),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  displayXO[index],
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: matchedIndexes.contains(index)
                        ? MainColor.secondaryColor
                        : MainColor.primaryColor,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(resultDeclaration, style: customFontWhite),
        const SizedBox(height: 10),
        _buildTimer(),
      ],
    );
  }

  Widget _buildTimer() {
    final isRunning = timer?.isActive ?? false;

    return isRunning
        ? SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: 1 - seconds / maxSeconds,
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                  strokeWidth: 6,
                  backgroundColor: MainColor.accentColor,
                ),
                Center(
                  child: Text(
                    '$seconds',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 40,
                    ),
                  ),
                ),
              ],
            ),
          )
        : ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: () {
              startTimer();
              _clearBoard();
              attempts++;
            },
            child: Text(
              attempts == 0 ? 'Start' : 'Play Again!',
              style: const TextStyle(fontSize: 20, color: Colors.black),
            ),
          );
  }

  void _playerTapped(int index) {
    if (timer?.isActive ?? false && displayXO[index] == '') {
      setState(() {
        displayXO[index] = 'O';
        oTurn = !oTurn;
        filledBoxes++;
        _checkWinner();

        if (!winnerFound && filledBoxes < 9) {
          _botMove();
        }
      });
    }
  }

  void _botMove() {
    final emptyIndexes = <int>[];
    for (int i = 0; i < displayXO.length; i++) {
      if (displayXO[i] == '') emptyIndexes.add(i);
    }

    if (emptyIndexes.isNotEmpty) {
      final randomIndex = emptyIndexes[Random().nextInt(emptyIndexes.length)];
      setState(() {
        displayXO[randomIndex] = 'X';
        filledBoxes++;
        _checkWinner();
      });
    }
  }

  void _checkWinner() {
    final List<List<int>> winningPatterns = [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],
      [0, 4, 8],
      [6, 4, 2],
    ];

    for (var pattern in winningPatterns) {
      final String a = displayXO[pattern[0]];
      final String b = displayXO[pattern[1]];
      final String c = displayXO[pattern[2]];

      if (a == b && a == c && a != '') {
        setState(() {
          resultDeclaration = a == 'O' ? 'Player Wins!' : 'Bot Wins!';
          matchedIndexes = pattern;
          stopTimer();
          _updateScore(a);
        });
        return;
      }
    }

    if (filledBoxes == 9 && !winnerFound) {
      setState(() {
        resultDeclaration = 'It\'s a Draw!';
        stopTimer();
      });
    }
  }

  void _updateScore(String winner) {
    if (winner == 'O') {
      oScore++;
    } else if (winner == 'X') {
      xScore++;
    }
    winnerFound = true;
  }

  void _clearBoard() {
    setState(() {
      displayXO.fillRange(0, displayXO.length, '');
      matchedIndexes.clear();
      resultDeclaration = '';
      filledBoxes = 0;
      winnerFound = false;
    });
  }
}
