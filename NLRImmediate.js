function NLR() {
	this.value = null;
}
function NLRImmediate() {
}
NLRImmediate.prototype.bench = function() {
  for (var i = 0; i < 10000; i++) {
    this.nlr();
  }
}
NLRImmediate.prototype.nlr = function() {
  var thisActivation = new NLR();
    try {
      this.run(function(){
        thisActivation.value = 2;
        throw thisActivation;
      });
      return 1;
    } catch(e) {
      if (thisActivation === e) {
        return e.value;
      }
      throw e;
    }
}
NLRImmediate.prototype.run = function(f) {
  f();
}
global.NLRImmediate = NLRImmediate;
