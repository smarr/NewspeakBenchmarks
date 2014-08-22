
// Strengths are used to measure the relative importance of constraints. New
// strengths may be inserted in the strength hierarchy without disrupting
// current constraints. Strengths cannot be created outside this class, so
// pointer comparison can be used for value comparison.
class Strength {
  String name;
  int value;

  Strength(this.name, this.value);

  bool strongerThan(Strength other) {
    return this.value < other.value;
  }

  bool weakerThan(Strength other) {
    return this.value > other.value;
  }

  Strength strongest(Strength other) {
    return this.strongerThan(other) ? this : other;
  }

  Strength weakest(Strength other) {
    return this.weakerThan(other) ? this : other;
  }
}

final Strength required = new Strength('required', 0);
final Strength strongPreferred = new Strength('strongPreferred', 1);
final Strength preferred = new Strength('preferred', 2);
final Strength strongDefault = new Strength('strongDefault', 3);
final Strength normal = new Strength('normal', 4);
final Strength weakDefault = new Strength('weakDefault', 5);
final Strength weakest = new Strength('weakest', 6);

final List<Strength> descendingStrengths = [required, strongPreferred,
    preferred, strongDefault, normal, weakDefault, weakest];

class Direction {
  String name;
  Direction(this.name);
}

final Direction forward = new Direction('forward');
final Direction backward = new Direction('backward');

// I represent a constrained variable. In addition to my value, I maintain the
// structure of the constraint graph, the current dataflow graph, and various
// parameters of interest to the DeltaBlue incremental constraint solver.
class Variable {
  int value;
  List<Constraint> constraints = new List<Constraint>(); // hint = 2
  Constraint determinedBy;
  int mark = 0;
  Strength walkStrength = weakest;
  bool stay = true;
  String name;
  Variable(this.name, this.value);

  // Add the given constraint to the set of all constraints that refer to me.
  void addConstraint(Constraint c) {
    constraints.add(c);
  }

  // Remove all traces of c from this variable.
  void removeConstraint(Constraint c) {
    constraints.remove(c);
    if (determinedBy == c) determinedBy = null;
  }
}

// I am an abstract class representing a system-maintainable relationship (or
// "constraint") between a set of variables. I supply a strength instance
// variable; concrete subclasses provide a means of storing the constrained
// variables and other information required to represent a constraint.
abstract class Constraint {
  Strength strength;
  Constraint(this.strength);

  // Activate this constraint and attempt to satisfy it.
  void addConstraint() {
    addToGraph();
    planner.incrementalAdd(this);
  }

  // Add myself to the constraint graph.
  void addToGraph();

  // Decide if I can be satisfied and record that decision. The output of the
  // chosen method must not have the given mark and must have a walkabout
  // strength less than that of this constraint.
  void chooseMethod(int mark);

  // Deactivate this constraint, remove it from the constraint graph, possibly
  // causing other constraints to be satisfied, and destroy it.
  void destroyConstraint() {
    if (isSatisfied()) planner.incrementalRemove(this);
    removeFromGraph();
  }

  // Enforce this constraint. Assume that it is satisfied.
  void execute();

  // Assume that I am satisfied. Answer true if all my current inputs are
  // known. A variable is known if either a) it is 'stay' (i.e. it is a
  // constant at plan execution time), b) it has the given mark (indicating
  // that it has been computed by a constraint appearing earlier in the plan),
  // or c) it is not determined by any constraint.
  bool inputsKnown(int mark);

  // Normal constraints are not input constraints. An input constraint is one
  // that depends on external state, such as the mouse, the keyboard, a clock,
  // or some arbitrary piece of imperative code.
  bool isInput() {
    return false;
  }

  // Answer true if this constraint is satisfied in the current solution.
  bool isSatisfied();

  // Set the mark of all input from the given mark.
  void markInputs(int mark);

  // Record the fact that I am unsatisfied.
  void markUnsatisfied();

  // Answer my current output variable. Raise an error if I am not currently
  // satisfied.
  Variable get output;

  // Calculate the walkabout strength, the stay flag, and, if it is 'stay', the
  // value for the current output of this constraint. Assume this constraint is
  // satisfied.
  void recalculate();

  // Remove myself from the constraint graph.
  void removeFromGraph();

