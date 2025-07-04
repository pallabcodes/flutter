// 1. Mixin Constraints - Using 'on' keyword to restrict mixin usage
mixin CanFly on Bird {
  double flyingAltitude = 0.0;

  void fly() {
    print('Flying at altitude: $flyingAltitude meters');
  }

  void increaseAltitude(double delta) {
    flyingAltitude += delta;
    print('Increased altitude to: $flyingAltitude meters');
  }
}

// 2. Mixin Stacking - Order matters due to lookup chain
mixin Logger {
  void log(String message) => print('LOG: $message');
}

mixin TimeStamped {
  DateTime timestamp = DateTime.now();
  String getTimestamp() => timestamp.toIso8601String();
}

// 3. Abstract Mixin - Defining contract
mixin ValidatorMixin {
  bool validate();
  List<String> getErrors();
}

// 4. Mixin with Generic Type Parameters
mixin DataPersistence<T> {
  List<T> _cache = [];

  void save(T item) => _cache.add(item);
  List<T> getAll() => List.unmodifiable(_cache);
  void clear() => _cache.clear();
}

// 5. Base Classes
abstract class Bird {
  String species;
  Bird(this.species);

  void makeSound();
}

// 6. Class using multiple mixins
class Eagle extends Bird with CanFly, Logger, TimeStamped {
  Eagle() : super('Eagle');

  @override
  void makeSound() {
    log('Eagle screech at ${getTimestamp()}');
  }

  void hunt() {
    log('Started hunting at ${getTimestamp()}');
    increaseAltitude(100);
    // Hunting logic
  }
}

// 7. Mixin with State Management
mixin StateManagement {
  Map<String, dynamic> _state = {};

  T? getValue<T>(String key) => _state[key] as T?;
  void setValue<T>(String key, T value) => _state[key] = value;
  void clearState() => _state.clear();
}

// 8. Mixin with Resource Management
mixin ResourceHandler {
  final List<Object> _resources = [];

  void acquireResource(Object resource) {
    _resources.add(resource);
  }

  void releaseResources() {
    for (var resource in _resources) {
      // Resource cleanup logic
      print('Releasing resource: $resource');
    }
    _resources.clear();
  }
}

// 9. Mixin with Error Handling
mixin ErrorHandler {
  final List<String> _errors = [];

  void handleError(String error) {
    _errors.add(error);
    print('Error occurred: $error');
  }

  bool hasErrors() => _errors.isNotEmpty;
  List<String> getErrors() => List.unmodifiable(_errors);
}

// 10. Complex Example: Data Model with Validation and Persistence
class UserModel
    with ValidatorMixin, DataPersistence<Map<String, dynamic>>, ErrorHandler {
  String? email;
  String? password;

  bool validate() {
    if (email == null || !email!.contains('@')) {
      handleError('Invalid email format');
      return false;
    }
    if (password == null || password!.length < 8) {
      handleError('Password must be at least 8 characters');
      return false;
    }
    return true;
  }

  List<String> getErrors() => super.getErrors();

  void saveUser() {
    if (validate()) {
      save({'email': email, 'password': password});
    }
  }
}

// 11. Mixin for Async Operations
mixin AsyncOperationHandler {
  final Map<String, Future<dynamic>> _pendingOperations = {};

  Future<T> trackOperation<T>(String key, Future<T> operation) async {
    _pendingOperations[key] = operation;
    try {
      final result = await operation;
      _pendingOperations.remove(key);
      return result;
    } catch (e) {
      _pendingOperations.remove(key);
      rethrow;
    }
  }

  bool isOperationPending(String key) => _pendingOperations.containsKey(key);
}

// 12. Advanced Component with Multiple Mixins
class AdvancedComponent
    with StateManagement, ResourceHandler, AsyncOperationHandler {
  Future<void> initialize() async {
    setValue('initialized', true);
    acquireResource('DatabaseConnection');

    await trackOperation(
        'initialization',
        Future.delayed(
            Duration(seconds: 1), () => print('Component initialized')));
  }

  void dispose() {
    releaseResources();
    clearState();
  }
}

// Example Usage
void main() async {
  // Bird with mixins example
  final eagle = Eagle();
  eagle.makeSound();
  eagle.hunt();

  // User model with validation and persistence
  final user = UserModel()
    ..email = 'test@example.com'
    ..password = 'password123';

  user.saveUser();
  print('Saved users: ${user.getAll()}');

  // Advanced component usage
  final component = AdvancedComponent();
  await component.initialize();
  print('Is initialized: ${component.getValue<bool>('initialized')}');
  component.dispose();
}
