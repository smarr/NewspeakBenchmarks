"using strict";

Object.prototype.extends = function(superConstructor) {
  function O() {}
  O.prototype = superConstructor.prototype;
  this.prototype = new O();
  this.superConstructor = superConstructor;
}

Array.prototype.isEmpty = function() {
  return this.length == 0;
}

Array.prototype.remove = function (elm) {
  var index = 0, skipped = 0;
  for (var i = 0; i < this.length; i++) {
    var value = this[i];
    if (value != elm) {
      this[index] = value;
      index++;
    } else {
      skipped++;
    }
  }
  for (var i = 0; i < skipped; i++)
    this.pop();
}

// Strengths are used to measure the relative importance of constraints. New
// strengths may be inserted in the strength hierarchy without disrupting
// current constraints. Strengths cannot be created outside this class, so
// pointer comparison can be used for value comparison.
function Strength(name, value) {
  this.name = name;
  this.value = value;
}

Strength.prototype.strongerThan = function(other) {
  return this.value < other.value;
}

Strength.prototype.weakerThan = function(other) {
  return this.value > other.value;
}

Strength.prototype.strongest = function(other) {
  return this.strongerThan(other) ? this : other;
}

Strength.prototype.weakest = function(other) {
  return this.weakerThan(other) ? this : other;
}

var required = new Strength('required', 0);
var strongPreferred = new Strength('strongPreferred', 1);
var preferred = new Strength('preferred', 2);
var strongDefault = new Strength('strongDefault', 3);
var normal = new Strength('normal', 4);
var weakDefault = new Strength('weakDefault', 5);
var weakest = new Strength('weakest', 6);

var descendingStrengths = [required, strongPreferred,
    preferred, strongDefault, normal, weakDefault, weakest];

function Direction(name) {
  this.name = name;
}

var forward = new Direction('forward');
var backward = new Direction('backward');

// I represent a constrained variable. In addition to my value, I maintain the
// structure of the constraint graph, the current dataflow graph, and various
// parameters of interest to the DeltaBlue incremental constraint solver.
function Variable(name, value) {
  this.value = value;
  this.constraints = new Array();
  this.determinedBy = null;
  this.mark = 0;
  this.walkStrength = weakest;
  this.stay = true;
  this.name = name;
}

// Add the given constraint to the set of all constraints that refer to me.
Variable.prototype.addConstraint = function(c) {
  this.constraints.push(c);
}
  
// Remove all traces of c from this variable.
Variable.prototype.removeConstraint = function(c) {
  this.constraints.remove(c);
  if (this.determinedBy == c) this.determinedBy = null;
}


// I am an abstract class representing a system-maintainable relationship (or
// "constraint") between a set of variables. I supply a strength instance
// variable; concrete subclasses provide a means of storing the constrained
// variables and other information required to represent a constraint.
function Constraint(strength) {
  this.strength = strength;
}

// Activate this constraint and attempt to satisfy it.
Constraint.prototype.addConstraint = function() {
  this.addToGraph();
  planner.incrementalAdd(this);
}

// Add myself to the constraint graph.
Constraint.prototype.addToGraph = function() {
  this.subclassResponsibility();
}

// Decide if I can be satisfied and record that decision. The output of the
// chosen method must not have the given mark and must have a walkabout
// strength less than that of this constraint.
Constraint.prototype.chooseMethod = function(mark) {
  this.subclassResponsibility();
}

// Deactivate this constraint, remove it from the constraint graph, possibly
// causing other constraints to be satisfied, and destroy it.
Constraint.prototype.destroyConstraint = function() {
  if (this.isSatisfied()) planner.incrementalRemove(this);
  this.removeFromGraph();
}

// Enforce this constraint. Assume that it is satisfied.
Constraint.prototype.execute = function() {
  this.subclassResponsibility();
}

// Assume that I am satisfied. Answer true if all my current inputs are
// known. A variable is known if either a) it is 'stay' (i.e. it is a
// constant at plan execution time), b) it has the given mark (indicating
// that it has been computed by a constraint appearing earlier in the plan),
// or c) it is not determined by any constraint.
Constraint.prototype.inputsKnown = function(mark) {
  this.subclassResponsibility();
}