  // Attempt to find a way to enforce this constraint. If successful, record
  // the solution, perhaps modifying the current dataflow graph. Answer the
  // constraint that this constraint overrides, if there is one, or nil, if
  // there isn't. Assume: I am not already satisfied.
  Constraint satisfy(int mark) {
    chooseMethod(mark);
    if (!isSatisfied()) {
      if (strength == required)
          throw new Exception('Could not satisfy a required constraint');
      return null;
    }
    // constraint can be satisfied
    // mark inputs to allow cycle detection in addPropagate
    markInputs(mark);
    Variable out = output;
    Constraint overridden = out.determinedBy;
    if (overridden != null) overridden.markUnsatisfied();
    out.determinedBy = this;
    if (!planner.addPropagate(this, mark))
        throw new Exception('Cycle encountered');
    out.mark = mark;
    return overridden;
  }
}

// I am an abstract superclass for constraints having a single possible output
// variable.
abstract class UnaryConstraint extends Constraint {
  Variable output;
  bool satisfied = false;
  UnaryConstraint(this.output, strength) : super(strength);

  // Add myself to the constraint graph.
  void addToGraph() {
    output.addConstraint(this);
    satisfied = false;
  }

  // Add myself to the constraint graph.
  void chooseMethod(int mark) {
    satisfied = (output.mark != mark) &&
                strength.strongerThan(output.walkStrength);
  }

  bool inputsKnown(int mark) {
    return true;
  }

  // Answer true if this constraint is satisfied in the current solution.
  bool isSatisfied() {
    return satisfied;
  }

  // I have no inputs.
  void markInputs(int mark) {}

  // Record the fact that I am unsatisfied.
  void markUnsatisfied() {
    satisfied = false;
  }

  // Calculate the walkabout strength, the stay flag, and, if it is 'stay', the
  // value for the current output of this constraint. Assume this constraint
  // is satisfied.
  void recalculate() {
    output.walkStrength = strength;
    output.stay = !isInput();
    if (output.stay) execute(); // Stay optimization
  }

  // Remove myself from the constraint graph.
  void removeFromGraph() {
    if (output != null) output.removeConstraint(this);
    satisfied = false;
  }
}

// I am a unary input constraint used to mark a variable that the client wishes
// to change.
class EditConstraint extends UnaryConstraint {
  EditConstraint(Variable v, Strength s) : super(v, s) {
    addConstraint();
  }

  // Edit constraints do nothing.
  void execute() {}

  // I am a unary input constraint used to mark a variable that the client
  // wishes to change.
  bool isInput() {
    return true;
  }
}

// I mark variables that should, with some level of preference, stay the same.
// I have one method with zero inputs and one output, which does nothing.
// Planners may exploit the fact that, if I am satisfied, my output will not
// change during plan execution. This is called "stay optimization".
class StayConstraint extends UnaryConstraint {
  StayConstraint(Variable v, Strength s) : super(v, s) {
    addConstraint();
  }

  // Stay constraints do nothing.
  void execute() {}
}

// I am an abstract superclass for constraints having two possible output variables.
abstract class BinaryConstraint extends Constraint {
  Variable v1;
  Variable v2;
  Direction direction;
  BinaryConstraint(this.v1, this.v2, Strength s) : super(s) {}

  // Add myself to the constraint graph.
  void addToGraph() {
    v1.addConstraint(this);
    v2.addConstraint(this);
    direction = null;
  }

  // Decide if I can be satisfied and which way I should flow based on the
  // relative strength of the variables I relate, and record that decision.
  void chooseMethod(int mark) {
    if (v1.mark == mark) {
      direction = (v2.mark != mark) && strength.strongerThan(v2.walkStrength)
	? forward
        : null;
      return;
    }
    if (v2.mark == mark) {
      direction = (v1.mark != mark) && strength.strongerThan(v1.walkStrength)
        ? backward
        : null;
      return;
    }
    // If we get here, neither variable is marked, so we have a choice.
    if (v1.walkStrength.weakerThan(v2.walkStrength)) {
      direction = strength.strongerThan(v1.walkStrength) ? backward : null;
    } else {
      direction = strength.strongerThan(v2.walkStrength) ? forward : null;
    }
  }

  // Answer my current input variable
  Variable get input {
    return direction == forward ? v1 : v2;
  }

  bool inputsKnown(int mark) {
    Variable i = input;
    return (i.mark == mark) || i.stay || (i.determinedBy == null);
  }

