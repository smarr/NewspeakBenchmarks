function ClosureDefFibonacci() {
}
ClosureDefFibonacci.prototype.bench = function() {
  this.fib(25);
}
ClosureDefFibonacci.prototype.fib = function(x) {
  var self = this;
  function f(n) {
    return n < 2 ? 1 : self.fib(n-1) + self.fib(n-2);
  }
  return f(x);
}
global.ClosureDefFibonacci = ClosureDefFibonacci;