// Normal constraints are not input constraints. An input constraint is one
// that depends on external state, such as the mouse, the keyboard, a clock, 
// or some arbitrary piece of imperative code.
Constraint.prototype.isInput = function() {
  return false;
}

// Answer true if this constraint is satisfied in the current solution.
Constraint.prototype.isSatisfied = function() {
  this.subclassResponsibility();
}

// Set the mark of all input from the given mark.
Constraint.prototype.markInputs = function() {
  this.subclassResponsibility();
}

// Record the fact that I am unsatisfied.
Constraint.prototype.markUnsatisfied = function() {
  this.subclassResponsibility();
}

// Answer my current output variable. Raise an error if I am not currently
// satisfied.
Constraint.prototype.output = function() {
  this.subclassResponsibility();
}

// Calculate the walkabout strength, the stay flag, and, if it is 'stay', the
// value for the current output of this constraint. Assume this constraint is
// satisfied.
Constraint.prototype.recalculate = function() {
  this.subclassResponsibility();
}

// Remove myself from the constraint graph.
Constraint.prototype.removeFromGraph = function() {
  this.subclassResponsibility();
}

// Attempt to find a way to enforce this constraint. If successful, record
// the solution, perhaps modifying the current dataflow graph. Answer the
// constraint that this constraint overrides, if there is one, or nil, if
// there isn't. Assume: I am not already satisfied.
Constraint.prototype.satisfy = function(mark) {
  this.chooseMethod(mark);
  if (!this.isSatisfied()) {
    if (this.strength == required)
        throw new Exception('Could not satisfy a required constraint');
    return null;
  } 
  // constraint can be satisfied
  // mark inputs to allow cycle detection in addPropagate
  this.markInputs(mark);
  var out = this.output();
  var overridden = out.determinedBy;
  if (overridden != null) overridden.markUnsatisfied();
  out.determinedBy = this;
  if (!planner.addPropagate(this, mark))
      throw new Exception('Cycle encountered');
  out.mark = mark;
  return overridden;
}

// I am an abstract superclass for constraints having a single possible output
// variable.
function UnaryConstraint(v, strength) {
  UnaryConstraint.superConstructor.call(this, strength);
  this.myOutput = v;
  this.satisfied = false;
}
UnaryConstraint.extends(Constraint);

// Add myself to the constraint graph.
UnaryConstraint.prototype.addToGraph = function() {
  this.myOutput.addConstraint(this);
  this.satisfied = false;
}

// Add myself to the constraint graph.
UnaryConstraint.prototype.chooseMethod = function(mark) {
  this.satisfied = (this.myOutput.mark != mark) && 
              this.strength.strongerThan(this.myOutput.walkStrength);
}

UnaryConstraint.prototype.inputsKnown = function(mark) {
  return true;
}

// Answer true if this constraint is satisfied in the current solution.
UnaryConstraint.prototype.isSatisfied = function() {
  return this.satisfied;
}

// I have no inputs.
UnaryConstraint.prototype.markInputs = function(mark) {}

// Record the fact that I am unsatisfied.
UnaryConstraint.prototype.markUnsatisfied = function() {
  this.satisfied = false;
}

UnaryConstraint.prototype.output = function() {
  return this.myOutput;
}

// Calculate the walkabout strength, the stay flag, and, if it is 'stay', the
// value for the current output of this constraint. Assume this constraint
// is satisfied.
UnaryConstraint.prototype.recalculate = function() {
  this.myOutput.walkStrength = this.strength;
  this.myOutput.stay = !this.isInput();
  if (this.myOutput.stay) this.execute(); // Stay optimization
}

// Remove myself from the constraint graph.
UnaryConstraint.prototype.removeFromGraph = function() {
  if (this.myOutput != null) this.myOutput.removeConstraint(this);
  this.satisfied = false;
}

// I am a unary input constraint used to mark a variable that the client wishes
// to change.
function EditConstraint(v, s) {
  EditConstraint.superConstructor.call(this, v, s);
  this.addConstraint();
}
EditConstraint.extends(UnaryConstraint);

// Edit constraints do nothing.
EditConstraint.prototype.execute = function() {}