  // Answer true if this constraint is satisfied in the current solution.
  bool isSatisfied() {
    return direction != null;
  }

  // Mark the input variable with the given mark.
  void markInputs(int mark) {
    input.mark = mark;
  }

  // Record the fact that I am unsatisfied.
  void markUnsatisfied() {
    direction = null;
  }

  // Answer my current output variable.
  Variable get output {
    return direction == forward ? v2 : v1;
  }

  // Calculate the walkabout strength, the stay flag, and, if it is 'stay', the
  // value for the current output of this constraint. Assume this constraint is
  // satisfied.
  void recalculate() {
    Variable i = input, o = output;
    o.walkStrength = strength.weakest(i.walkStrength);
    o.stay = i.stay;
    if (o.stay) execute();
  }

  // Calculate the walkabout strength, the stay flag, and, if it is 'stay', the
  // value for the current output of this constraint. Assume this constraint is
  // satisfied.
  void removeFromGraph() {
    if (v1 != null) v1.removeConstraint(this);
    if (v2 != null) v2.removeConstraint(this);
    direction = null;
  }
}

// I constrain two variables to have the same value: "v1 = v2".
class EqualityConstraint extends BinaryConstraint {
  EqualityConstraint(Variable v1, Variable v2, Strength s) : super(v1, v2, s) {
    addConstraint();
  }

  // Enforce this constraint. Assume that it is satisfied.
  void execute() {
    output.value = input.value;
  }
}

// I relate two variables by the linear scaling relationship: "v2 = (v1 *
// scale) + offset". Either v1 or v2 may be changed to maintain this
// relationship but the scale factor and offset are considered read-only.
class ScaleConstraint extends BinaryConstraint {
  Variable scale;  // scale factor input variable
  Variable offset;  // offset input variable
  ScaleConstraint(src, this.scale, this.offset, dest, s) : super(src, dest, s) {
    addConstraint();
  }

  // Add myself to the constraint graph.
  void addToGraph() {
    super.addToGraph();
    scale.addConstraint(this);
    offset.addConstraint(this);
  }

  // Enforce this constraint. Assume that it is satisfied.
  void execute() {
    if (direction == forward) {
      v2.value = v1.value * scale.value + offset.value;
    } else {
      v1.value = (v2.value - offset.value) ~/ scale.value;
    }
  }

  // Mark the inputs from the given mark.
  void markInputs(int mark) {
    super.markInputs(mark);
    scale.mark = mark;
    offset.mark = mark;
  }

  // Calculate the walkabout strength, the stay flag, and, if it is 'stay', the
  // value for the current output of this constraint. Assume this constraint is
  // satisfied.
  void recalculate() {
    Variable i = input, o = output;
    o.walkStrength = strength.weakest(i.walkStrength);
    o.stay = i.stay && scale.stay && offset.stay;
    if (o.stay) execute(); // stay optimization
  }

  // Remove myself from the constraint graph.
  void removeFromGraph() {
    super.removeFromGraph();
    if (scale != null) scale.removeConstraint(this);
    if (offset != null) offset.removeConstraint(this);
  }
}

// A Plan is an ordered list of constraints to be executed in sequence to
// resatisfy all currently satisfiable constraints in the face of one or more
// changing inputs.
class Plan {
  List<Constraint> constraints = new List<Constraint>();

  Plan();

  void addConstraint(Constraint c) {
    constraints.add(c);
  }

  // Execute my constraints in order.
  void execute() {
    constraints.forEach((c){
      c.execute();
    });
  }
}

// I embody the DeltaBlue algorithm described in:
// ''The DeltaBlue Algorithm: An Incremental Constraint Hierarchy Solver''
// by Bjorn N. Freeman-Benson and John Maloney.
// See January 1990 Communications of the ACM
// or University of Washington TR 89-08-06 for further details.
class Planner {
  int currentMark = 0;

  void addConstraintsConsumingTo(Variable v, List<Constraint> list) {
    Constraint determining = v.determinedBy;
    v.constraints.forEach((c) {
      if (c != determining && c.isSatisfied()) list.add(c);
    });
  }

