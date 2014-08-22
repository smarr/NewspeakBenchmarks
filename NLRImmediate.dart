class NLR {
  var value;
}

class NLRImmediate {
  bench() {
    for (var i = 0; i < 10000; i++) {
      this.nlr();
    }
  }
  nlr() {
    var thisActivation = new NLR();
    try {
      run(() {
        thisActivation.value = 2;
        throw thisActivation;
      });
      return 1;
    } catch (e) {
      if (thisActivation == e) {
        return e.value;
      }
      throw e;
    }
  }
  run(f) {
    f();
  }
}
