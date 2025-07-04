import 'dart:async';
import 'package:meta/meta.dart';
import 'package:synchronized/synchronized.dart';

// Define ListChangeType enum first
enum ListChangeType { add, remove, update, bulk }

// Define ListChangeEvent class
@immutable
class ListChangeEvent<T> {
  final ListChangeType type;
  final List<T> items;
  final T? item;
  final int? index;

  const ListChangeEvent._(
    this.type,
    this.items, {
    this.item,
    this.index,
  });

  factory ListChangeEvent.add(T item) =>
      ListChangeEvent._(ListChangeType.add, const [], item: item);

  factory ListChangeEvent.bulk(List<T> items) =>
      ListChangeEvent._(ListChangeType.bulk, items);
}

// Advanced type constraints
abstract class Identifiable {
  String get id;
}

// Custom iterator implementation
class ReverseIterator<T> implements Iterator<T> {
  final List<T> _list;
  int _index;

  ReverseIterator(this._list) : _index = _list.length;

  @override
  T get current => _list[_index];

  @override
  bool moveNext() => --_index >= 0;
}

// Enhanced type-safe list with more enterprise features
class TypeSafeList<T extends Object> implements Iterable<T> {
  final List<T> _items;
  final StreamController<ListChangeEvent<T>> _changeController;
  // ignore: unused_field
  final bool _growable;
  final Lock _lock = Lock();

  TypeSafeList({
    bool growable = true,
    int? initialCapacity,
  })  : _items = List<T>.empty(growable: growable),
        _growable = growable,
        _changeController = StreamController<ListChangeEvent<T>>.broadcast() {
    if (initialCapacity != null) {
      _items.length = initialCapacity;
    }
  }

  // Implementing Iterable interface methods
  @override
  Iterator<T> get iterator => _items.iterator;

  @override
  bool any(bool Function(T element) test) => _items.any(test);

  @override
  Iterable<R> cast<R>() => _items.cast<R>();

  @override
  bool contains(Object? element) => _items.contains(element);

  @override
  T elementAt(int index) => _items[index];

  @override
  bool every(bool Function(T element) test) => _items.every(test);

  @override
  Iterable<E> expand<E>(Iterable<E> Function(T element) toElements) =>
      _items.expand(toElements);

  @override
  T get first => _items.first;

  @override
  T firstWhere(bool Function(T element) test, {T Function()? orElse}) =>
      _items.firstWhere(test, orElse: orElse);

  @override
  E fold<E>(E initialValue, E Function(E previousValue, T element) combine) =>
      _items.fold(initialValue, combine);

  @override
  Iterable<T> followedBy(Iterable<T> other) => _items.followedBy(other);

  @override
  void forEach(void Function(T element) action) => _items.forEach(action);

  @override
  bool get isEmpty => _items.isEmpty;

  @override
  bool get isNotEmpty => _items.isNotEmpty;

  @override
  String join([String separator = ""]) => _items.join(separator);

  @override
  T get last => _items.last;

  @override
  T lastWhere(bool Function(T element) test, {T Function()? orElse}) =>
      _items.lastWhere(test, orElse: orElse);

  @override
  int get length => _items.length;

  @override
  Iterable<E> map<E>(E Function(T e) toElement) => _items.map(toElement);

  @override
  T reduce(T Function(T value, T element) combine) => _items.reduce(combine);

  @override
  T get single => _items.single;

  @override
  T singleWhere(bool Function(T element) test, {T Function()? orElse}) =>
      _items.singleWhere(test, orElse: orElse);

  @override
  Iterable<T> skip(int count) => _items.skip(count);

  @override
  Iterable<T> skipWhile(bool Function(T value) test) => _items.skipWhile(test);

  @override
  Iterable<T> take(int count) => _items.take(count);

  @override
  Iterable<T> takeWhile(bool Function(T value) test) => _items.takeWhile(test);

  @override
  List<T> toList({bool growable = true}) => _items.toList(growable: growable);

  @override
  Set<T> toSet() => _items.toSet();

  @override
  Iterable<T> where(bool Function(T element) test) => _items.where(test);

  @override
  Iterable<E> whereType<E>() => _items.whereType<E>();

  // CRUD Operations
  void add(T item) {
    _items.add(item);
    _notifyListeners(ListChangeEvent.add(item));
  }

  void addAll(Iterable<T> items) {
    _items.addAll(items);
    _notifyListeners(ListChangeEvent.bulk(items.toList()));
  }

  bool remove(T item) {
    final result = _items.remove(item);
    if (result) {
      _notifyListeners(
          ListChangeEvent._(ListChangeType.remove, [], item: item));
    }
    return result;
  }

  // Use _lock in synchronized operations
  Future<void> addAllAsync(Iterable<T> items) async {
    await _lock.synchronized(() async {
      _items.addAll(items);
      _notifyListeners(ListChangeEvent.bulk(items.toList()));
    });
  }

  // Remove duplicate toList() method since we already have the proper override
  // from Iterable interface that handles the growable parameter

  void _notifyListeners(ListChangeEvent<T> event) {
    _changeController.add(event);
  }
}

enum TransactionType { credit, debit }

// Custom annotation for validation
@sealed
class assertPositive {
  const assertPositive();
}

// Advanced extension methods
extension TypeSafeListExtensions<T extends Object> on TypeSafeList<T> {
  TypeSafeList<T> distinctBy<K>(K Function(T) keySelector) {
    final seen = <K>{};
    final result = TypeSafeList<T>();
    for (var item in this) {
      final key = keySelector(item);
      if (seen.add(key)) {
        result.add(item);
      }
    }
    return result;
  }

  Map<K, V> associate<K, V>(MapEntry<K, V> Function(T) transform) {
    return Map.fromEntries(map(transform));
  }
}

// Keep all other classes (ListChangeEvent, CustomRangeError, PagedResult, etc.) as they are

void main() {
  // Example usage of TypeSafeList
  final list = TypeSafeList<int>();
  list.add(1);
  list.add(2);
  list.add(3);

  print('List items: ${list.toList()}');

  // Demonstrate distinctBy extension
  final distinctList = list.distinctBy((item) => item % 2);
  print('Distinct items: ${distinctList.toList()}');
}