  // Recompute the walkabout strengths and stay flags of all variables
  // downstream of the given constraint and recompute the actual values of all
  // variables whose stay flag is true. If a cycle is detected, remove the
  // given constraint and answer false. Otherwise, answer true.
  // Details: Cycles are detected when a marked variable is encountered
  // downstream of the given constraint. The sender is assumed to have marked
  // the inputs of the given constraint with the given mark. Thus, encountering
  // a marked node downstream of the output constraint means that there is a
  // path from the constraint's output to one of its inputs.
  bool addPropagate(Constraint c, int mark) {
    List<Constraint> todo = new List<Constraint>();
    todo.add(c);
    while (!todo.isEmpty) {
      Constraint d = todo.removeLast();
      if (d.output.mark == mark) {
        incrementalRemove(c);
        return false;
      }
      d.recalculate();
      addConstraintsConsumingTo(d.output, todo);
    }
    return true;
  }

  // This is the standard DeltaBlue benchmark. A long chain of equality
  // constraints is constructed with a stay constraint on one end. An edit
  // constraint is then added to the opposite end and the time is measured for
  // adding and removing this constraint, and extracting and executing a
  // constraint satisfaction plan. There are two cases. In case 1, the added
  // constraint is stronger than the stay constraint and values must propagate
  // down the entire length of the chain. In case 2, the added constraint is
  // weaker than the stay constraint so it cannot be accommodated. The cost in
  // this case is, of course, very low. Typical situations lie somewhere
  // between these two extremes.
  void chainTest(int n) {
    Variable prev, first, last;
    for (int i = 1; i <= n; i++) {
      var name = 'v$i';
      var v = new Variable(name, 0);
      if (prev != null) new EqualityConstraint(prev, v, required);
      if (i == 1) first = v;
      if (i == n) last = v;
      prev = v;
    }

    new StayConstraint(last, strongDefault);
    Constraint editC = new EditConstraint(first, preferred);
    List<Constraint> editV = new List<Constraint>();
    editV.add(editC);
    Plan plan = extractPlanFromConstraints(editV);
    for (int i = 1; i <= n; i++) {
      first.value = i;
      plan.execute();
      if (last.value != i) throw new Exception('Chain test failed!');
    }
    editC.destroyConstraint();
  }

  // Extract a plan for resatisfaction starting from the outputs of the given
  // constraints, usually a set of input constraints.
  Plan extractPlanFromConstraints(List<Constraint> constraints) {
    List<Constraint> sources = new List<Constraint>();
    constraints.forEach((c) {
      if (c.isInput() && c.isSatisfied()) sources.add(c);
    });
    return makePlan(sources);
  }

  // Attempt to satisfy the given constraint and, if successful, incrementally
  // update the dataflow graph.  Details: If satisfying the constraint is
  // successful, it may override a weaker constraint on its output. The
  // algorithm attempts to resatisfy that constraint using some other method.
  // This process is repeated until either a) it reaches a variable that was
  // not previously determined by any constraint or b) it reaches a constraint
  // that is too weak to be satisfied using any of its methods. The variables
  // of constraints that have been processed are marked with a unique mark
  // value so that we know where we've been. This allows the algorithm to avoid
  // getting into an infinite loop even if the constraint graph has an
  // inadvertent cycle.
  void incrementalAdd(Constraint c) {
    int mark = newMark();
    Constraint overridden = c.satisfy(mark);
    while (overridden != null) {
      overridden = overridden.satisfy(mark);
    }
  }

  // Entry point for retracting a constraint. Remove the given constraint and
  // incrementally update the dataflow graph.
  // Details: Retracting the given constraint may allow some currently
  // unsatisfiable downstream constraint to be satisfied. We therefore collect
  // a list of unsatisfied downstream constraints and attempt to satisfy each
  // one in turn. This list is traversed by constraint strength, strongest
  // first, as a heuristic for avoiding unnecessarily adding and then
  // overriding weak constraints.
  // Assume: c is satisfied.
  void incrementalRemove(Constraint c) {
    Variable out = c.output;
    c.markUnsatisfied();
    c.removeFromGraph();
    List<Constraint> unsatisfied = removePropagateFrom(out);
    descendingStrengths.forEach((strength) {
      unsatisfied.forEach((u) {
        if (u.strength == strength) incrementalAdd(u);
      });
    });
  }

