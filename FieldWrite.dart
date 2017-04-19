class FieldWrite {
  var slot;
  bench() {
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
}