// I am a unary input constraint used to mark a variable that the client
// wishes to change.
EditConstraint.prototype.isInput = function() {
  return true;
}

// I mark variables that should, with some level of preference, stay the same.
// I have one method with zero inputs and one output, which does nothing.
// Planners may exploit the fact that, if I am satisfied, my output will not
// change during plan execution. This is called "stay optimization".
function StayConstraint(v, s) {
  StayConstraint.superConstructor.call(this, v, s);
  this.addConstraint();
}
StayConstraint.extends(UnaryConstraint);

// Stay constraints do nothing.
StayConstraint.prototype.execute = function() {}

// I am an abstract superclass for constraints having two possible output variables.
function BinaryConstraint(v1, v2, s) {
  BinaryConstraint.superConstructor.call(this, s);
  this.v1 = v1;
  this.v2 = v2;
  this.direction = null;
}
BinaryConstraint.extends(Constraint);

// Add myself to the constraint graph.
BinaryConstraint.prototype.addToGraph = function() {
  this.v1.addConstraint(this);
  this.v2.addConstraint(this);
  this.direction = null;
}

// Decide if I can be satisfied and which way I should flow based on the
// relative strength of the variables I relate, and record that decision.
BinaryConstraint.prototype.chooseMethod = function(mark) {
  if (this.v1.mark == mark) {
    this.direction = (this.v2.mark != mark) && this.strength.strongerThan(this.v2.walkStrength)
      ? forward
      : null; 
    return;
  }
  if (this.v2.mark == mark) {
    this.direction = (this.v1.mark != mark) && this.strength.strongerThan(this.v1.walkStrength)
      ? backward
      : null;
    return;
  } 
  // If we get here, neither variable is marked, so we have a choice.
  if (this.v1.walkStrength.weakerThan(this.v2.walkStrength)) {
    this.direction = this.strength.strongerThan(this.v1.walkStrength) ? backward : null;
  } else {
    this.direction = this.strength.strongerThan(this.v2.walkStrength) ? forward : null;
  }
}

// Answer my current input variable
BinaryConstraint.prototype.input = function() {
  return this.direction == forward ? this.v1 : this.v2;
}

BinaryConstraint.prototype.inputsKnown = function(mark) {
  var i = this.input();
  return (i.mark == mark) || i.stay || (i.determinedBy == null);
}

// Answer true if this constraint is satisfied in the current solution.
BinaryConstraint.prototype.isSatisfied = function() {
  return this.direction != null;
}

// Mark the input variable with the given mark.
BinaryConstraint.prototype.markInputs = function(mark) {
  this.input().mark = mark;
}

// Record the fact that I am unsatisfied.
BinaryConstraint.prototype.markUnsatisfied = function() {
  this.direction = null;
}

// Answer my current output variable.
BinaryConstraint.prototype.output = function() {
  return this.direction == forward ? this.v2 : this.v1;
}

// Calculate the walkabout strength, the stay flag, and, if it is 'stay', the
// value for the current output of this constraint. Assume this constraint is
// satisfied.
BinaryConstraint.prototype.recalculate = function() {
  var i = this.input(), o = this.output();
  o.walkStrength = this.strength.weakest(i.walkStrength);
  o.stay = i.stay;
  if (o.stay) this.execute();
}

// Calculate the walkabout strength, the stay flag, and, if it is 'stay', the
// value for the current output of this constraint. Assume this constraint is
// satisfied.
BinaryConstraint.prototype.removeFromGraph = function() {
  if (this.v1 != null) this.v1.removeConstraint(this);
  if (this.v2 != null) this.v2.removeConstraint(this);
  this.direction = null;
}

// I constrain two variables to have the same value: "v1 = v2".
function EqualityConstraint(v1, v2, s) {
  EqualityConstraint.superConstructor.call(this, v1, v2, s);
  this.addConstraint();
}
EqualityConstraint.extends(BinaryConstraint);

// Enforce this constraint. Assume that it is satisfied.
EqualityConstraint.prototype.execute = function() {
  this.output().value = this.input().value;
}

