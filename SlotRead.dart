class SlotRead {
  var _slot;
  getSlot() {
    return this._slot;
  }
  setSlot(v) {
    this._slot = v;
    return this;
  }
  bench() {
    this.setSlot('something');
    for(var i = 0; i < 100000; i++) {
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
}

