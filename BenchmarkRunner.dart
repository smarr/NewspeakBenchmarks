
import "FieldRead.dart";
import "FieldWrite.dart";
import "SlotRead.dart";
import "SlotWrite.dart";
import "MethodFibonacci.dart";
import "ClosureFibonacci.dart";
import "ClosureDefFibonacci.dart";
import "NLRImmediate.dart";
import "NLRLoop.dart";
import "Splay.dart";
import "SplayHarder.dart";
import "DeltaBlue.dart";
import "Richards.dart";
import "ParserCombinators.dart";

benchmark(name, action) {
  var stopwatch, elapsed, runs;

  // Warm up.
  stopwatch = new Stopwatch();
  stopwatch.start();
  elapsed = 0;
  while (elapsed < 300) {
    action();
    elapsed = stopwatch.elapsedMilliseconds;
  }
  stopwatch.stop();

  // Measure.
  stopwatch = new Stopwatch();
  stopwatch.start();
  elapsed = 0;
  runs = 0;
  while (elapsed < 2000) {
    action();
    elapsed = stopwatch.elapsedMilliseconds;
    runs++;
  }
  stopwatch.stop();

  var score = runs * 1000.0 / elapsed;
  print("$name: ${score.toStringAsFixed(1)} runs/second");
}

main() {
  benchmark("FieldRead", () => new FieldRead().bench());
  benchmark("FieldWrite", () => new FieldWrite().bench());
  benchmark("SlotRead", () => new SlotRead().bench());
  benchmark("SlotWrite", () => new SlotWrite().bench());
  benchmark("MethodFibonacci", () => new MethodFibonacci().bench());
  benchmark("ClosureFibonacci", () => new ClosureFibonacci().bench());
  benchmark("ClosureDefFibonacci", () => new ClosureDefFibonacci().bench());
  benchmark("NLRImmediate", () => new NLRImmediate().bench());
  benchmark("NLRLoop", () => new NLRLoop().bench());

  benchmark("DeltaBlue", () { planner.chainTest(100); planner.projectionTest(100); });

  benchmark("Richards", () { new Richards().run(); });


  Splay.mysetup();
  benchmark("Splay", () => new Splay().exercise());
  Splay.tearDown();

  SplayHarder.mysetup();
  benchmark("SplayHarder", () => new SplayHarder().exercise());
  SplayHarder.tearDown();

  var parser = new SimpleExpressionGrammar().start.compress();
  var theExpression = randomExpression(20);
  assert (theExpression.length == 41137);
  benchmark("ParserCombinators", () => parser.parseWithContext(new ParserContext(theExpression)));
}
