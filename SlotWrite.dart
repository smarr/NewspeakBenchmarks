class SlotWrite {
  var _slot;
  getSlot() {
    return this._slot;
  }
  setSlot(v) {
    this._slot = v;
    return this;
  }
  bench() {
    var something = 'something';
    for(var i = 0; i < 100000; i++) {
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
}

