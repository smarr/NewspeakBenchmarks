function MethodFibonacci() {
}
MethodFibonacci.prototype.bench = function() {
  this.fib(25);
}
MethodFibonacci.prototype.fib = function(n) {
  return n < 2 ? 1 : this.fib(n-1) + this.fib(n-2);
}

global.MethodFibonacci = MethodFibonacci;

