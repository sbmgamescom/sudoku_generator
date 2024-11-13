import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sudoku/sudoku.dart';
import 'package:uuid/uuid.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Map<String, List<Map<String, dynamic>>> allPuzzles = {
    'easy': [],
    'medium': [],
    'hard': [],
    'very_hard': [],
  };

  String? jsonFilePath;
  final Uuid uuid = const Uuid();
  bool isLoading = false; // Для отображения индикатора загрузки
  double progress = 0; // Прогресс генерации

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Судоку Генератор'),
      ),
      body: Column(
        children: [
          if (isLoading) // Показываем прогресс, если идет загрузка
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: LinearProgressIndicator(value: progress),
            ),
          ElevatedButton(
            onPressed: isLoading
                ? null
                : () => generatePuzzlesForDifficulty('easy', 1),
            child: const Text('Сгенерировать Легкие головоломки'),
          ),
          ElevatedButton(
            onPressed: isLoading
                ? null
                : () => generatePuzzlesForDifficulty('medium', 2),
            child: const Text('Сгенерировать Средние головоломки'),
          ),
          ElevatedButton(
            onPressed: isLoading
                ? null
                : () => generatePuzzlesForDifficulty('hard', 3),
            child: const Text('Сгенерировать Сложные головоломки'),
          ),
          ElevatedButton(
            onPressed: isLoading
                ? null
                : () => generatePuzzlesForDifficulty('very_hard', 4),
            child: const Text('Сгенерировать Очень сложные головоломки'),
          ),
        ],
      ),
    );
  }

  String formatPuzzle(List<List<int>> puzzle) {
    return puzzle.map((row) => row.join(' ')).join('\n');
  }

  // Загрузка головоломок из файла в зависимости от сложности
  Future<void> loadExistingPuzzles(String difficulty) async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;
    String fileName = getFileNameForDifficulty(difficulty);

    File file = File('$appDocPath/$fileName');

    if (await file.exists()) {
      String jsonData = await file.readAsString();
      List<dynamic> jsonPuzzles = jsonDecode(jsonData);
      allPuzzles[difficulty] =
          jsonPuzzles.map((p) => Map<String, dynamic>.from(p)).toList();
      setState(() {});
    } else {
      print('Файл для сложности "$difficulty" не найден. Создание нового.');
    }
  }

  Future<void> generatePuzzlesForDifficulty(
      String difficulty, int difficultyLevel) async {
    try {
      await loadExistingPuzzles(difficulty);

      SudokuGenerator generator;
      List<Map<String, dynamic>> generatedPuzzles = [];
      setState(() {
        isLoading = true;
        progress = 0;
      });

      int numberOfPuzzles = 10;

      for (int i = 0; i < numberOfPuzzles; i++) {
        generator = SudokuGenerator();

        List<List<int>> puzzle = await Future.delayed(
            const Duration(milliseconds: 100),
            () => generator.generatePuzzle(difficultyLevel));

        String uniqueId = uuid.v4();

        generatedPuzzles.add({
          'id': uniqueId,
          'puzzle': puzzle,
        });

        setState(() {
          progress = (i + 1) / numberOfPuzzles;
        });

        print('Головоломка с ID $uniqueId для "$difficulty" сгенерирована.');
      }

      allPuzzles[difficulty]!.addAll(generatedPuzzles);

      String jsonPuzzles = jsonEncode(allPuzzles[difficulty]);

      Directory appDocDir = await getApplicationDocumentsDirectory();
      String appDocPath = appDocDir.path;
      String fileName = getFileNameForDifficulty(difficulty);

      File file = File('$appDocPath/$fileName');

      await file.writeAsString(jsonPuzzles);

      print(
          'Добавлено $numberOfPuzzles головоломок для "$difficulty" и сохранено в ${file.path}');

      jsonFilePath = file.path;
    } catch (e) {
      print('Ошибка во время генерации: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  String getFileNameForDifficulty(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return 'sudoku_easy.json';
      case 'medium':
        return 'sudoku_medium.json';
      case 'hard':
        return 'sudoku_hard.json';
      case 'very_hard':
        return 'sudoku_very_hard.json';
      default:
        return 'sudoku_puzzles.json';
    }
  }

  @override
  void initState() {
    super.initState();
    loadExistingPuzzles('easy');
    loadExistingPuzzles('medium');
    loadExistingPuzzles('hard');
    loadExistingPuzzles('very_hard');
  }
}
