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

  // Асинхронная генерация новых головоломок для определенной сложности и добавление к существующим
  Future<void> generatePuzzlesForDifficulty(
      String difficulty, int difficultyLevel) async {
    try {
      await loadExistingPuzzles(
          difficulty); // Загрузка существующих головоломок перед генерацией новых

      SudokuGenerator generator;
      List<Map<String, dynamic>> generatedPuzzles = [];
      setState(() {
        isLoading = true; // Включаем индикатор загрузки
        progress = 0; // Сбрасываем прогресс
      });

      int numberOfPuzzles = 10; // Количество новых головоломок

      // Показываем индикатор загрузки
      for (int i = 0; i < numberOfPuzzles; i++) {
        generator = SudokuGenerator(); // Создаем новый экземпляр генератора

        // Задержка и генерация головоломки
        List<List<int>> puzzle = await Future.delayed(
            const Duration(milliseconds: 100), // Увеличиваем задержку
            () => generator.generatePuzzle(difficultyLevel));

        // Генерация уникального UUID для каждой головоломки
        String uniqueId = uuid.v4();

        // Добавляем новую головоломку с уникальным UUID
        generatedPuzzles.add({
          'id': uniqueId, // Уникальный ID (UUID) для сложности
          'puzzle': puzzle,
        });

        // Обновляем прогресс после каждой головоломки
        setState(() {
          progress = (i + 1) / numberOfPuzzles;
        });

        print('Головоломка с ID $uniqueId для "$difficulty" сгенерирована.');
      }

      // Добавляем новые головоломки к существующим
      allPuzzles[difficulty]!.addAll(generatedPuzzles);

      // Конвертируем объединенный список головоломок в JSON
      String jsonPuzzles = jsonEncode(allPuzzles[difficulty]);

      // Получаем путь к директории документов
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String appDocPath = appDocDir.path;
      String fileName = getFileNameForDifficulty(difficulty);

      // Создаем файл в директории документов (перезаписываем его)
      File file = File('$appDocPath/$fileName');

      // Записываем JSON в файл
      await file.writeAsString(jsonPuzzles);

      print(
          'Добавлено $numberOfPuzzles головоломок для "$difficulty" и сохранено в ${file.path}');

      // Сохраняем путь к файлу
      jsonFilePath = file.path;
    } catch (e) {
      print('Ошибка во время генерации: $e');
    } finally {
      // Завершаем загрузку и обновляем состояние
      setState(() {
        isLoading = false;
      });
    }
  }

  // Определение имени файла для сложности
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
    // Загружаем существующие головоломки для всех сложностей при инициализации
    loadExistingPuzzles('easy');
    loadExistingPuzzles('medium');
    loadExistingPuzzles('hard');
    loadExistingPuzzles('very_hard');
  }
}
