void main() {
  for (int i = 1; i <= 5; i++) {
    print("Iteration: $i");
  }

  int i = 0;

  while (i < 5) {
    print("Iteration: ${i + 1}");
    i++;
  }

  do {
    print("Iteration: ${i + 1}");
    i++;
  } while (i < 5);

  var collection = [1, 2, 3, 4, 5];
  
  for (var element in collection) {
    print("Element: $element");
  }
}
