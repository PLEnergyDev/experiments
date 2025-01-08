class Main {
  static int sum() {
    int sum = 0;
    for (int i = 0; i < 10; i++) {
      sum += i;
    }
    return sum;
  }

  public static void main(String[] args) {
    System.out.println(sum());
  }
}
