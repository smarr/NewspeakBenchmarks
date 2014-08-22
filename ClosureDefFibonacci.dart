class ClosureDefFibonacci {
  bench() {
    this.fib(25);
  }
  fib(x) {
    f(n) => n < 2 ? 1 : fib(n-1) + fib(n-2);
    return f(x);
  }
}

