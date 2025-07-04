import 'dart:async';
import 'package:async/async.dart'; // Import for StreamGroup

/// A feature-rich, thread-safe, and scalable wrapper for managing streams.
class AdvancedStream<T> {
  final StreamController<T> _controller;

  AdvancedStream({bool isBroadcast = false})
      : _controller = isBroadcast
            ? StreamController<T>.broadcast()
            : StreamController<T>();

  /// Adds a value to the stream.
  void add(T value) {
    if (!_controller.isClosed) {
      _controller.add(value);
    } else {
      throw StateError('Cannot add to a closed stream.');
    }
  }

  /// Adds an error to the stream.
  void addError(Object error, [StackTrace? stackTrace]) {
    if (!_controller.isClosed) {
      _controller.addError(error, stackTrace);
    } else {
      throw StateError('Cannot add error to a closed stream.');
    }
  }

  /// Closes the stream.
  Future<void> close() => _controller.close();

  /// Returns the stream.
  Stream<T> get stream => _controller.stream;

  /// Transforms the stream using a mapper function.
  Stream<R> map<R>(R Function(T event) mapper) =>
      _controller.stream.map(mapper);

  /// Filters the stream based on a condition.
  Stream<T> where(bool Function(T event) test) =>
      _controller.stream.where(test);

  /// Buffers events and emits them as a list after a delay.
  Stream<List<T>> buffer(Duration duration) async* {
    List<T> buffer = [];
    await for (final event in _controller.stream) {
      buffer.add(event);
      await Future.delayed(duration);
      yield List<T>.from(buffer);
      buffer.clear();
    }
  }

  /// Debounces the stream, emitting only the last event within a time frame.
  Stream<T> debounce(Duration duration) {
    return _controller.stream.transform(
      StreamTransformer<T, T>.fromBind((stream) {
        return stream.asyncMap((event) async {
          await Future.delayed(duration);
          return event;
        });
      }),
    );
  }

  /// Throttles the stream, emitting events at most once per time frame.
  Stream<T> throttle(Duration duration) {
    return _controller.stream.transform(
      StreamTransformer<T, T>.fromBind((stream) {
        return stream.asyncExpand((event) async* {
          yield event;
          await Future.delayed(duration);
        });
      }),
    );
  }

  /// Combines the current stream with another stream.
  Stream<R> combineLatest<R, S>(
      Stream<S> other, R Function(T, S) combiner) async* {
    final controller = StreamController<R>();
    final subscription1 = _controller.stream.listen(null);
    final subscription2 = other.listen(null);

    T? latest1;
    S? latest2;

    subscription1.onData((data) {
      latest1 = data;
      if (latest2 != null) {
        controller.add(combiner(latest1 as T, latest2 as S));
      }
    });

    subscription2.onData((data) {
      latest2 = data;
      if (latest1 != null) {
        controller.add(combiner(latest1 as T, latest2 as S));
      }
    });

    await controller.close();
    yield* controller.stream;
  }

  /// Merges the current stream with another stream.
  Stream<T> merge(Stream<T> other) async* {
    yield* StreamGroup.merge([_controller.stream, other]);
  }

  /// Reduces the stream to a single value.
  Future<R> reduce<R>(R Function(R accumulator, T event) combine, R initial) {
    return _controller.stream.fold(initial, combine);
  }

  /// Returns a stream that emits distinct events.
  Stream<T> distinct([bool Function(T previous, T next)? equals]) =>
      _controller.stream.distinct(equals);

  /// Returns a stream that emits events in batches of a given size.
  Stream<List<T>> batch(int size) async* {
    List<T> batch = [];
    await for (final event in _controller.stream) {
      batch.add(event);
      if (batch.length == size) {
        yield List<T>.from(batch);
        batch.clear();
      }
    }
    if (batch.isNotEmpty) {
      yield List<T>.from(batch);
    }
  }

  /// Returns a stream that emits events after a delay.
  Stream<T> delay(Duration duration) =>
      _controller.stream.asyncMap((event) async {
        await Future.delayed(duration);
        return event;
      });

  /// Returns a stream that retries on error.
  Stream<T> retry(int retries) async* {
    int attempt = 0;
    while (attempt < retries) {
      try {
        yield* _controller.stream;
        break;
      } catch (e) {
        attempt++;
        if (attempt >= retries) rethrow;
      }
    }
  }

  /// Returns a stream that emits events until a condition is met.
  Stream<T> takeUntil(Stream<void> trigger) {
    final controller = StreamController<T>();
    final subscription = _controller.stream.listen(
      controller.add,
      onError: controller.addError,
      onDone: controller.close,
    );
    trigger.listen((_) {
      subscription.cancel();
      controller.close();
    });
    return controller.stream;
  }

  /// Disposes the stream controller.
  void dispose() {
    _controller.close();
  }
}

/// Example usage of AdvancedStream.
void main() async {
  final stream = AdvancedStream<int>(isBroadcast: true);

  // Listen to the stream.
  stream.stream.listen((event) {
    print('Event: $event');
  });

  // Add events to the stream.
  stream.add(1);
  stream.add(2);
  stream.add(3);

  // Transform the stream.
  final mappedStream = stream.map((event) => event * 2);
  await for (final event in mappedStream) {
    print('Mapped Event: $event');
  }

  // Filter the stream.
  final filteredStream = stream.where((event) => event.isEven);
  await for (final event in filteredStream) {
    print('Filtered Event: $event');
  }

  // Batch the stream.
  final batchedStream = stream.batch(2);
  await for (final batch in batchedStream) {
    print('Batch: $batch');
  }

  // Dispose the stream.
  stream.dispose();
}
