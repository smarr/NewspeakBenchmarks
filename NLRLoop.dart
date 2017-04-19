class NLR {
  var value;
}

class NLRLoop {
  var array = [1, 2, 3, 4, 5, 6];
  bench() {
    for (var i = 0; i < 10000; i++) {
      this.nlr();
    }
  }
  nlr() {
    var thisActivation = new NLR();
    try {
      this.array.forEach((each) {
        if (each == 4) {
          thisActivation.value = each;
          throw thisActivation;
        }
      });
      return this;
    } catch (e) {
      if (thisActivation == e) {
        return e.value;
      }
      throw e;
    }
  }
}
