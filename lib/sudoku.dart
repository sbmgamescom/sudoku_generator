import 'dart:math';

class SudokuGenerator {
  List<List<int>> grid = List.generate(9, (_) => List.filled(9, 0));

  // Проверка, можно ли вставить число в заданную позицию
  bool isSafe(int row, int col, int num) {
    // Проверка строки и столбца
    for (int i = 0; i < 9; i++) {
      if (grid[row][i] == num || grid[i][col] == num) {
        return false;
      }
    }

    // Проверка 3x3 квадрата
    int startRow = row - row % 3;
    int startCol = col - col % 3;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if (grid[startRow + i][startCol + j] == num) {
          return false;
        }
      }
    }
    return true;
  }

  // Генерация полной решетки Судоку
  bool fillGrid() {
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (grid[row][col] == 0) {
          List<int> numbers = List<int>.generate(9, (index) => index + 1)
            ..shuffle();
          for (int num in numbers) {
            if (isSafe(row, col, num)) {
              grid[row][col] = num;
              if (fillGrid()) {
                return true;
              }
              grid[row][col] = 0;
            }
          }
          return false;
        }
      }
    }
    return true;
  }

  // Удаление цифр для создания головоломки с учетом сложности
  void removeNumbers(int difficulty) {
    int clues; // Количество заполненных клеток

    switch (difficulty) {
      case 1: // Легкий
        clues = 40 + Random().nextInt(6); // 40-45 подсказок
        break;
      case 2: // Средний
        clues = 32 + Random().nextInt(6); // 32-37 подсказок
        break;
      case 3: // Сложный
        clues = 28 + Random().nextInt(5); // 28-32 подсказки
        break;
      case 4: // Очень сложный
        clues = 22 + Random().nextInt(6); // 22-27 подсказок
        break;
      default:
        clues = 32 + Random().nextInt(6); // По умолчанию средний уровень
    }

    int cellsToRemove = 81 - clues;

    while (cellsToRemove > 0) {
      int row = Random().nextInt(9);
      int col = Random().nextInt(9);
      if (grid[row][col] != 0) {
        int backup = grid[row][col];
        grid[row][col] = 0;

        // Создаем копию сетки для проверки уникальности
        List<List<int>> gridCopy = grid.map((r) => List<int>.from(r)).toList();

        if (!hasUniqueSolution(gridCopy)) {
          grid[row][col] =
              backup; // Возвращаем цифру, если решение не уникально
        } else {
          cellsToRemove--;
        }
      }
    }
  }

  // Функция для генерации головоломки
  List<List<int>> generatePuzzle(int difficulty) {
    fillGrid();
    removeNumbers(difficulty);
    return grid;
  }

  // Проверка на единственность решения
  bool hasUniqueSolution(List<List<int>> gridCopy) {
    int solutions = 0;

    bool solve(int row, int col) {
      if (row == 9) {
        solutions++;
        return solutions > 1; // Прекратить, если найдено больше одного решения
      }
      if (gridCopy[row][col] != 0) {
        return solve(col == 8 ? row + 1 : row, (col + 1) % 9);
      }
      for (int num = 1; num <= 9; num++) {
        if (isSafeInGrid(gridCopy, row, col, num)) {
          gridCopy[row][col] = num;
          if (solve(col == 8 ? row + 1 : row, (col + 1) % 9)) {
            gridCopy[row][col] = 0;
            return true;
          }
          gridCopy[row][col] = 0;
        }
      }
      return false;
    }

    solve(0, 0);
    return solutions == 1;
  }

  // Проверка безопасности для копии сетки
  bool isSafeInGrid(List<List<int>> gridCopy, int row, int col, int num) {
    // Проверка строки и столбца
    for (int i = 0; i < 9; i++) {
      if (gridCopy[row][i] == num || gridCopy[i][col] == num) {
        return false;
      }
    }

    // Проверка 3x3 квадрата
    int startRow = row - row % 3;
    int startCol = col - col % 3;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if (gridCopy[startRow + i][startCol + j] == num) {
          return false;
        }
      }
    }
    return true;
  }
}
