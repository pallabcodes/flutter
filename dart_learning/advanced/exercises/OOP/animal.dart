// 2. Runtime Polymorphism (Method Overriding)
// Dart supports runtime polymorphism through inheritance and method overriding.

class Animal {
  void makeSound() {
    print("Animal makes a sound");
  }
}

class Dog extends Animal {
  @override
  void makeSound() {
    print("Dog barks");
  }
}

class Cat extends Animal {
  @override
  void makeSound() {
    print("Cat meows");
  }
}

void main() {
  Animal animal;

  animal = Dog();
  animal.makeSound(); // Output: Dog barks (runtime decision)

  animal = Cat();
  animal.makeSound(); // Output: Cat meows (runtime decision)
}

// Explanation:

// The makeSound method is overridden in the Dog and Cat classes.
// The decision about which method to call is made at runtime, based on the actual object type (Dog or Cat).