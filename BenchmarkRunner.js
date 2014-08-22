if (console) print = console.log;

require('./FieldRead.js');
require('./FieldWrite.js');
require('./SlotRead.js');
require('./SlotWrite.js');
require('./MethodFibonacci.js');
require('./ClosureFibonacci.js');
require('./ClosureDefFibonacci.js');
require('./NLRImmediate.js');
require('./NLRLoop.js');
require('./Splay.js');
require('./SplayHarder.js');
require('./DeltaBlue.js');
require('./Richards.js');

function benchmark(name, action) {
  var start, elapsed, runs;

  // Warm up.
  start = new Date();
  elapsed = 0;
  while (elapsed < 300) {
    action();
    elapsed = new Date() - start;
  }

  // Measure.
  start = new Date();
  elapsed = 0;
  runs = 0;
  while (elapsed < 2000) {
    action();
    elapsed = new Date() - start;
    runs++;
  }

  var score = runs * 1000.0 / elapsed;
  print(name + ": " + score + " runs/second");
}

benchmark("FieldRead", function(){ new FieldRead().bench(); });
benchmark("FieldWrite", function(){ new FieldWrite().bench(); });
benchmark("SlotRead", function(){ new SlotRead().bench(); });
benchmark("SlotWrite", function(){ new SlotWrite().bench(); });
benchmark("MethodFibonacci", function(){ new MethodFibonacci().bench(); });
benchmark("ClosureFibonacci", function(){ new ClosureFibonacci().bench(); });
benchmark("ClosureDefFibonacci", function(){ new ClosureDefFibonacci().bench(); });
benchmark("NLRImmediate", function(){ new NLRImmediate().bench(); });
benchmark("NLRLoop", function(){ new NLRLoop().bench(); });

benchmark("DeltaBlue", function(){ DeltaBluePlanner.chainTest(100); DeltaBluePlanner.projectionTest(100); });
benchmark("Richards", function(){ runRichards(); });

SplaySetup();
benchmark("Splay", function(){ SplayRun(); });
SplayTearDown();

SplayHarderSetup();
benchmark("SplayHarder", function(){ SplayHarderRun(); });
SplayHarderTearDown();