// I relate two variables by the linear scaling relationship: "v2 = (v1 *
// scale) + offset". Either v1 or v2 may be changed to maintain this
// relationship but the scale factor and offset are considered read-only.
function ScaleConstraint(src, scale, offset, dst, s) {
  ScaleConstraint.superConstructor.call(this, src, dst, s);
  this.scale = scale;  // scale factor input variable
  this.offset = offset;  // offset input variable
  this.addConstraint();
}
ScaleConstraint.extends(BinaryConstraint);

// Add myself to the constraint graph.
ScaleConstraint.prototype.addToGraph = function() {
  ScaleConstraint.superConstructor.prototype.addToGraph.call(this);
  this.scale.addConstraint(this);
  this.offset.addConstraint(this);
}

// Enforce this constraint. Assume that it is satisfied.
ScaleConstraint.prototype.execute = function() {
  if (this.direction == forward) {
    this.v2.value = this.v1.value * this.scale.value + this.offset.value;
  } else {
    this.v1.value = (this.v2.value - this.offset.value) / this.scale.value;
  }
}

// Mark the inputs from the given mark.
ScaleConstraint.prototype.markInputs = function(mark) {
  ScaleConstraint.superConstructor.prototype.markInputs.call(this, mark);
  this.scale.mark = mark;
  this.offset.mark = mark;
}

// Calculate the walkabout strength, the stay flag, and, if it is 'stay', the
// value for the current output of this constraint. Assume this constraint is
// satisfied.
ScaleConstraint.prototype.recalculate = function() {
  var i = this.input(), o = this.output();
  o.walkStrength = this.strength.weakest(i.walkStrength);
  o.stay = i.stay && this.scale.stay && this.offset.stay;
  if (o.stay) this.execute(); // stay optimization
}

// Remove myself from the constraint graph.
ScaleConstraint.prototype.removeFromGraph = function() {
  ScaleConstraint.superConstructor.prototype.removeFromGraph.call(this);
  if (this.scale != null) this.scale.removeConstraint(this);
  if (this.offset != null) this.offset.removeConstraint(this);
}

// A Plan is an ordered list of constraints to be executed in sequence to
// resatisfy all currently satisfiable constraints in the face of one or more
// changing inputs.
function Plan() {
  this.constraints = new Array();
}

Plan.prototype.addConstraint = function(c) {
  this.constraints.push(c);
}

// Execute my constraints in order.
Plan.prototype.execute = function() {
  this.constraints.forEach(function(c) {
    c.execute();
  });
}

// I embody the DeltaBlue algorithm described in:
// ''The DeltaBlue Algorithm: An Incremental Constraint Hierarchy Solver''
// by Bjorn N. Freeman-Benson and John Maloney.
// See January 1990 Communications of the ACM
// or University of Washington TR 89-08-06 for further details.
function Planner() {
  this.currentMark = 0;
}

