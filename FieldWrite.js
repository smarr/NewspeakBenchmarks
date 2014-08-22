function FieldWrite() {
  this.slot = null;
}
FieldWrite.prototype.bench = function() {
  var something = 'something';
  for(var i = 0; i < 100000; i++) {
    this.slot = something;
    this.slot = something;
    this.slot = something;
    this.slot = something;
    this.slot = something;
    this.slot = something;
    this.slot = something;
    this.slot = something;
    this.slot = something;
    this.slot = something;
  }
}
global.FieldWrite = FieldWrite;
