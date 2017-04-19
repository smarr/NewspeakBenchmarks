class MethodFibonacci {
  bench() {
    this.fib(25);
  }
  fib(n) {
    return n < 2 ? 1 : this.fib(n-1) + this.fib(n-2);
  }
}

