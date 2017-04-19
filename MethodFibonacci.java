class MethodFibonacci extends Benchmark {
  MethodFibonacci() { super("MethodFibonacci"); }
  public void run() {
    this.fib(25);
  }
  public int fib(int n) {
    return n < 2 ? 1 : this.fib(n-1) + this.fib(n-2);
  }
}
