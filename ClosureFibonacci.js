function ClosureFibonacci() {
}
ClosureFibonacci.prototype.bench = function() {
  this.fib()(25);
}
ClosureFibonacci.prototype.fib = function() {
  function f(n) {
    return n < 2 ? 1 : f(n-1) + f(n-2);
  }
  return f;
}
global.ClosureFibonacci = ClosureFibonacci;
