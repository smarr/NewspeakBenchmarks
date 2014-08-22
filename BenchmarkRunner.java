
abstract class Benchmark {
  protected String name;

  Benchmark(String name) {
    this.name = name;
  }

  public void setup() { }

  public abstract void run();

  public double measureForAtLeast(long milliseconds) {
   long start, elapsed, runs;
    runs = 0;
    start = System.currentTimeMillis();
    elapsed = 0;
    while (elapsed < milliseconds) {
      run();
      elapsed = System.currentTimeMillis() - start;
      runs++;
    }
    return runs * 1000.0 / elapsed;
  }

  public void report() {
    setup();
    measureForAtLeast(300);  // Warm up.
    double score = measureForAtLeast(2000);
    System.out.format("%s %.3f\n", name, score);
  }
}

class BenchmarkRunner {
  public static void main(String[] args) {
    new DeltaBlue().report();
    new MethodFibonacci().report();
    new Splay().report();
    new SplayHarder().report();
  }
}
