function SlotRead() {
  this._slot = null;
}
SlotRead.prototype.getSlot = function() {
  return this._slot;
}
SlotRead.prototype.setSlot = function(v) {
  this._slot = v;
  return this;
}
SlotRead.prototype.bench = function() {
  this.setSlot('something');
  for (var i = 0; i < 100000; i++) {
    this.getSlot();
    this.getSlot();
    this.getSlot();
    this.getSlot();
    this.getSlot();
    this.getSlot();
    this.getSlot();
    this.getSlot();
    this.getSlot();
    this.getSlot();
  }
}
global.SlotRead = SlotRead;