Planner.prototype.addConstraintsConsumingTo = function(v, list) {
  var determining = v.determinedBy;
  v.constraints.forEach(function(c) {
    if (c != determining && c.isSatisfied()) list.push(c);
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
Planner.prototype.addPropagate = function(c, mark) {
  var todo = new Array();
  todo.push(c);
  while (!todo.isEmpty()) {
    var d = todo.pop();
    if (d.output().mark == mark) {
      this.incrementalRemove(c);
      return false;
    }
    d.recalculate();
    this.addConstraintsConsumingTo(d.output(), todo);
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
Planner.prototype.chainTest = function(n) {
  var prev, first, last;
  for (var i = 1; i <= n; i++) { 
    var name = 'v$i';	
    var v = new Variable(name, 0);
    if (prev != null) new EqualityConstraint(prev, v, required);
    if (i == 1) first = v;
    if (i == n) last = v;
    prev = v;
  }

  new StayConstraint(last, strongDefault);
  var editC = new EditConstraint(first, preferred);
  var editV = new Array();
  editV.push(editC);
  var plan = this.extractPlanFromConstraints(editV);
  for (var i = 1; i <= n; i++) {
    first.value = i;
    plan.execute();
    if (last.value != i) throw new Exception('Chain test failed!');
  }
  editC.destroyConstraint();
}

// Extract a plan for resatisfaction starting from the outputs of the given
// constraints, usually a set of input constraints.
Planner.prototype.extractPlanFromConstraints = function(constraints) {
  var sources = new Array();
  constraints.forEach(function(c) {
    if (c.isInput() && c.isSatisfied()) sources.push(c);
  });
  return this.makePlan(sources);
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
Planner.prototype.incrementalAdd = function(c) {
  var mark = this.newMark();
  var overridden = c.satisfy(mark);
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
Planner.prototype.incrementalRemove = function(c) {
  var self = this;
  var out = c.output();
  c.markUnsatisfied();
  c.removeFromGraph();
  var unsatisfied = this.removePropagateFrom(out);
  descendingStrengths.forEach(function(strength) { 
    unsatisfied.forEach(function(u) {
      if (u.strength == strength) self.incrementalAdd(u);
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
Planner.prototype.makePlan = function(sources) {
  var mark = this.newMark();
  var plan = new Plan();
  var todo = sources;
  while (!todo.isEmpty()) {
    var c = todo.pop();
    if (c.output().mark != mark && c.inputsKnown(mark)) {
      // not in plan already and eligible for inclusion
      plan.addConstraint(c);
      c.output().mark = mark;
      this.addConstraintsConsumingTo(c.output(), todo);
    }
  }
  return plan;
}

// Select a previously unused mark value.
Planner.prototype.newMark = function() {
  this.currentMark = this.currentMark + 1;
  return this.currentMark;
}

// This test constructs a two sets of variables related to each other by a
// simple linear transformation (scale and offset). The time is measured to
// change a variable on either side of the mapping and to change the scale
// and offset factors.
Planner.prototype.projectionTest = function(n) {
  var src, dst;
  var scale = new Variable('scale', 10);
  var offset = new Variable('offset', 1000);
  var dests = new Array();
  for (var i = 0; i < n; i++) {
    src = new Variable('src$i', i);
    dst = new Variable('dst$i', i);
    dests.push(dst);
    new StayConstraint(src, normal);
    new ScaleConstraint(src, scale, offset, dst, required);
  }

  this.setValue(src, 17);
  if (dst.value != 1170)
      throw new Exception('Projection test 1 failed!');
 
  this.setValue(dst, 1050);
  if (src.value != 5)
      throw new Exception('Projection test 2 failed!');
	
  this.setValue(scale, 5);
  for (var i = 0; i < n-1; i++) {
    if (dests[i].value != (i * 5 + 1000))
       throw new Exception('Projection test 3 failed!');
  }

  this.setValue(offset, 2000);
  for (var i = 0; i < n-1; i++) {
    if (dests[i].value != (i * 5 + 2000))
        throw new Exception('Projection test 4 failed!');
  }
}

// The given variable has changed. Propagate new values downstream.
Planner.prototype.propagateFrom = function(v) {
  var todo = new Array();
  this.addConstraintsConsumingTo(v, todo);
  while (!todo.isEmpty()) {
    var c = todo.pop();
    c.execute();
    this.addConstraintsConsumingTo(c.output(), todo);
  }
}

// Update the walkabout strengths and stay flags of all variables downstream
// of the given constraint. Answer a collection of unsatisfied constraints
// sorted in order of decreasing strength.
Planner.prototype.removePropagateFrom = function(out) {
  out.determinedBy = null;
  out.walkStrength = weakest;
  out.stay = true;
  var unsatisfied = new Array();
  var todo = new Array();
  todo.push(out);
  while (!todo.isEmpty()) {
    var v = todo.pop();
    v.constraints.forEach(function(c) {
      if (!c.isSatisfied()) unsatisfied.push(c);
    });
    var determining = v.determinedBy;
    v.constraints.forEach(function(nextC) {
      if (nextC != determining && nextC.isSatisfied()) {
        nextC.recalculate();
        todo.push(nextC.output());
      }
    });
  }
  return unsatisfied;
}

Planner.prototype.setValue = function(v, newValue) {
  var editC = new EditConstraint(v, preferred);
  var editV = new Array();
  editV.push(editC);
  var plan = this.extractPlanFromConstraints(editV);
  for (var i = 0; i < 10; i++) {
     v.value = newValue;
     plan.execute();
  }
  editC.destroyConstraint();
}

var planner = new Planner();
//planner.chainTest(100);
//planner.projectionTest(100);

global.DeltaBluePlanner = planner;
