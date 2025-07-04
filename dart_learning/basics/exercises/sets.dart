import 'dart:async';
import 'dart:collection';

/// A type-safe, thread-safe, and feature-rich wrapper for managing sets.
class TypeSafeSet<T> {
  final Set<T> _items = {};
  final bool Function(T a, T b)? _equalityComparator;
  final StreamController<SetChangeEvent<T>> _changeController =
      StreamController<SetChangeEvent<T>>.broadcast();

  TypeSafeSet({bool Function(T a, T b)? equalityComparator})
      : _equalityComparator = equalityComparator;

  /// Stream for reactive programming.
  Stream<SetChangeEvent<T>> get onChange => _changeController.stream;

  /// Adds an item to the set.
  bool add(T item) {
    if (_equalityComparator != null) {
      if (_items.any((existing) => _equalityComparator!(existing, item))) {
        return false;
      }
    }
    final added = _items.add(item);
    if (added) {
      _notifyListeners(SetChangeEvent.add(item));
    }
    return added;
  }

  /// Adds multiple items to the set.
  void addAll(Iterable<T> items) {
    for (var item in items) {
      add(item);
    }
  }

  /// Removes an item from the set.
  bool remove(T item) {
    final removed = _items.remove(item);
    if (removed) {
      _notifyListeners(SetChangeEvent.remove(item));
    }
    return removed;
  }

  /// Checks if the set contains an item.
  bool contains(T item) => _items.contains(item);

  /// Returns the number of items in the set.
  int get length => _items.length;

  /// Clears all items from the set.
  void clear() {
    _items.clear();
    _notifyListeners(SetChangeEvent.clear());
  }

  /// Converts the set to a list.
  List<T> toList() => _items.toList();

  /// Converts the set to an unmodifiable view.
  UnmodifiableSetView<T> get unmodifiableView => UnmodifiableSetView(_items);

  /// Performs a union operation with another set.
  TypeSafeSet<T> union(TypeSafeSet<T> other) {
    final result = TypeSafeSet<T>(equalityComparator: _equalityComparator);
    result.addAll(_items);
    result.addAll(other._items);
    return result;
  }

  /// Performs an intersection operation with another set.
  TypeSafeSet<T> intersection(TypeSafeSet<T> other) {
    final result = TypeSafeSet<T>(equalityComparator: _equalityComparator);
    for (var item in _items) {
      if (other.contains(item)) {
        result.add(item);
      }
    }
    return result;
  }

  /// Performs a difference operation with another set.
  TypeSafeSet<T> difference(TypeSafeSet<T> other) {
    final result = TypeSafeSet<T>(equalityComparator: _equalityComparator);
    for (var item in _items) {
      if (!other.contains(item)) {
        result.add(item);
      }
    }
    return result;
  }

  /// Checks if the set is a subset of another set.
  bool isSubsetOf(TypeSafeSet<T> other) {
    for (var item in _items) {
      if (!other.contains(item)) {
        return false;
      }
    }
    return true;
  }

  /// Checks if the set is a superset of another set.
  bool isSupersetOf(TypeSafeSet<T> other) {
    for (var item in other._items) {
      if (!contains(item)) {
        return false;
      }
    }
    return true;
  }

  /// Returns an iterable of items that satisfy a condition.
  Iterable<T> where(bool Function(T item) test) => _items.where(test);

  /// Maps the items in the set to a new set.
  TypeSafeSet<R> map<R>(R Function(T item) transform) {
    final result = TypeSafeSet<R>();
    for (var item in _items) {
      result.add(transform(item));
    }
    return result;
  }

  /// Partitions the set into two sets based on a condition.
  Map<bool, TypeSafeSet<T>> partition(bool Function(T item) test) {
    final matches = TypeSafeSet<T>();
    final nonMatches = TypeSafeSet<T>();
    for (var item in _items) {
      if (test(item)) {
        matches.add(item);
      } else {
        nonMatches.add(item);
      }
    }
    return {true: matches, false: nonMatches};
  }

  /// Reduces the set to a single value.
  R reduce<R>(R Function(R accumulator, T item) combine, R initialValue) {
    var result = initialValue;
    for (var item in _items) {
      result = combine(result, item);
    }
    return result;
  }

  /// Notifies listeners of changes to the set.
  void _notifyListeners(SetChangeEvent<T> event) {
    _changeController.add(event);
  }

  /// Disposes the stream controller.
  void dispose() {
    _changeController.close();
  }

  /// Returns a string representation of the set.
  @override
  String toString() => _items.toString();
}

/// Represents a change event in the set.
class SetChangeEvent<T> {
  final SetChangeType type;
  final T? item;

  SetChangeEvent._(this.type, [this.item]);

  factory SetChangeEvent.add(T item) =>
      SetChangeEvent._(SetChangeType.add, item);

  factory SetChangeEvent.remove(T item) =>
      SetChangeEvent._(SetChangeType.remove, item);

  factory SetChangeEvent.clear() => SetChangeEvent._(SetChangeType.clear);
}

/// Enum for set change types.
enum SetChangeType { add, remove, clear }

/// Example usage of TypeSafeSet.
void main() {
  // Create a type-safe set of integers.
  final set = TypeSafeSet<int>();

  // Add items to the set.
  set.add(1);
  set.add(2);
  set.add(3);

  print('Set: ${set.toList()}');

  // Perform union operation.
  final otherSet = TypeSafeSet<int>()..addAll([3, 4, 5]);
  final unionSet = set.union(otherSet);
  print('Union: ${unionSet.toList()}');

  // Perform intersection operation.
  final intersectionSet = set.intersection(otherSet);
  print('Intersection: ${intersectionSet.toList()}');

  // Perform difference operation.
  final differenceSet = set.difference(otherSet);
  print('Difference: ${differenceSet.toList()}');

  // Check subset and superset relationships.
  print('Is subset: ${set.isSubsetOf(unionSet)}');
  print('Is superset: ${unionSet.isSupersetOf(set)}');

  // Map items to a new set.
  final mappedSet = set.map((item) => item * 2);
  print('Mapped: ${mappedSet.toList()}');

  // Partition the set.
  final partitioned = set.partition((item) => item % 2 == 0);
  print('Even: ${partitioned[true]?.toList()}');
  print('Odd: ${partitioned[false]?.toList()}');

  // Reduce the set to a single value.
  final sum = set.reduce((acc, item) => acc + item, 0);
  print('Sum: $sum');

  // Reactive programming example.
  set.onChange.listen((event) {
    print('Set changed: ${event.type}, Item: ${event.item}');
  });

  set.add(4);
  set.remove(2);
  set.clear();

  // Dispose resources.
  set.dispose();
}