  // Extract a plan for resatisfaction starting from the given source
  // constraints, usually a set of input constraints. This method assumes that
  // stay optimization is desired; the plan will contain only constraints whose
  // output variables are not stay. Constraints that do no computation, such as
  // stay and edit constraints, are not included in the plan.
  // Details: The outputs of a constraint are marked when it is added to the
  // plan under construction. A constraint may be appended to the plan when all
  // its input variables are known. A variable is known if either a) the
  // variable is marked (indicating that has been computed by a constraint
  // appearing earlier in the plan), b) the variable is 'stay' (i.e. it is a
  // constant at plan execution time), or c) the variable is not determined by
  // any constraint. The last provision is for past states of history
  // variables, which are not stay but which are also not computed by any
  // constraint.
  // Assume: sources are all satisfied.
  Plan makePlan(List<Constraint> sources) {
    int mark = newMark();
    Plan plan = new Plan();
    List<Constraint> todo = sources;
    while (!todo.isEmpty) {
      Constraint c = todo.removeLast();
      if (c.output.mark != mark && c.inputsKnown(mark)) {
        // not in plan already and eligible for inclusion
        plan.addConstraint(c);
        c.output.mark = mark;
        addConstraintsConsumingTo(c.output, todo);
      }
    }
    return plan;
  }

  // Select a previously unused mark value.
  int newMark() {
    currentMark = currentMark + 1;
    return currentMark;
  }

  // This test constructs a two sets of variables related to each other by a
  // simple linear transformation (scale and offset). The time is measured to
  // change a variable on either side of the mapping and to change the scale
  // and offset factors.
  void projectionTest(int n) {
    Variable src, dst;
    Variable scale = new Variable('scale', 10);
    Variable offset = new Variable('offset', 1000);
    List<Variable> dests = new List<Variable>();
    for (var i = 0; i < n; i++) {
      src = new Variable('src$i', i);
      dst = new Variable('dst$i', i);
      dests.add(dst);
      new StayConstraint(src, normal);
      new ScaleConstraint(src, scale, offset, dst, required);
    }

    setValue(src, 17);
    if (dst.value != 1170)
        throw new Exception('Projection test 1 failed!');

    setValue(dst, 1050);
    if (src.value != 5)
        throw new Exception('Projection test 2 failed!');

    setValue(scale, 5);
    for (int i = 0; i < n-1; i++) {
      if (dests[i].value != (i * 5 + 1000))
          throw new Exception('Projection test 3 failed!');
    }

    setValue(offset, 2000);
    for (int i = 0; i < n-1; i++) {
      if (dests[i].value != (i * 5 + 2000))
          throw new Exception('Projection test 4 failed!');
    }
  }

  // The given variable has changed. Propagate new values downstream.
  void propagateFrom(Variable v) {
    List<Constraint> todo = new List<Constraint>().
    addConstraintsConsumingTo(v, todo);
    while (!todo.isEmpty) {
      Constraint c = todo.removeLast();
      c.execute();
      addConstraintsConsumingTo(c.output, todo);
    }
  }

  // Update the walkabout strengths and stay flags of all variables downstream
  // of the given constraint. Answer a collection of unsatisfied constraints
  // sorted in order of decreasing strength.
  List<Constraint> removePropagateFrom(Variable out) {
    out.determinedBy = null;
    out.walkStrength = weakest;
    out.stay = true;
    List<Constraint> unsatisfied = new List<Constraint>();
    List<Variable> todo = new List<Variable>();
    todo.add(out);
    while (!todo.isEmpty) {
      Variable v = todo.removeLast();
      v.constraints.forEach((c) {
        if (!c.isSatisfied()) unsatisfied.add(c);
      });
      Constraint determining = v.determinedBy;
      v.constraints.forEach((nextC) {
        if (nextC != determining && nextC.isSatisfied()) {
          nextC.recalculate();
          todo.add(nextC.output);
        }
      });
    }
    return unsatisfied;
  }

  void setValue(Variable v, int newValue) {
    Constraint editC = new EditConstraint(v, preferred);
    List<Constraint> editV = new List<Constraint>();
    editV.add(editC);
    Plan plan = extractPlanFromConstraints(editV);
    for (int i = 0; i < 10; i++) {
       v.value = newValue;
       plan.execute();
    }
    editC.destroyConstraint();
  }
}

var planner = new Planner();
main() {
  planner.chainTest(100);
  planner.projectionTest(100);
}
