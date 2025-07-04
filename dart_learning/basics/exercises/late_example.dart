class LazyInitializationExample {
  late String description;

  void initialize() {
    description = "This is a late-initialized variable.";
  }

  void printDescription() {
    print(description);
  }
}

void main() {
  final example = LazyInitializationExample();

  // Initialize the late variable before accessing it
  example.initialize();
  example.printDescription(); // Prints: This is a late-initialized variable.
}
