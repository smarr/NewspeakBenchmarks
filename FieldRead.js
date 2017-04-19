function FieldRead() {
  this.slot = null;
}
FieldRead.prototype.bench = function() {
  this.slot = 'something';
  for(var i = 0; i < 100000; i++) {
    this.slot;
    this.slot;
    this.slot;
    this.slot;
    this.slot;
    this.slot;
    this.slot;
    this.slot;
    this.slot;
    this.slot;
  }
}
global.FieldRead = FieldRead;
