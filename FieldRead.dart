class FieldRead {
  var slot;
  bench() {
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
}

