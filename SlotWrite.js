function SlotWrite() {
  this._slot = null;
}
SlotWrite.prototype.getSlot = function() {
  return this._slot;
}
SlotWrite.prototype.setSlot = function(v) {
  this._slot = v;
  return this;
}
SlotWrite.prototype.bench = function() {
  var something = 'something';
  for (var i = 0; i < 100000; i++) {
    this.setSlot(something);
    this.setSlot(something);
    this.setSlot(something);
    this.setSlot(something);
    this.setSlot(something);
    this.setSlot(something);
    this.setSlot(something);
    this.setSlot(something);
    this.setSlot(something);
    this.setSlot(something);
  }
}
global.SlotWrite = SlotWrite;
