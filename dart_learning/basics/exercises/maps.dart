import 'dart:async';
import 'dart:collection';

/// A type-safe, thread-safe, and feature-rich wrapper for managing maps.
class TypeSafeMap<K, V> {
  final Map<K, V> _items = {};
  final bool Function(K a, K b)? _keyEqualityComparator;
  final StreamController<MapChangeEvent<K, V>> _changeController =
      StreamController<MapChangeEvent<K, V>>.broadcast();

  TypeSafeMap({bool Function(K a, K b)? keyEqualityComparator})
      : _keyEqualityComparator = keyEqualityComparator;

  /// Stream for reactive programming.
  Stream<MapChangeEvent<K, V>> get onChange => _changeController.stream;

  /// Adds a key-value pair to the map.
  void add(K key, V value) {
    if (_keyEqualityComparator != null) {
      if (_items.keys
          .any((existingKey) => _keyEqualityComparator!(existingKey, key))) {
        throw ArgumentError(
            'Duplicate key detected based on custom comparator.');
      }
    }
    _items[key] = value;
    _notifyListeners(MapChangeEvent.add(key, value));
  }

  /// Adds multiple key-value pairs to the map.
  void addAll(Map<K, V> entries) {
    entries.forEach((key, value) => add(key, value));
  }

  /// Removes a key-value pair by key.
  bool remove(K key) {
    final removed = _items.remove(key);
    if (removed != null) {
      _notifyListeners(MapChangeEvent.remove(key, removed));
      return true;
    }
    return false;
  }

  /// Checks if the map contains a key.
  bool containsKey(K key) => _items.containsKey(key);

  /// Checks if the map contains a value.
  bool containsValue(V value) => _items.containsValue(value);

  /// Gets the value associated with a key.
  V? get(K key) => _items[key];

  /// Returns the number of key-value pairs in the map.
  int get length => _items.length;

  /// Clears all key-value pairs from the map.
  void clear() {
    _items.clear();
    _notifyListeners(MapChangeEvent.clear());
  }

  /// Converts the map to an unmodifiable view.
  UnmodifiableMapView<K, V> get unmodifiableView => UnmodifiableMapView(_items);

  /// Returns all keys in the map.
  Iterable<K> get keys => _items.keys;

  /// Returns all values in the map.
  Iterable<V> get values => _items.values;

  /// Merges another map into this map.
  void merge(Map<K, V> other,
      {V Function(V existing, V incoming)? conflictResolver}) {
    other.forEach((key, value) {
      if (_items.containsKey(key) && conflictResolver != null) {
        _items[key] = conflictResolver(_items[key] as V, value);
      } else {
        _items[key] = value;
      }
    });
    _notifyListeners(MapChangeEvent.bulk(other));
  }

  /// Filters the map based on a condition.
  TypeSafeMap<K, V> where(bool Function(K key, V value) test) {
    final result =
        TypeSafeMap<K, V>(keyEqualityComparator: _keyEqualityComparator);
    _items.forEach((key, value) {
      if (test(key, value)) {
        result.add(key, value);
      }
    });
    return result;
  }

  /// Maps the keys and values to a new map.
  TypeSafeMap<RK, RV> map<RK, RV>(
      MapEntry<RK, RV> Function(K key, V value) transform) {
    final result = TypeSafeMap<RK, RV>();
    _items.forEach((key, value) {
      final entry = transform(key, value);
      result.add(entry.key, entry.value);
    });
    return result;
  }

  /// Groups the map's entries by a key selector.
  Map<RK, List<MapEntry<K, V>>> groupBy<RK>(
      RK Function(K key, V value) keySelector) {
    final result = <RK, List<MapEntry<K, V>>>{};
    _items.forEach((key, value) {
      final groupKey = keySelector(key, value);
      result.putIfAbsent(groupKey, () => []).add(MapEntry(key, value));
    });
    return result;
  }

  /// Reduces the map to a single value.
  R reduce<R>(
      R Function(R accumulator, K key, V value) combine, R initialValue) {
    var result = initialValue;
    _items.forEach((key, value) {
      result = combine(result, key, value);
    });
    return result;
  }

  /// Partitions the map into two maps based on a condition.
  Map<bool, TypeSafeMap<K, V>> partition(bool Function(K key, V value) test) {
    final matches =
        TypeSafeMap<K, V>(keyEqualityComparator: _keyEqualityComparator);
    final nonMatches =
        TypeSafeMap<K, V>(keyEqualityComparator: _keyEqualityComparator);
    _items.forEach((key, value) {
      if (test(key, value)) {
        matches.add(key, value);
      } else {
        nonMatches.add(key, value);
      }
    });
    return {true: matches, false: nonMatches};
  }

  /// Notifies listeners of changes to the map.
  void _notifyListeners(MapChangeEvent<K, V> event) {
    _changeController.add(event);
  }

  /// Disposes the stream controller.
  void dispose() {
    _changeController.close();
  }

  /// Returns a string representation of the map.
  @override
  String toString() => _items.toString();
}

/// Represents a change event in the map.
class MapChangeEvent<K, V> {
  final MapChangeType type;
  final K? key;
  final V? value;
  final Map<K, V>? bulkEntries;

  MapChangeEvent._(this.type, {this.key, this.value, this.bulkEntries});

  factory MapChangeEvent.add(K key, V value) =>
      MapChangeEvent._(MapChangeType.add, key: key, value: value);

  factory MapChangeEvent.remove(K key, V value) =>
      MapChangeEvent._(MapChangeType.remove, key: key, value: value);

  factory MapChangeEvent.clear() => MapChangeEvent._(MapChangeType.clear);

  factory MapChangeEvent.bulk(Map<K, V> entries) =>
      MapChangeEvent._(MapChangeType.bulk, bulkEntries: entries);
}

/// Enum for map change types.
enum MapChangeType { add, remove, clear, bulk }

/// Example usage of TypeSafeMap.
void main() {
  // Create a type-safe map of integers to strings.
  final map = TypeSafeMap<int, String>();

  // Add key-value pairs to the map.
  map.add(1, 'One');
  map.add(2, 'Two');
  map.add(3, 'Three');

  print('Map: $map');

  // Merge another map with conflict resolution.
  final otherMap = {2: 'Deux', 4: 'Four'};
  map.merge(otherMap,
      conflictResolver: (existing, incoming) => '$existing/$incoming');
  print('Merged Map: $map');

  // Filter the map.
  final filteredMap = map.where((key, value) => key.isEven);
  print('Filtered Map (even keys): $filteredMap');

  // Map the entries to a new map.
  final mappedMap =
      map.map((key, value) => MapEntry('Key $key', value.toUpperCase()));
  print('Mapped Map: $mappedMap');

  // Group the entries by the length of the value.
  final groupedMap = map.groupBy((key, value) => value.length);
  print('Grouped Map: $groupedMap');

  // Reduce the map to a single value.
  final concatenatedValues =
      map.reduce((acc, key, value) => '$acc, $value', '');
  print('Concatenated Values: $concatenatedValues');

  // Partition the map into two maps based on a condition.
  final partitioned = map.partition((key, value) => key.isOdd);
  print('Odd Keys: ${partitioned[true]}');
  print('Even Keys: ${partitioned[false]}');

  // Reactive programming example.
  map.onChange.listen((event) {
    print(
        'Map changed: ${event.type}, Key: ${event.key}, Value: ${event.value}');
  });

  map.add(5, 'Five');
  map.remove(2);
  map.clear();

  // Dispose resources.
  map.dispose();
}
