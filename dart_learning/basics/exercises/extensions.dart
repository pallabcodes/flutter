import 'dart:math'; // Import for sqrt function

/// Extension on String to add advanced utility methods.
extension StringExtension on String {
  /// Reverses the string.
  String reverse() => split('').reversed.join();

  /// Capitalizes the first letter of the string.
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  /// Checks if the string is a palindrome.
  bool isPalindrome() => this == reverse();

  /// Converts the string to camelCase.
  String toCamelCase() {
    final words = split(' ');
    return words
        .mapIndexed((index, word) =>
            index == 0 ? word.toLowerCase() : word.capitalize())
        .join('');
  }

  /// Converts the string to kebab-case.
  String toKebabCase() => toLowerCase().replaceAll(' ', '-');

  /// Converts the string to snake_case.
  String toSnakeCase() => toLowerCase().replaceAll(' ', '_');

  /// Converts the string to PascalCase.
  String toPascalCase() => split(' ').map((word) => word.capitalize()).join('');
}

/// Extension on List<T> to add advanced utility methods.
extension ListExtension<T> on List<T> {
  /// Returns a new list with duplicates removed.
  List<T> unique() => toSet().toList();

  /// Returns the element at the given index or null if out of bounds.
  T? elementAtOrNull(int index) =>
      (index >= 0 && index < length) ? this[index] : null;

  /// Groups the list into chunks of the given size.
  List<List<T>> chunked(int size) {
    if (size <= 0) throw ArgumentError('Chunk size must be greater than 0');
    return [
      for (var i = 0; i < length; i += size)
        sublist(i, (i + size > length ? length : i + size))
    ];
  }

  /// Shuffles the list randomly.
  void shuffleList() => shuffle();

  /// Finds the median of a list of numbers.
  double? median() {
    if (isEmpty) return null;
    final sorted = [...this]..sort();
    final middle = length ~/ 2;
    return length.isOdd
        ? sorted[middle] as double
        : ((sorted[middle - 1] as double) + (sorted[middle] as double)) / 2;
  }

  /// Flattens a nested list.
  List<dynamic> flatten() =>
      expand((item) => item is List ? item.flatten() : [item]).toList();

  /// Applies a function to each element and returns a new list.
  List<R> mapIndexed<R>(R Function(int index, T item) transform) {
    final result = <R>[];
    for (var i = 0; i < length; i++) {
      result.add(transform(i, this[i]));
    }
    return result;
  }
}

/// Extension on int to add advanced utility methods.
extension IntExtension on int {
  /// Checks if the number is even.
  bool get isEven => this % 2 == 0;

  /// Checks if the number is odd.
  bool get isOdd => !isEven;

  /// Returns the factorial of the number.
  int factorial() {
    if (this < 0)
      throw ArgumentError('Negative numbers do not have a factorial');
    return this <= 1 ? 1 : this * (this - 1).factorial();
  }

  /// Checks if the number is a prime number.
  bool get isPrime {
    if (this <= 1) return false;
    for (var i = 2; i <= sqrt(this).toInt(); i++) {
      // Fixed by importing dart:math
      if (this % i == 0) return false;
    }
    return true;
  }

  /// Finds the greatest common divisor (GCD) of two numbers.
  int gcd(int other) {
    int a = this;
    int b = other;
    while (b != 0) {
      final temp = b;
      b = a % b;
      a = temp;
    }
    return a.abs();
  }

  /// Converts the number to a binary string.
  String toBinary() => toRadixString(2);

  /// Converts the number to a hexadecimal string.
  String toHex() => toRadixString(16);
}

/// Extension on DateTime to add advanced utility methods.
extension DateTimeExtension on DateTime {
  /// Formats the date as a string in the given format.
  String format(String pattern) {
    final replacements = {
      'yyyy': year.toString(),
      'MM': month.toString().padLeft(2, '0'),
      'dd': day.toString().padLeft(2, '0'),
      'HH': hour.toString().padLeft(2, '0'),
      'mm': minute.toString().padLeft(2, '0'),
      'ss': second.toString().padLeft(2, '0'),
    };
    return replacements.entries.fold(pattern, (result, entry) {
      return result.replaceAll(entry.key, entry.value);
    });
  }

  /// Checks if the date is today.
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Adds a given number of weekdays to the date.
  DateTime addWeekdays(int days) {
    var result = this;
    var addedDays = 0;
    while (addedDays < days) {
      result = result.add(Duration(days: 1));
      if (result.weekday != DateTime.saturday &&
          result.weekday != DateTime.sunday) {
        addedDays++;
      }
    }
    return result;
  }

  /// Calculates the difference in days between two dates.
  int differenceInDays(DateTime other) => difference(other).inDays;

  /// Calculates the difference in weeks between two dates.
  int differenceInWeeks(DateTime other) => difference(other).inDays ~/ 7;
}

/// Extension on Map<K, V> to add advanced utility methods.
extension MapExtension<K, V> on Map<K, V> {
  /// Returns a new map with keys transformed by the given function.
  Map<R, V> mapKeys<R>(R Function(K key) transform) {
    return map((key, value) => MapEntry(transform(key), value));
  }

  /// Returns a new map with values transformed by the given function.
  Map<K, R> mapValues<R>(R Function(V value) transform) {
    return map((key, value) => MapEntry(key, transform(value)));
  }

  /// Returns a new map with entries filtered by the given predicate.
  Map<K, V> whereEntries(bool Function(K key, V value) test) {
    return Map.fromEntries(
        entries.where((entry) => test(entry.key, entry.value)));
  }

  /// Merges another map into this map.
  Map<K, V> merge(Map<K, V> other) {
    final result = Map<K, V>.from(this);
    other.forEach((key, value) {
      result[key] = value;
    });
    return result;
  }

  /// Inverts the keys and values of the map.
  Map<V, K> invert() {
    return map((key, value) => MapEntry(value, key));
  }
}

/// Example usage of extensions.
void main() {
  // String extensions.
  print("hello world".toPascalCase()); // Prints: HelloWorld

  // List extensions.
  final nestedList = [
    1,
    [
      2,
      [3, 4]
    ],
    5
  ];
  print(nestedList.flatten()); // Prints: [1, 2, 3, 4, 5]

  // int extensions.
  print(7.isPrime); // Prints: true
  print(12.gcd(18)); // Prints: 6
}
