function NLR() {
  this.value = null;
}
function NLRLoop() {
  this.array = [1, 2, 3, 4, 5, 6];
}
NLRLoop.prototype.bench = function() {
  for (var i = 0; i < 10000; i++) {
    this.nlr();
  }
}
NLRLoop.prototype.nlr = function() {
  var thisActivation = new NLR();
  try {
    this.array.forEach(function(each) {
      if (each == 4) {
        thisActivation.value = each;
        throw thisActivation;
      }
    });
    return this;
  } catch(e) {
    if (thisActivation === e) {
      return e.value;
    }
    throw e;
  }
}
global.NLRLoop = NLRLoop;
