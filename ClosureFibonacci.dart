class ClosureFibonacci {
  bench() {
    this.fib()(25);
  }
  fib() {
    f(n) => n < 2 ? 1 : f(n-1) + f(n-2);
    return f;
  }
}

