// Abstract class: Cannot be instantiated directly
abstract class AbstractClass {
  void abstractMethod();
}

// Concrete implementation of AbstractClass
class ConcreteClass extends AbstractClass {
  @override
  void abstractMethod() => print("Abstract method implemented.");
}

// Sealed class: Cannot be extended outside its library
sealed class SealedClass {
  void sealedMethod() => print("This is a sealed class method.");
}

// Concrete implementation of SealedClass
final class ConcreteSealedClass extends SealedClass {}

// Base class: Can only be extended, not implemented or mixed in
base class BaseClass {
  void baseMethod() => print("This is a base class method.");
}

// Derived class from BaseClass must be base, final, or sealed
base class DerivedBaseClass extends BaseClass {}

// Interface class: Can be used as an interface
class InterfaceClass {
  void interfaceMethod() => print("This is an interface class method.");
}

// Implementation of InterfaceClass
class ImplementsInterface implements InterfaceClass {
  @override
  void interfaceMethod() => print("Interface method implemented.");
}

// Final class: Cannot be extended
final class FinalClass {
  void finalMethod() => print("This is a final class method.");
}

// Mixin class: Can be applied to other classes
mixin MixinClass {
  void mixinMethod() => print("This is a mixin class method.");
}

// Class that uses the mixin
class MixedClass with MixinClass {}

// Enum class: Defines an enumeration
enum EnumClass { value1, value2, value3 }

void main() {
  // Abstract class usage
  final concrete = ConcreteClass();
  concrete.abstractMethod();

  // Sealed class usage (within the same library)
  final sealed = ConcreteSealedClass();
  sealed.sealedMethod();

  // Base class usage
  final base = DerivedBaseClass();
  base.baseMethod();

  // Interface class usage
  final interface = ImplementsInterface();
  interface.interfaceMethod();

  // Final class usage
  final finalClass = FinalClass();
  finalClass.finalMethod();

  // Mixin class usage
  final mixed = MixedClass();
  mixed.mixinMethod();

  // Enum class usage
  final enumValue = EnumClass.value1;
  print("Enum value: $enumValue");
}
