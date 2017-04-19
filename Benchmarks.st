Smalltalk
package 'Benchmarks' = (

'Benchmarks-Microbenchmarks'
class Benchmark = Object (
""
| "instance variables"  |
| "class pool variables"  |
| "shared pool variables"  |
'as yet unclassified'
measureForAtLeast: milliseconds = (
	| runs start elapsed |
	runs := 0. Smalltalk garbageCollect.
	start := Time millisecondClockValue.
	
	[self run.
	runs := runs + 1.
	elapsed :=Time millisecondClockValue - start.
	elapsed < milliseconds] whileTrue.
	
	^(runs * 1000.0 / elapsed) asFloat
)
report = (
	| score |
	self setup.
	self measureForAtLeast: 300. "Warm up"
	Smalltalk garbageCollect. 
	score := self measureForAtLeast: 2000.
	Transcript cr; show: self class name; space; show: (score printShowingDecimalPlaces: 1).
	^score
)
setup = (
)) : (
| "class instance variables"  |
'as yet unclassified'
report = (
	^self new report
)
reportAll = (
	^(self subclasses sortBy: [:a :b | a name < b name]) collect:
		[:benchmarkClass | benchmarkClass name -> benchmarkClass report]
))

'Benchmarks-DeltaBlue'
class DBBinaryConstraint = DBConstraint (
"I am an abstract superclass for constraints having two possible output variables."
| "instance variables" v1 v2 direction  |
| "class pool variables"  |
| "shared pool variables"  |
'as yet unclassified'
addToGraph = (
	"Add myself to the constraint graph."
	v1 addConstraint: self.
	v2 addConstraint: self.
	direction := nil.
)
chooseMethod: mark = (
	"Decide if I can be satisfied and which way I should flow based on the relative strength of the variables I relate, and record that decision."
	v1 mark == mark ifTrue:
		[(v2 mark ~= mark and: [strength strongerThan: v2 walkStrength]) 
			ifTrue: [direction:= DBForward] 
			ifFalse: [direction:= nil].
		^self].
	v2 mark == mark ifTrue:
		[(v1 mark ~= mark and: [strength strongerThan: v1 walkStrength]) 
			ifTrue: [direction:= DBBackward]
			ifFalse: [direction:= nil].
		^self].

	"If we get here, neither variable is marked, so we have a choice."
    	(v1 walkStrength weakerThan: v2 walkStrength)
		ifTrue: 
			[direction:= (strength strongerThan: v1 walkStrength)
				ifTrue: [DBBackward]
				ifFalse: [nil]]
		ifFalse:
			[direction:= (strength strongerThan: v2 walkStrength)
				ifTrue: [DBForward]
				ifFalse: ["nil" DBBackward]].
)
input = (
	"Answer my current input variable"
	^direction == DBForward ifTrue: [v1] ifFalse: [v2]
)
inputsKnown: mark = (
	| in |
	in := self input.
	^in mark == mark or: [in stay or: [in determinedBy isNil]]
)
isSatisfied = (
	"Answer true if this constraint is satisfied in the current solution."
	^direction notNil
)
markInputs: mark = (
	"Mark the input variable with the given mark."
	self input mark: mark
)
markUnsatisfied = (
	"Record the fact that I am unsatisfied."
	direction := nil.
)
output = (
	"Answer my current output variable."
	^direction == DBForward ifTrue: [v2] ifFalse: [v1]
)
recalculate = (
	"Calculate the walkabout strength, the stay flag, and, if it is 'stay', the value for the current output of this constraint. Assume this constraint is satisfied."
	| in out |
	in := self input. out := self output.
	out walkStrength: (strength weakest: in walkStrength).
	out stay: in stay.
	out stay ifTrue: [self execute].
)
removeFromGraph = (
	"Remove myself from the constraint graph."
	v1 isNil ifFalse: [v1 removeConstraint: self].
	v2 isNil ifFalse: [v2 removeConstraint: self].
	direction := nil.
)
var: v1p var: v2p strength: s = (
	super strength: s.
	v1 := v1p.
	v2 := v2p.
)) : (
| "class instance variables"  |
'as yet unclassified'
var: v1 var: v2 strength: s = (
	^self new var: v1 var: v2 strength: s 
))

'Benchmarks-DeltaBlue'
class DBConstraint = Object (
"I am an abstract class representing a system-maintainable relationship (or ''constraint'') between a set of variables. I supply a strength instance variable; concrete subclasses provide a means of storing the constrained variables and other information required to represent a constraint."
| "instance variables" strength  |
| "class pool variables"  |
| "shared pool variables"  |
'as yet unclassified'
addConstraint = (
	"Activate this constraint and attempt to satisfy it."
	self addToGraph.
	DBThePlanner incrementalAdd: self. 
)
addToGraph = (
	"Add myself to the constraint graph."
	self subclassResponsibility
)
chooseMethod: mark = (
	"Decide if I can be satisfied and record that decision. The output of the chosen method must not have the given mark and must have a walkabout strength less than that of this constraint."
	self subclassResponsibility
)
execute = (
	"Enforce this constraint. Assume that it is satisfied."
	self subclassResponsibility
)
inputsKnown: mark = (
	"Assume that I am satisfied. Answer true if all my current inputs are known. A variable is known if either a) it is 'stay' (i.e. it is a constant at plan execution time), b) it has the given mark (indicating that it has been computed by a constraint appearing earlier in the plan), or c) it is not determined by any constraint."
	self subclassResponsibility
)
isInput = (
	"Normal constraints are not input constraints. An input constraint is one that depends on external state, such as the mouse, the keyboard, a clock, or some arbitrary piece of imperative code."
	^false
)
isSatisfied = (
	"Answer true if this constraint is satisfied in the current solution."
	self subclassResponsibility
)
markInputs: mark = (
	"Set the mark of all input from the given mark."
	self subclassResponsibility
)
markUnsatisfied = (
	"Record the fact that I am unsatisfied."
	self subclassResponsibility
)
output = (
	"Answer my current output variable. Raise an error if I am not currently satisfied."
	self subclassResponsibility
)
recalculate = (
	"Calculate the walkabout strength, the stay flag, and, if it is 'stay', the value for the current output of this constraint. Assume this constraint is satisfied."
	self subclassResponsibility
)
removeFromGraph = (
	"Remove myself from the constraint graph."
	self subclassResponsibility
)
satisfy: mark = (
	"Attempt to find a way to enforce this constraint. If successful, record the solution, perhaps modifying the current dataflow graph. Answer the constraint that this constraint overrides, if there is one, or nil, if there isn't. Assume: I am not already satisfied."
	| out overridden |
	self chooseMethod: mark.
	self isSatisfied ifFalse:
		[strength == DBRequired ifTrue:
			[Error signal: 'Could not satisfy a required constraint'].
		^nil].
	"constraint can be satisfied"
	"mark inputs to allow cycle detection in addPropagate"
	self markInputs: mark.
	out := self output.
	overridden := out determinedBy.
	overridden isNil ifFalse: [overridden markUnsatisfied].
	out determinedBy: self.
	(DBThePlanner addPropagate: self mark: mark) ifFalse: [Error signal: 'Cycle encountered'].
	out mark: mark.
	^overridden
)
strength = (
	^strength
)
strength: s = (
	strength := s.
)'as-yet-unclassified'
destroyConstraint = (
	"Deactivate this constraint, remove it from the constraint graph, possibly causing other constraints to be satisfied, and destroy it."
	self isSatisfied ifTrue: [DBThePlanner incrementalRemove: self].
	self removeFromGraph.
)) : (
| "class instance variables"  |
)

'Benchmarks-DeltaBlue'
class DBDirection = Object (
""
| "instance variables" name  |
| "class pool variables" Backward Forward  |
| "shared pool variables"  |
'as yet unclassified'
name: n = (
	name := n. 
)) : (
| "class instance variables"  |
'as yet unclassified'
initialize = (
	"DBDirection initialize"
	DBForward := self name: 'forward'.
	DBBackward := self name: 'backward'.
)
name: n = (
	^self basicNew name: n
))

'Benchmarks-DeltaBlue'
class DBEditConstraint = DBUnaryConstraint (
"I am a unary input constraint used to mark a variable that the client wishes to change."
| "instance variables"  |
| "class pool variables"  |
| "shared pool variables"  |
'as yet unclassified'
execute = (
	"Edit constraints do nothing."
)
isInput = (
	"I indicate that a variable is to be changed by imperative code."
	^true
)
var: v strength: s = (
	super var: v strength: s.
	self addConstraint.
)) : (
| "class instance variables"  |
)

'Benchmarks-DeltaBlue'
class DBEqualityConstraint = DBBinaryConstraint (
"I constrain two variables to have the same value: ''v1 = v2''."
| "instance variables"  |
| "class pool variables"  |
| "shared pool variables"  |
'as yet unclassified'
execute = (
	"Enforce this constraint. Assume that it is satisfied."
	self output value: self input value.
)
var: v1 var: v2 strength: s = (
	super var: v1 var: v2 strength: s.
	self addConstraint.
)) : (
| "class instance variables"  |
)

'Benchmarks-DeltaBlue'
class DBPlan = Object (
"A Plan is an ordered list of constraints to be executed in sequence to resatisfy all currently satisfiable constraints in the face of one or more changing inputs."
| "instance variables" constraints  |
| "class pool variables"  |
| "shared pool variables"  |
'as yet unclassified'
addConstraint: c = (
	constraints addLast: c
)
execute = (
	"Execute my constraints in order."
	constraints do: [:c | c execute]
)
initialize = (
	constraints := OrderedCollection new. 
)) : (
| "class instance variables"  |
)

'Benchmarks-DeltaBlue'
class DBPlanner = Object (
""
| "instance variables" currentMark  |
| "class pool variables"  |
| "shared pool variables"  |
'as yet unclassified'
addConstraintsConsuming: v to: list = (
	| determining |
	determining := v determinedBy.
	v constraints do: [:c | (c ~= determining and: [c isSatisfied]) ifTrue: [list addLast: c]].
)
addPropagate: c mark: mark = (
	"Recompute the walkabout strengths and stay flags of all variables downstream of the given constraint and recompute the actual values of all variables whose stay flag is true. If a cycle is detected, remove the given constraint and answer false. Otherwise, answer true."
	"Details: Cycles are detected when a marked variable is encountered downstream of the given constraint. The sender is assumed to have marked the inputs of the given constraint with the given mark. Thus, encountering a marked node downstream of the output constraint means that there is a path from the constraint's output to one of its inputs."
	| todo |
	todo := OrderedCollection new.
	todo addLast: c.
	[todo isEmpty] whileFalse: [
		| d |
		d := todo removeLast.
		d output mark == mark ifTrue: [self incrementalRemove: c. ^false].
		d recalculate.
		self addConstraintsConsuming: d output to: todo.
	].
	^true
)
extractPlanFromConstraints: constraints = (
	"Extract a plan for resatisfaction starting from the outputs of the given constraints, usually a set of input constraints."
	| sources |
	sources := OrderedCollection new.
	constraints do: [:c | (c isInput and: [c isSatisfied]) ifTrue: [sources addLast: c]].
	^self makePlan: sources
)
incrementalAdd: c = (
	"Attempt to satisfy the given constraint and, if successful, incrementally update the dataflow graph.  Details: If satisfying the constraint is successful, it may override a weaker constraint on its output. The algorithm attempts to resatisfy that constraint using some other method. This process is repeated until either a) it reaches a variable that was not previously determined by any constraint or b) it reaches a constraint that is too weak to be satisfied using any of its methods. The variables of constraints that have been processed are marked with a unique mark value so that we know where we've been. This allows the algorithm to avoid getting into an infinite loop even if the constraint graph has an inadvertent cycle."
	| mark overridden |
	mark := self newMark.
	overridden := c satisfy: mark.
	[overridden isNil] whileFalse: [overridden := overridden satisfy: mark].
)
incrementalRemove: c = (
	"Entry point for retracting a constraint. Remove the given constraint and incrementally update the dataflow graph."
	"Details: Retracting the given constraint may allow some currently unsatisfiable downstream constraint to be satisfied. We therefore collect a list of unsatisfied downstream constraints and attempt to satisfy each one in turn. This list is traversed by constraint strength, strongest first, as a heuristic for avoiding unnecessarily adding and then overriding weak constraints. Assume: c is satisfied."
	| out unsatisfied |
	out := c output.
	c markUnsatisfied.
	c removeFromGraph.
	unsatisfied := self removePropagateFrom: out.
	DBDescendingStrengths do: [:strength | 
		unsatisfied do: [:u | 
			u strength = strength
				ifTrue: [self incrementalAdd: u]]].
)
initialize = (
	currentMark := 0.
)
makePlan: sources = (
	"Extract a plan for resatisfaction starting from the given source constraints, usually a set of input constraints. This method assumes that stay optimization is desired; the plan will contain only constraints whose output variables are not stay. Constraints that do no computation, such as stay and edit constraints, are not included in the plan."
	"Details: The outputs of a constraint are marked when it is added to the plan under construction. A constraint may be appended to the plan when all its input variables are known. A variable is known if either a) the variable is marked (indicating that has been computed by a constraint appearing earlier in the plan), b) the variable is 'stay' (i.e. it is a constant at plan execution time), or c) the variable is not determined by any constraint. The last provision is for past states of history variables, which are not stay but which are also not computed by any constraint. Assume: sources are all satisfied."
	| mark plan todo |
	mark := self newMark.
	plan := DBPlan new.
	todo := sources.
	[todo isEmpty] whileFalse: [
		| c |
		c := todo removeLast.
		(c output mark ~= mark and: [c inputsKnown: mark]) ifTrue: [
			"not in plan already and eligible for inclusion"
			plan addConstraint: c.
			c output mark: mark.
			self addConstraintsConsuming: c output to: todo.
		]
	].
	^plan
)
newMark = (
	"Select a previously unused mark value."
	currentMark := currentMark + 1.
	^currentMark
)
projectionTest: n = (
	"This test constructs a two sets of variables related to each other by a simple linear transformation (scale and offset). The time is measured to change a variable on either side of the mapping and to change the scale and offset factors."
	| scale offset src dst dests |
	scale := DBVariable name: 'scale' initialValue: 10.
	offset := DBVariable name: 'offset' initialValue: 1000.
	dests := OrderedCollection new.
	0 to: n-1 do: [:i |
		src := DBVariable name: 'src', i printString initialValue: i.
		dst := DBVariable name: 'dst', i printString initialValue: i.
		dests addLast: dst.
		DBStayConstraint var: src strength: DBNormal.
		DBScaleConstraint source: src scale: scale offset: offset destination: dst strength: DBRequired.
	].
	
	self setValueOf: src to: 17.
	dst value = 1170 ifFalse: [Error signal: 'Projection test 1 failed!'].
	
	self setValueOf: dst to: 1050.
	src value = 5 ifFalse: [Error signal: 'Projection test 2 failed!'].
	
	self setValueOf: scale to: 5.
	0 to: n - 2 do:
		[:i | (dests at: i + 1) value = (i * 5 + 1000)
			ifFalse: [Error signal: 'Projection test 3 failed!'] ].
	
	self setValueOf: offset to: 2000.
	0 to: n - 2 do:
		[:i | (dests at: i + 1) value = (i * 5 + 2000)
			ifFalse: [Error signal: 'Projection test 4 failed!']].
)
propagateFrom: v = (
	"The given variable has changed. Propagate new values downstream."
	| todo |
	todo := OrderedCollection new.
	self addConstraintsConsuming: v to: todo.
	[todo isEmpty] whileFalse: [
		| c |
		c := todo removeLast.
		c execute.
		self addConstraintsConsuming: c output to: todo.
	].
)
removePropagateFrom: out = (
	"Update the walkabout strengths and stay flags of all variables downstream of the given constraint. Answer a collection of unsatisfied constraints sorted in order of decreasing strength."
	| unsatisfied todo |
	out determinedBy: nil.
	out walkStrength: DBWeakest.
	out stay: true.
	unsatisfied := OrderedCollection new.
	todo := OrderedCollection new.
	todo addLast: out.
	[todo isEmpty] whileFalse: [
		| v determining |
		v := todo removeLast.
		v constraints do: [:c | c isSatisfied ifFalse: [unsatisfied addLast: c]].
		determining := v determinedBy.
		v constraints do: [:nextC | 
			(nextC ~= determining and: [nextC isSatisfied])
				ifTrue: [nextC recalculate. todo addLast: nextC output]].
	].
	^unsatisfied
)'as-yet-unclassified'
chainTest: n = (
	"This is the standard DeltaBlue benchmark. A long chain of equality constraints is constructed with a stay constraint on one end. An edit constraint is then added to the opposite end and the time is measured for adding and removing this constraint, and extracting and executing a constraint satisfaction plan. There are two cases. In case 1, the added constraint is stronger than the stay constraint and values must propagate down the entire length of the chain. In case 2, the added constraint is weaker than the stay constraint so it cannot be accommodated. The cost in this case is, of course, very low. Typical situations lie somewhere between these two extremes."
	| prev first last editC editV plan |
	1 to: n do: [:i | 
		| name v |
		name := 'v', i printString.	
		v := DBVariable name: name initialValue: 0.
		prev isNil ifFalse: [DBEqualityConstraint var: prev var: v strength: DBRequired].
		i == 1 ifTrue: [first := v].
		i == n ifTrue: [last := v].
		prev := v.
	].

	DBStayConstraint var: last strength: DBStrongDefault.
	editC := DBEditConstraint var: first strength: DBPreferred.
	editV := OrderedCollection new.
	editV addLast: editC.
	plan := self extractPlanFromConstraints: editV.
	1 to: n do: [:i |
		first value: i.
		plan execute.
		last value == i ifFalse: [Error signal: 'Chain test failed!'].
	].
	editC destroyConstraint.
)
setValueOf: var to: newValue = (
	| editC editV plan |
	editC := DBEditConstraint var: var strength: DBPreferred.
	editV := OrderedCollection new.
	editV addLast: editC.
	plan := self extractPlanFromConstraints: editV.
	10 timesRepeat: [var value: newValue. plan execute].
	editC destroyConstraint.
)) : (
| "class instance variables"  |
'as yet unclassified'
initialize = (
	"DBPlanner initialize"
	DBThePlanner := DBPlanner new.
))

'Benchmarks-DeltaBlue'
class DBScaleConstraint = DBBinaryConstraint (
"I relate two variables by the linear scaling relationship: ''v2 = (v1 * scale) + offset''. Either v1 or v2 may be changed to maintain this relationship but the scale factor and offset are considered read-only."
| "instance variables" scale offset  |
| "class pool variables"  |
| "shared pool variables"  |
'as yet unclassified'
addToGraph = (
	"Add myself to the constraint graph."
	super addToGraph.
	scale addConstraint: self.
	offset addConstraint: self.
)
execute = (
	"Enforce this constraint. Assume that it is satisfied."
	direction == DBForward
		ifTrue: [v2 value: v1 value * scale value + offset value]
		ifFalse: [v1 value: (v2 value - offset value) // scale value].
)
markInputs: mark = (
	"Mark the inputs from the given mark."
	super markInputs: mark.
	scale mark: mark.
	offset mark: mark.
)
removeFromGraph = (
	"Remove myself from the constraint graph."
	super removeFromGraph.
	scale isNil ifFalse: [scale removeConstraint: self].
	offset isNil ifFalse: [offset removeConstraint: self].
)
source: src scale: scalep offset: offsetp destination: dst strength: s = (
	super var: src var: dst strength: s.
	scale := scalep.
	offset := offsetp.
	self addConstraint.
)'as-yet-unclassified'
recalculate = (
	"Calculate the walkabout strength, the stay flag, and, if it is 'stay', the value for the current output of this constraint. Assume this constraint is satisfied."
	| in out |
	in := self input. out := self output.
	out walkStrength: (strength weakest: in walkStrength).
	out stay: (in stay and: [scale stay and: [offset stay]]).
	out stay ifTrue: [self execute]. "stay optimization"
)) : (
| "class instance variables"  |
'as yet unclassified'
source: src scale: scale offset: offset destination: dst strength: s = (
	^self new source: src scale: scale offset: offset destination: dst strength: s
))

'Benchmarks-DeltaBlue'
class DBStayConstraint = DBUnaryConstraint (
"I mark variables that should, with some level of preference, stay the same. I have one method with zero inputs and one output, which does nothing. Planners may exploit the fact that, if I am satisfied, my output will not change during plan execution. This is called ''stay optimization''."
| "instance variables"  |
| "class pool variables"  |
| "shared pool variables"  |
'as yet unclassified'
execute = (
	"Stay constraints do nothing." 
)
var: v strength: s = (
	super var: v strength: s.
	self addConstraint.
)) : (
| "class instance variables"  |
)

'Benchmarks-DeltaBlue'
class DBStrength = Object (
"Strengths are used to measure the relative importance of constraints. New strengths may be inserted in the strength hierarchy without disrupting current constraints. Strengths cannot be created outside this class, so pointer comparison can be used for value comparison."
| "instance variables" name value  |
| "class pool variables"  |
| "shared pool variables"  |
'as yet unclassified'
name: n value: v = (
	name := n.
	value := v. 
)
strongerThan: other = (
	^value < other value
)
strongest: other = (
	^(self strongerThan: other) ifTrue: [self] ifFalse: [other]
)
value = (
	^value
)
weakerThan: other = (
	^value > other value
)
weakest: other = (
	^(self weakerThan: other) ifTrue: [self] ifFalse: [other]
)) : (
| "class instance variables"  |
'as yet unclassified'
initialize = (
	"DBStrength initialize"
	DBRequired := self name: 'required' value: 0.
	DBStrongPreferred := self name: 'strongPreferred' value: 1.
	DBPreferred := self name: 'preferred' value: 2.
	DBStrongDefault := self name: 'strongDefault' value: 3.
	DBNormal := self name: 'normal' value: 4.
	DBWeakDefault := self name: 'weakDefault' value: 5.
	DBWeakest := self name: 'weakest' value: 6.

	DBDescendingStrengths := 
		{DBRequired.
		DBStrongPreferred.
		DBPreferred.
		DBStrongDefault.
		DBNormal.
		DBWeakDefault.
		DBWeakest}.
)
name: n value: v = (
	^self basicNew name: n value: v
))

'Benchmarks-DeltaBlue'
class DBUnaryConstraint = DBConstraint (
"I am an abstract superclass for constraints having a single possible output variable."
| "instance variables" myOutput satisfied  |
| "class pool variables"  |
| "shared pool variables"  |
'as yet unclassified'
addToGraph = (
	"Add myself to the constraint graph."
	myOutput addConstraint: self.
	satisfied := false. 
)
chooseMethod: mark = (
	"Decide if I can be satisfied and record that decision."
	satisfied := (myOutput mark ~= mark and: [strength strongerThan: myOutput walkStrength])
)
inputsKnown: mark = (
	^true
)
isSatisfied = (
	"Answer true if this constraint is satisfied in the current solution."
	^satisfied
)
markInputs: mark = (
	"I have no inputs."
)
markUnsatisfied = (
	"Record the fact that I am unsatisfied."
	satisfied := false
)
output = (
	^myOutput
)
recalculate = (
	"Calculate the walkabout strength, the stay flag, and, if it is 'stay', the value for the current output of this constraint. Assume this constraint is satisfied."
	myOutput walkStrength: strength.
	myOutput stay: self isInput not.
	myOutput stay ifTrue: [self execute]. "Stay optimization"
)
removeFromGraph = (
	"Remove myself from the constraint graph."
	myOutput isNil ifFalse: [myOutput removeConstraint: self].
	satisfied := false.
)
var: v strength: s = (
	super strength: s.
	myOutput := v.
	satisfied := false.
)) : (
| "class instance variables"  |
'as yet unclassified'
var: v strength: s = (
	^self new var: v strength: s
))

'Benchmarks-DeltaBlue'
class DBVariable = Object (
"I represent a constrained variable. In addition to my value, I maintain the structure of the constraint graph, the current dataflow graph, and various parameters of interest to the DeltaBlue incremental constraint solver."
| "instance variables" value constraints determinedBy mark walkStrength stay name  |
| "class pool variables"  |
| "shared pool variables"  |
'as yet unclassified'
addConstraint: c = (
	"Add the given constraint to the set of all constraints that refer to me."
	constraints addLast: c.
)
constraints = (
	^constraints
)
determinedBy = (
	^determinedBy
)
determinedBy: c = (
	determinedBy := c
)
mark = (
	^mark
)
mark: m = (
	mark := m
)
name: n initialValue: v = (
	value := v.
	constraints := OrderedCollection new: 2.
	determinedBy := nil.
	mark := 0.
	walkStrength := DBWeakest.
	stay := true.
	name := n.
)
removeConstraint: c = (
	"Remove all traces of c from this variable."
	constraints remove: c ifAbsent: [].
	determinedBy == c ifTrue: [determinedBy := nil]. 
)
stay = (
	^stay
)
stay: b = (
	stay := b
)
value = (
	^value
)
value: v = (
	value := v.
)
walkStrength = (
	^walkStrength
)
walkStrength: s = (
	walkStrength := s
)) : (
| "class instance variables"  |
'as yet unclassified'
name: n initialValue: v = (
	^self basicNew name: n initialValue: v
))

'Benchmarks-ParserCombinators'
class PCAlternatingParser = PCCombinatorialParser (
""
| "instance variables" p q  |
| "class pool variables"  |
| "shared pool variables"  |
'as yet unclassified'
compress = (
	compressed ifTrue: [^self].
	compressed := true.
	p := p compress.
	q := q compress.
	^self
)
either: pArg or: qArg = (
	compressed := false.
	p := pArg.
	q := qArg.
)
parseWithContext: ctxt ifError: onError = (
	| pos |
	pos := ctxt position.
	^p parseWithContext: ctxt ifError: [ctxt position: pos. ^q parseWithContext: ctxt ifError: onError]
)) : (
| "class instance variables"  |
)

'Benchmarks-ParserCombinators'
class PCCharacterRangeParser = PCCombinatorialParser (
""
| "instance variables" lowerBound upperBound  |
| "class pool variables"  |
| "shared pool variables"  |
'as yet unclassified'
between: c1 and: c2 = (
	lowerBound := c1.
	upperBound := c2.
)
compress = (
	^self
)
parseWithContext: ctxt ifError: onError = (
	| c |
	ctxt atEnd ifTrue: [onError value].
	c := ctxt next.
	(lowerBound <= c) & (c <= upperBound) ifTrue: [^c].
	onError value.
)) : (
| "class instance variables"  |
)

'Benchmarks-ParserCombinators'
class PCCombinatorialParser = Object (
""
| "instance variables" compressed  |
| "class pool variables"  |
| "shared pool variables"  |
'as yet unclassified'
, p = (
	^PCSequencingParser new subparsers: {self. p}
)
char: c = (
	^PCCharacterRangeParser new between: c and: c.
)
charBetween: c1 and: c2 = (
	^PCCharacterRangeParser new between: c1 and: c2.
)
eoi = (
	^PCEOIParser new
)
parseWithContext: ctxt ifError: onError = (
	self subclassResponsibility
)
star = (
	^PCStarParser new repeat: self
)
wrapper: block = (
	^PCWrappingParser new wrap: self with: block
)
| q = (
	^PCAlternatingParser new either: self or: q
)) : (
| "class instance variables"  |
)

'Benchmarks-ParserCombinators'
class PCEOIParser = PCCombinatorialParser (
""
| "instance variables"  |
| "class pool variables"  |
| "shared pool variables"  |
'as yet unclassified'
compress = (
	^self
)
parseWithContext: ctxt ifError: onError = (
	ctxt atEnd ifTrue: [^nil].
	onError value.
)) : (
| "class instance variables"  |
)

'Benchmarks-ParserCombinators'
class PCForwardReferenceParser = PCCombinatorialParser (
""
| "instance variables" forwardee  |
| "class pool variables"  |
| "shared pool variables"  |
'as yet unclassified'
bind: p = (
	self assert: [forwardee isNil] message: ''.
	forwardee := p.
)
compress = (
	^forwardee compress
)) : (
| "class instance variables"  |
)

'Benchmarks-ParserCombinators'
class PCParserContext = Object (
""
| "instance variables" content position  |
| "class pool variables"  |
| "shared pool variables"  |
'as yet unclassified'
atEnd = (
	^position >= content size
)
next = (
	position := position + 1.
	^content at: position
)
over: s = (
	content := s.
	position := 0.
)
position = (
	^position
)
position: v = (
	position := v
)) : (
| "class instance variables"  |
)

'Benchmarks-ParserCombinators'
class PCSequencingParser = PCCombinatorialParser (
""
| "instance variables" subparsers  |
| "class pool variables"  |
| "shared pool variables"  |
'as yet unclassified'
, p = (
	^PCSequencingParser new subparsers: (subparsers copyWith: p)
)
compress = (
	compressed ifTrue: [^self].
	compressed := true.
	subparsers := subparsers collect: [:e | e compress].
	^self
)
parseWithContext: ctxt ifError: onError = (
	^subparsers collect: [:p | p parseWithContext: ctxt ifError: onError]
)
subparsers: ps = (
	compressed := false.
	subparsers := ps.
)
wrapper: block = (
	^PCWrappingParser new wrap: self with: [:results | block valueWithArguments: results]
)) : (
| "class instance variables"  |
)

'Benchmarks-ParserCombinators'
class PCSimpleExpressionGrammar = PCCombinatorialParser (
""
| "instance variables" start exp e1 e2 parenExp number plus times digit lparen rparen  |
| "class pool variables"  |
| "shared pool variables"  |
'as yet unclassified'
initialize = (
	start := PCForwardReferenceParser new.
	exp := PCForwardReferenceParser new.
	e1 := PCForwardReferenceParser new.
	e2 := PCForwardReferenceParser new.
	parenExp := PCForwardReferenceParser new.
	number := PCForwardReferenceParser new.
	plus := PCForwardReferenceParser new.
	times := PCForwardReferenceParser new.
	digit := PCForwardReferenceParser new.
	lparen := PCForwardReferenceParser new.
	rparen := PCForwardReferenceParser new.

	start bind: (exp, self eoi wrapper: [:v :dollar | v]).
	exp bind: (e1, (plus, e1) star wrapper: [:lhs :rhss | 
		| z | z := lhs. rhss do: [:rhs | z := z + (rhs at: 2) rem: 16rFFFF]. z]).
	e1 bind: (e2, (times, e2) star wrapper: [:lhs :rhss | 
		| z | z := lhs. rhss do: [:rhs | z := z * (rhs at: 2) rem: 16rFFFF]. z]).
	e2 bind: (number | parenExp).
	
	parenExp bind: (lparen, exp, rparen wrapper: [:lhs :e :rhs | e]).
	number bind: (digit wrapper: [:d | d asString asNumber]).
	
	plus bind: (self char: $+).
	times bind: (self char: $*).
	digit bind: (self charBetween: $0 and: $9).
	lparen bind: (self char: $().
	rparen bind: (self char: $))
)
start = (
	^start
)) : (
| "class instance variables"  |
)

'Benchmarks-ParserCombinators'
class PCStarParser = PCCombinatorialParser (
""
| "instance variables" p  |
| "class pool variables"  |
| "shared pool variables"  |
'as yet unclassified'
compress = (
	compressed ifTrue: [^self].
	compressed := true.
	p := p compress.
	^self
)
parseWithContext: ctxt ifError: onError = (
	| results |
	results := OrderedCollection new.
	[
		| pos |
		pos := ctxt position.
		results add: (p parseWithContext: ctxt ifError: [ctxt position: pos. ^results]).
	] repeat.
)
repeat: pArg = (
	compressed := false.
	p := pArg.
)
wrapper: block = (
	^PCWrappingParser new wrap: self with: [:results | block valueWithArguments: results]
)) : (
| "class instance variables"  |
)

'Benchmarks-ParserCombinators'
class PCWrappingParser = PCCombinatorialParser (
""
| "instance variables" p b  |
| "class pool variables"  |
| "shared pool variables"  |
'as yet unclassified'
compress = (
	compressed ifTrue: [^self].
	compressed := true.
	p := p compress.
	^self
)
parseWithContext: ctxt ifError: onError = (
	^b value: (p parseWithContext: ctxt ifError: onError)
)
wrap: pArg with: bArg = (
	compressed := false.
	p := pArg.
	b := bArg.
)) : (
| "class instance variables"  |
)

'Benchmarks-Richards'
class RDeviceTask = RTask (
"A task that suspends itself after each time it has been run to simulate waiting for data from an external device."
| "instance variables" pending  |
| "class pool variables"  |
| "shared pool variables"  |
'as yet unclassified'
run: packet = (
	packet isNil ifTrue:
		[ | functionWork |
		pending isNil ifTrue: [^scheduler suspendCurrent].
		functionWork := pending.
		pending := nil.
		^scheduler queue: functionWork].
	pending := packet.
	^scheduler holdCurrent
)) : (
| "class instance variables"  |
'as yet unclassified'
on: s = (
	^self basicNew on: s
))

'Benchmarks-Richards'
class RHandlerTask = RTask (
"A task that manipulates work packets and then suspends itself."
| "instance variables" workIn deviceIn  |
| "class pool variables"  |
| "shared pool variables"  |
'as yet unclassified'
run: packet = (
	packet isNil ifFalse:
		[packet kind == KIND_WORK
			ifTrue: [workIn := packet appendTo: workIn]
			ifFalse: [deviceIn := packet appendTo: deviceIn]].
	workIn isNil ifFalse:
		[ | v count |
		count := workIn datum.
		count < DATA_SIZE
			ifTrue:
				[deviceIn isNil ifFalse:
					[v := deviceIn.
					deviceIn := deviceIn link.
					v datum: (workIn data at: count + 1 " 1-origin conversion, sigh ").
					workIn datum: (count + 1).
					^scheduler queue: v]]
			ifFalse:
				[v := workIn.
				workIn := workIn link.
				^scheduler queue: v]].
	^scheduler suspendCurrent
)) : (
| "class instance variables"  |
'as yet unclassified'
on: s = (
	^self basicNew on: s
))

'Benchmarks-Richards'
class RIdleTask = RTask (
"An idle task doesn't do any work itself but cycles control between the two device tasks."
| "instance variables" control count  |
| "class pool variables"  |
| "shared pool variables"  |
'as yet unclassified'
on: s with: ctrl with: cnt = (
	super on: s.
	control := ctrl.
	count := cnt.
)
run: packet = (
	count := count - 1.
	count = 0 ifTrue: [^scheduler holdCurrent].
	(control bitAnd: 1) = 0 ifTrue:
		[control := control quo: 2.
		^scheduler release: ID_DEVICE_A].
	control := (control quo: 2) bitXor: 16rD008.
	^scheduler release: ID_DEVICE_B
)) : (
| "class instance variables"  |
'as yet unclassified'
on: s with: ctrl with: cnt = (
	^self basicNew on: s with: ctrl with: cnt
))

'Benchmarks-Richards'
class RPacket = Object (
""
| "instance variables" link identity kind datum data  |
| "class pool variables"  |
| "shared pool variables"  |
'as yet unclassified'
appendTo: queueHead = (
	"Add this packet to the end of a worklist, and return the worklist."
	| peek next |
	link := nil.
	queueHead isNil ifTrue: [^self].
	next := queueHead.
	[(peek := next link) isNil]
		whileFalse: [next := peek].
	next link: self.
   	^queueHead
)
data = (
	^data
)
datum = (
	^datum
)
datum: d = (
	datum := d
)
identity = (
	^identity
)
identity: i = (
	identity := i
)
kind = (
	^kind
)
link = (
	^link
)
link: l = (
	link := l
)
link: l identity: i kind: k = (
	link := l.
	identity := i.
	kind := k.
	datum := 0.
	data := Array new: DATA_SIZE.
)) : (
| "class instance variables"  |
'as yet unclassified'
link: l identity: i kind: k = (
	^self basicNew link: l identity: i kind: k
))

'Benchmarks-Richards'
class RScheduler = Object (
"A scheduler can be used to schedule a set of tasks based on their relative priorities.  Scheduling is done by maintaining a list of task control blocks which holds tasks and the data queue they are processing."
| "instance variables" queueCount holdCount currentTcb currentId list blocks  |
| "class pool variables"  |
| "shared pool variables"  |
'as yet unclassified'
addDeviceTask: id priority: priority work: queue = (
	"Add a device task to this scheduler."
	self addTask: id priority: priority work: queue task: (RDeviceTask on: self).
)
addHandlerTask: id priority: priority work: queue = (
	"Add a handler task to this scheduler."
	self addTask: id priority: priority work: queue task: (RHandlerTask on: self).
)
addIdleTask: id priority: priority work: queue state: count = (
	"Add an idle task to this scheduler."
	self addRunningTask: id priority: priority work: queue task: (RIdleTask on: self with: 1 with: count).
)
addRunningTask: id priority: priority work: queue task: task = (
	self addTask: id priority: priority work: queue task: task.
	currentTcb setRunning.
)
addTask: id priority: priority work: queue task: task = (
	currentTcb := RTaskControlBlock link: list id: id priority: priority queue: queue task: task.
	list := currentTcb.
	blocks at: id put: currentTcb.
)
addWorkerTask: id priority: priority work: queue = (
	"Add a work task to this scheduler."
	self addTask: id priority: priority work: queue task: (RWorkerTask on: self with: ID_HANDLER_A with: 0).
)
holdCount = (
	^holdCount
)
holdCurrent = (
	"Block the currently executing task and return the next task control block to run.  The blocked task will not be made runnable until it is explicitly released, even if new work is added to it."
	holdCount := holdCount + 1.
	currentTcb markAsHeld.
	^currentTcb link
)
initialize = (
	queueCount := 0.
	holdCount := 0.
	currentTcb := nil.
	currentId := nil.
	list := nil.
	blocks := Array new: NUMBER_OF_IDS.
)
queue: packet = (
	"Add the specified packet to the end of the worklist used by the task associated with the packet and make the task runnable if it is currently suspended."
	| t |
	t := blocks at: packet identity.
	t isNil ifTrue: [^t].
	queueCount := queueCount + 1.
	packet link: nil.
	packet identity: currentId.
	^t addInput: packet checkPriority: currentTcb
)
queueCount = (
	^queueCount
)
release: id = (
	"Release a task that is currently blocked and return the next block to run."
	| tcb |
	tcb := blocks at: id.
	tcb isNil ifTrue: [^tcb].
	tcb markAsNotHeld.
	tcb priority > currentTcb priority ifTrue: [^tcb].
	^currentTcb
)
schedule = (
	"Execute the tasks managed by this scheduler."
	currentTcb := list.
	[currentTcb isNil] whileFalse:
		[currentTcb isHeldOrSuspended
			ifTrue: [currentTcb := currentTcb link]
			ifFalse: [currentId := currentTcb identity.
					currentTcb := currentTcb run]].
)
suspendCurrent = (
	"Suspend the currently executing task and return the next task control block to run. If new work is added to the suspended task it will be made runnable."
	currentTcb markAsSuspended.
	^currentTcb
)) : (
| "class instance variables"  |
)

'Benchmarks-Richards'
class RTask = Object (
""
| "instance variables" scheduler  |
| "class pool variables"  |
| "shared pool variables"  |
'as yet unclassified'
on: s = (
	scheduler := s.
)
run: packet = (
	self subclassResponsibility
)) : (
| "class instance variables"  |
)

'Benchmarks-Richards'
class RTaskControlBlock = Object (
"A task control block manages a task and the queue of work packages associated with it."
| "instance variables" link identity priority queue task state  |
| "class pool variables"  |
| "shared pool variables"  |
'as yet unclassified'
addInput: packet checkPriority: oldTask = (
	"Adds a packet to the worklist of this block's task, marks this as runnable if necessary, and returns the next runnable object to run (the one with the highest priority."
	queue isNil
		ifTrue:
			[queue := packet.
			self markAsRunnable.
			priority > oldTask priority ifTrue: [^self]]
		ifFalse:
			[queue := packet appendTo: queue].
	^oldTask
)
identity = (
	^identity
)
isHeldOrSuspended = (
	^(state bitAnd: STATE_HELD) ~= 0
		or: [state == STATE_SUSPENDED]
)
link = (
	^link
)
link: l id: i priority: p queue: q task: t = (
	link := l.
	identity := i.
	priority := p.
	queue := q.
	task := t.
	state := queue isNil
		ifTrue: [STATE_SUSPENDED]
		ifFalse: [STATE_SUSPENDED_RUNNABLE]
)
markAsHeld = (
	state := state bitOr: STATE_HELD.
)
markAsNotHeld = (
	state := state bitAnd: STATE_NOT_HELD.
)
markAsRunnable = (
	state := state bitOr: STATE_RUNNABLE.
)
markAsSuspended = (
	state := state bitOr: STATE_SUSPENDED.
)
priority = (
	^priority
)
run = (
	"Runs this task, if it is ready to be run, and returns the next task to run."
	| packet |
	state == STATE_SUSPENDED_RUNNABLE ifTrue: [
		packet := queue.
		queue := packet link.
		state := queue isNil ifTrue: [STATE_RUNNING] ifFalse: [STATE_RUNNABLE].	
	].
	^task run: packet
)
setRunning = (
	state := STATE_RUNNING
)) : (
| "class instance variables"  |
'as yet unclassified'
link: l id: i priority: p queue: q task: t = (
	^self basicNew link: l id: i priority: p queue: q task: t
))

'Benchmarks-Richards'
class RWorkerTask = RTask (
""
| "instance variables" destination count  |
| "class pool variables"  |
| "shared pool variables"  |
'as yet unclassified'
on: s with: v1 with: v2 = (
	super on: s.
	destination := v1.
	count := v2.
)
run: packet = (
	packet isNil ifTrue: [^scheduler suspendCurrent].
	destination = ID_HANDLER_A
		ifTrue: [destination := ID_HANDLER_B]
		ifFalse: [destination := ID_HANDLER_A].
	packet identity: destination.
	packet datum: 0.
	1 to: DATA_SIZE do: [:i |
		count := count + 1.
		count > 26 ifTrue: [count := 1].
		packet data at: i put: count.
	].
	^scheduler queue: packet
)) : (
| "class instance variables"  |
'as yet unclassified'
on: s with: v1 with: v2 = (
	^self basicNew on: s with: v1 with: v2
))

'Benchmarks-Splay'
class SLeaf = Object (
""
| "instance variables" string array  |
| "class pool variables"  |
| "shared pool variables"  |
'as yet unclassified'
withTag: tag = (
	string := 'String for key ',tag,' in leaf node'.
	array := {0. 1. 2. 3. 4. 5. 6. 7. 8. 9}.
)) : (
| "class instance variables"  |
'as yet unclassified'
withTag: tag = (
	^self new withTag: tag
))

'Benchmarks-Splay'
class SNode = Object (
""
| "instance variables" key value left right  |
| "class pool variables"  |
| "shared pool variables"  |
'as yet unclassified'
key = (
	^key
)
key: k value: v = (
	key := k.
	value := v.
)
left = (
	^left
)
left: l = (
	left := l.
)
right = (
	^right
)
right: r = (
	right := r
)
traverse: f = ( "<[:Node]>"
	"Performs an ordered traversal of the subtree starting here."
	| current |
	current := self.
	[current == nil] whileFalse:
		[ | left |
		left := current left.
		left == nil ifFalse: [left traverse: f].
		f value: current.
		current := current right].
)) : (
| "class instance variables"  |
'as yet unclassified'
key: k value: v = (
	^self new key: k value: v
))

'Benchmarks-Splay'
class SPayload = Object (
""
| "instance variables" left right  |
| "class pool variables"  |
| "shared pool variables"  |
'as yet unclassified'
left: l right: r = (
	left := l.
	right := r.
)) : (
| "class instance variables"  |
'as yet unclassified'
generate: depth with: tag = (
	depth = 0 ifTrue: [^SLeaf withTag: tag].
	^SPayload 
		left: (self generate: depth - 1 with: tag)
		right: (self generate: depth - 1 with: tag)
)
left: l right: r = (
	^self new left: l right: r
))

'Benchmarks-Splay'
class SSplayTree = Object (
"A splay tree is a self-balancing binary search tree with the additional property that recently accessed elements are quick to access again. It performs basic operations such as insertion, look-up and removal in O(log(n)) amortized time."
| "instance variables" root  |
| "class pool variables"  |
| "shared pool variables"  |
'as yet unclassified'
at: key = ( "<Number> ^<Node>"
	"Returns the node having the specified [key] or null if the tree doesn't contain a node with the specified [key]."
	
	self isEmpty ifTrue: [^nil].
	self splay: key.
	^root key = key ifTrue: [root] ifFalse: [nil]
)
at: key "<Number>" put: value = (
	"Inserts a node into the tree with the specified [key] and value if the tree does not already contain a node with the specified key. If the value is inserted, it becomes the root of the tree."
	| node |
	
	self isEmpty ifTrue: [root := SNode key: key value: value. ^self].
	
	"Splay on the key to move the last node on the search path for the key to the root of the tree."
	self splay: key.
	
	root key = key ifTrue: [^self].
	node:= SNode key: key value: value.
	key > root key
		ifTrue: 
			[node left: root.
			node right: root right.
			root right: nil]
		ifFalse:
			[node right: root.
			node left: root left.
			root left: nil].
	root := node.
)
exportKeys = ( "^<List[Number]>"
	"Returns a list with all the keys of the tree."
	| result |
	result := OrderedCollection new.
	self isEmpty ifFalse: [root traverse: [:node | result add: node key]].
	^result
)
findGreatestLessThan: key = ( "<Number> ^<Node>"
	"Returns the Node having the maximum key value that is less than the specified [key]."
	self isEmpty ifTrue: [^nil].
	
	"Splay on the key to move the node with the given key or the last node on the search path to the top of the tree."
	self splay: key.
	"Now the result is either the root node or the greatest node in the left subtree."
	root key < key ifTrue: [^root].
	root left == nil ifFalse: [^self findMax: root left].
	^nil
)
findMax = ( "^<Node>"
	^self findMax: root
)
findMax: start = ( "<Node> ^<Node>"
	| current |
	self isEmpty ifTrue: [^nil].
	current := start.
	[current right == nil] whileFalse: [current := current right].
	^current
)
isEmpty = (
	^root == nil
)
removeKey: key = ( "<Number> ^<Node>"
	"Removes a node with the specified key from the tree if the tree contains a node with this key. The removed node is returned. If [key] is not found, an exception is thrown."
	| removed |
	
	self isEmpty ifTrue: [self error: 'Key not found: ', key printString].
	self splay: key.
	root key = key ifFalse: [self error: 'Key not found: ', key printString].
	removed := root.
	root left == nil
		ifTrue:
			[root := root right]
		ifFalse:
			[ | right |
			right := root right.
			root := root left.
			"Splay to make sure that the new root has an empty right child."
			self splay: key.
			"Insert the original right child as the right child of the new root."
			root right: right].
	^removed
)
splay: key = ( "<Number>"
	"Perform the splay operation for the given key. Moves the node with the given key to the top of the tree.  If no node has the given key, the last node on the search path is moved to the top of the tree. This is the simplified top-down splaying algorithm from: ''Self-adjusting Binary Search Trees'' by Sleator and Tarjan"
	| dummy left right current break |
	
	self isEmpty ifTrue: [^self].
	dummy := SHNode key: nil value: nil.
	left := right := dummy.
	current := root.
	
	break :=
		[left right: current left.
		right left: current right.
		current left: dummy right.
		current right: dummy left.
		root := current].
	
	[
		key < current key ifTrue: [
			current left == nil ifTrue: [^break value].
			key < current left key ifTrue: [
				"Rotate right"
				| tmp |
				tmp := current left.
				current left: tmp right.
				tmp right: current.
				current := tmp.
				current left == nil ifTrue: [^break value].
			].
			"Link right"
			right left: current.
			right := current.
			current := current left.
		] ifFalse: [key > current key ifTrue: [
			current right == nil ifTrue: [^break value].
			key > current right key ifTrue: [
				"Rotate left"
				| tmp |
				tmp := current right.
				current right: tmp left.
				tmp left: current.
				current := tmp.
				current right == nil ifTrue: [^break value].
			].
			"Link left"
			left right: current.
			left := current.
			current := current right.
		] ifFalse: [
			^break value
		]].
	] repeat.
)) : (
| "class instance variables"  |
)

'Benchmarks-Microbenchmarks'
class SmalltalkClosureDefFibonacci = Benchmark (
"A microbenchmark stressing closure creation and integer arithmetic.

Copyright 2014 Google Inc.

Licensed under the Apache License, Version 2.0 (the ''License''); you may not use this file except in compliance with the License.  You may obtain a copy of the License at  http://www.apache.org/licenses/LICENSE-2.0"
| "instance variables"  |
| "class pool variables"  |
| "shared pool variables"  |
'as yet unclassified'
fib: x = (
	| f |
	f := [:n | n < 2 ifTrue: [1] ifFalse: [(self fib: n-1) + (self fib: n-2)]].
	^f value: x
)
run = (
	self fib: 25
)) : (
| "class instance variables"  |
)

'Benchmarks-Microbenchmarks'
class SmalltalkClosureFibonacci = Benchmark (
"A microbenchmark stressing closure evalutation and integer arithmetic.

Copyright 2012 Google Inc.

Licensed under the Apache License, Version 2.0 (the ''License''); you may not use this file except in compliance with the License.  You may obtain a copy of the License at  http://www.apache.org/licenses/LICENSE-2.0"
| "instance variables"  |
| "class pool variables"  |
| "shared pool variables"  |
'as yet unclassified'
fib25 = (
	| fib |
	fib := nil.
	fib := [:n | n < 2 ifTrue: [1] ifFalse: [(fib value: n-1) + (fib value: n-2)]].
	fib value: 25.
)
run = (
	self fib25
)) : (
| "class instance variables"  |
)

'Benchmarks-DeltaBlue'
class SmalltalkDeltaBlue = Benchmark (
""
| "instance variables"  |
| "class pool variables"  |
| "shared pool variables"  |
'as yet unclassified'
run = (
	DBThePlanner chainTest: 100.
	DBThePlanner projectionTest: 100.
)
setup = (
)) : (
| "class instance variables"  |
)

'Benchmarks-Microbenchmarks'
class SmalltalkFieldRead = Benchmark (
"A microbenchmark stressing reads of slots.

Copyright 2012 Google Inc.

Licensed under the Apache License, Version 2.0 (the ''License''); you may not use this file except in compliance with the License.  You may obtain a copy of the License at  http://www.apache.org/licenses/LICENSE-2.0"
| "instance variables" bar  |
| "class pool variables"  |
| "shared pool variables"  |
'as yet unclassified'
run = (
	bar := 'something'.
	1 to: 100000 do: [:x|
		bar. bar. bar. bar. bar.
		bar. bar. bar. bar. bar.].
)) : (
| "class instance variables"  |
)

'Benchmarks-Microbenchmarks'
class SmalltalkFieldWrite = Benchmark (
"A microbenchmark stressing writes to slots.

Copyright 2012 Google Inc.

Licensed under the Apache License, Version 2.0 (the ''License''); you may not use this file except in compliance with the License.  You may obtain a copy of the License at  http://www.apache.org/licenses/LICENSE-2.0"
| "instance variables" bar  |
| "class pool variables"  |
| "shared pool variables"  |
'as yet unclassified'
run = (
	| something |
	something := 'something'.
	1 to: 100000 do: [:x|
		bar := something. bar := something. bar := something. bar := something. bar := something.
		bar := something. bar := something. bar := something. bar := something. bar := something.].
)) : (
| "class instance variables"  |
)

'Benchmarks-Microbenchmarks'
class SmalltalkMethodFibonacci = Benchmark (
"A microbenchmark stressing method invocations and integer arithmetic.

Copyright 2012 Google Inc.

Licensed under the Apache License, Version 2.0 (the ''License''); you may not use this file except in compliance with the License.  You may obtain a copy of the License at  http://www.apache.org/licenses/LICENSE-2.0"
| "instance variables"  |
| "class pool variables"  |
| "shared pool variables"  |
'as yet unclassified'
fib: n = (
	^n < 2 ifTrue: [1] ifFalse: [(self fib: n-1) + (self fib: n-2)]
)
run = (
	self fib: 25
)) : (
| "class instance variables"  |
)

'Benchmarks-Microbenchmarks'
class SmalltalkNLRImmediate = Benchmark (
"A microbenchmark stressing non-local returns.

Copyright 2012 Google Inc.

Licensed under the Apache License, Version 2.0 (the ''License''); you may not use this file except in compliance with the License.  You may obtain a copy of the License at  http://www.apache.org/licenses/LICENSE-2.0"
| "instance variables"  |
| "class pool variables"  |
| "shared pool variables"  |
'as yet unclassified'
nlr = (
	self run: [^2].
	^1
)
run = (
	1 to: 10000 do: [:i | self nlr].
)
run: block = (
	block value
)) : (
| "class instance variables"  |
)

'Benchmarks-Microbenchmarks'
class SmalltalkNLRLoop = Benchmark (
"A microbenchmark stressing non-local returns.

Copyright 2012 Google Inc.

Licensed under the Apache License, Version 2.0 (the ''License''); you may not use this file except in compliance with the License.  You may obtain a copy of the License at  http://www.apache.org/licenses/LICENSE-2.0"
| "instance variables" oneThroughSix  |
| "class pool variables"  |
| "shared pool variables"  |
'as yet unclassified'
nlr = (
	oneThroughSix do: [:each | each = 4 ifTrue: [^each]].
)
run = (
	oneThroughSix := {1. 2. 3. 4. 5. 6}.
	1 to: 10000 do: [:i | self nlr].
)) : (
| "class instance variables" oneThroughSix  |
)

'Benchmarks-ParserCombinators'
class SmalltalkParserCombinators = Benchmark (
""
| "instance variables" seed parser theExpression  |
| "class pool variables"  |
| "shared pool variables"  |
'as yet unclassified'
nextRandom = (
	seed := seed * 16rDEAD + 16rC0DE.
	seed := seed bitAnd: 16rFFF.
	^seed
)
randomExpression: depth = (
	| m |
	depth < 1 ifTrue: [^(self nextRandom rem: 10) printString].
	m := self nextRandom rem: 3.
	m = 0 ifTrue: [^(self randomExpression: depth-1),'+',(self randomExpression: depth-1)].
	m = 1 ifTrue: [^(self randomExpression: depth-1),'*',(self randomExpression: depth-1)].
	m = 2 ifTrue: [^'(',(self randomExpression: depth-1),')'].
	self halt.
)
setup = (
	seed := 16rCAFE.
	parser := PCSimpleExpressionGrammar new start compress.
	theExpression := self randomExpression: 20.
	self assert: [theExpression size = 41137] message: 'Generated expression of the wrong size'.
	self assert: [(parser parseWithContext: (PCParserContext new over: theExpression) ifError: [self parseFailed]) = 31615] message: 'Expression evaluated to wrong value'
)'as-yet-unclassified'
run = (
	parser parseWithContext: (PCParserContext new over: theExpression) ifError: [self parseFailed].
)) : (
| "class instance variables"  |
)

'Benchmarks-Richards'
class SmalltalkRichards = Benchmark (
""
| "instance variables"  |
| "class pool variables"  |
| "shared pool variables"  |
'as yet unclassified'
initialize = (
	DATA_SIZE := 4.
	COUNT := 1000.

	ID_IDLE := 1.
	ID_WORKER := 2.
	ID_HANDLER_A := 3.
	ID_HANDLER_B := 4.
	ID_DEVICE_A := 5.
	ID_DEVICE_B := 6.
	NUMBER_OF_IDS := 6.

	KIND_DEVICE := 0.
	KIND_WORK := 1.
	
	"The task is running and is currently scheduled."
	STATE_RUNNING := 0.
	
	"The task has packets left to process."
	STATE_RUNNABLE := 1.
	
	"The task is not currently running. The task is not blocked as such and may be started by the scheduler."
	STATE_SUSPENDED := 2.
	
	"The task is blocked and cannot be run until it is explicitly released."
	STATE_HELD := 4.
	STATE_SUSPENDED_RUNNABLE := STATE_SUSPENDED bitOr: STATE_RUNNABLE.
	STATE_NOT_HELD := STATE_HELD bitInvert.
)'as-yet-unclassified'
run = (
	| scheduler queue |
	
	scheduler := RScheduler new.
	scheduler addIdleTask: ID_IDLE priority: 0 work: nil state: COUNT.
	queue := RPacket link: nil identity: ID_WORKER kind: KIND_WORK.
	queue := RPacket link: queue identity: ID_WORKER kind: KIND_WORK.
    	scheduler addWorkerTask: ID_WORKER priority: 1000 work: queue.

	queue := RPacket link: nil identity: ID_DEVICE_A kind: KIND_DEVICE.
	queue := RPacket link: queue identity: ID_DEVICE_A kind: KIND_DEVICE.
	queue := RPacket link: queue identity: ID_DEVICE_A kind: KIND_DEVICE.
	scheduler addHandlerTask: ID_HANDLER_A priority: 2000 work: queue.

	queue := RPacket link: nil identity: ID_DEVICE_B kind: KIND_DEVICE.
	queue := RPacket link: queue identity: ID_DEVICE_B kind: KIND_DEVICE.
	queue := RPacket link: queue identity: ID_DEVICE_B kind: KIND_DEVICE.
	scheduler addHandlerTask: ID_HANDLER_B priority: 3000 work: queue.

	scheduler addDeviceTask: ID_DEVICE_A priority: 4000 work: nil.

	scheduler addDeviceTask: ID_DEVICE_B priority: 5000 work: nil.

	scheduler schedule.

	scheduler queueCount = 2322
		ifFalse: [Error signal: 'bad scheduler queue-count'].
	scheduler holdCount = 928
		ifFalse: [Error signal: 'bad scheduler hold-count'].
)) : (
| "class instance variables"  |
)

'Benchmarks-Microbenchmarks'
class SmalltalkSlotRead = Benchmark (
"A microbenchmark stressing reads of slots.

Copyright 2014 Google Inc.

Licensed under the Apache License, Version 2.0 (the ''License''); you may not use this file except in compliance with the License.  You may obtain a copy of the License at  http://www.apache.org/licenses/LICENSE-2.0"
| "instance variables" bar  |
| "class pool variables"  |
| "shared pool variables"  |
'as yet unclassified'
bar = (
	^bar
)
bar: v = (
	bar := v
)
run = (
	self bar: 'something'.
	1 to: 100000 do: [:x|
		self bar. self bar. self bar. self bar. self bar.
		self bar. self bar. self bar. self bar. self bar.].
)) : (
| "class instance variables"  |
)

'Benchmarks-Microbenchmarks'
class SmalltalkSlotWrite = Benchmark (
"A microbenchmark stressing writes to slots.

Copyright 2014 Google Inc.

Licensed under the Apache License, Version 2.0 (the ''License''); you may not use this file except in compliance with the License.  You may obtain a copy of the License at  http://www.apache.org/licenses/LICENSE-2.0"
| "instance variables" bar  |
| "class pool variables"  |
| "shared pool variables"  |
'as yet unclassified'
bar = (
	^bar
)
bar: v = (
	bar := v
)
run = (
	| something |
	something := 'something'.
	1 to: 100000 do: [:x |
		self bar: something. self bar: something. self bar: something. self bar: something. self bar: something.
		self bar: something. self bar: something. self bar: something. self bar: something. self bar: something.].
)) : (
| "class instance variables"  |
)

'Benchmarks-Splay'
class SmalltalkSplay = Benchmark (
""
| "instance variables" tree random  |
| "class pool variables" TreeModifications TreePayloadDepth TreeSize  |
| "shared pool variables"  |
'as yet unclassified'
insertNewNode = ( "^<Number>"
	| key payload |
	[key := random next.
	(tree at: key) == nil] whileFalse.
	payload := SPayload generate: TreePayloadDepth with: key printString.
	tree at: key put: payload.
	^key
)
run = (
	"Replace a few nodes in the splay tree."
	TreeModifications timesRepeat: 
		[ | key greatest |
		key := self insertNewNode. 
		greatest := tree findGreatestLessThan: key.
		greatest == nil 
			ifTrue: [tree removeKey: key]
			ifFalse: [tree removeKey: greatest key]].
)
setup = (
	tree := SSplayTree new.
	random := Random new.
	TreeSize timesRepeat: [self insertNewNode].
)) : (
| "class instance variables"  |
'as yet unclassified'
initialize = (
	"SSplay initialize"
	TreeSize := 8000.
	TreeModifications := 80.
	TreePayloadDepth := 5.
))

)