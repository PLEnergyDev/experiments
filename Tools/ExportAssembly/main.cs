using System;

class Program {
  static int sum() {
    int sum = 0;
    for (int i = 0; i < 10; i++) {
      sum += i;
    }
    return sum;
  }

  static void Main(string[] args) {
    Console.WriteLine(sum());
  }
}
