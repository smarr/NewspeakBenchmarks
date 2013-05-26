
/* A macrobenchmark based on the Newspeak's CombinatorialParsing. This benchmark parses and evaluates a fixed string with a simple arithmetic expression grammar. These parser combinators use explicitly initialized forward reference parsers rather than mirrors to handle the cycles in the productions. They also do not use of any platform streams to avoid API differences.It was expected that the bottleneck would be the non-local returns, or rather their translation as exceptions in Java/Dart/JavaScript. AFAWK, Hotspot optimizes exceptions but DartVM and V8 do not, so we expected Hotspot to outperform the others. Instead, we find V8 as the strong leader, for reasons we do not understand.This benchmark is derived from the Newspeak version of CombinatorialParsers, which is why the Cadence copyrights apply.Copyright 2008 Cadence Design Systems, Inc.Copyright 2012 Cadence Design Systems, Inc.Copyright 2013 Ryan Macnak   Licensed under the Apache License, Version 2.0 (the ''License''); you may not use this file except in compliance with the License.  You may obtain a copy of the License at  http://www.apache.org/licenses/LICENSE-2.0 */

main(){
		CombinatorialParser p = new SimpleExpressionGrammar().start.compress();
		String theExpression = randomExpression(20);

		if(theExpression.length!=41137) throw "Generated expression of the wrong size";
		if(p.parseWithContext(new ParserContext(theExpression))!=31615) throw "Expression evaluated to wrong value";
		
		// Warm-up
		p.parseWithContext( new ParserContext(theExpression) );
		p.parseWithContext( new ParserContext(theExpression) );
		p.parseWithContext( new ParserContext(theExpression) );

		// Measure for at least 10 seconds
		num startTime = new DateTime.now().millisecondsSinceEpoch;
		num duration;
		int runs = 0;
		do{
			p.parseWithContext( new ParserContext(theExpression) );
			runs++;
			duration = new DateTime.now().millisecondsSinceEpoch - startTime;
		}while(duration < 10000);
		
		print("score="+(runs*1000.0/duration).toString());
}
		
	int seed = 0xCAFE;
	int nextRandom(){
		seed = seed * 0xDEAD + 0xC0DE;
		seed = seed & 0x0FFF;
		return seed;
	}
	String randomExpression(int depth){
		if(depth<1) return (nextRandom()%10).toString();
		switch(nextRandom()%3){
			case 0: return randomExpression(depth-1)+"+"+randomExpression(depth-1);
			case 1: return randomExpression(depth-1)+"*"+randomExpression(depth-1);
			case 2: return "("+randomExpression(depth-1)+")";
		}
		return null;
	}

class ParserContext {
	 String content;
	 int pos;
	ParserContext(String s){
		content = s;
		pos = 0;
	}
	get position {
		return pos;
	}
	set position(int p){
		pos = p;
	}
	char next(){
		return content[pos++];
	}
	boolean atEnd(){
		return pos >= content.length;
	}
}

class ParserError implements Exception {	
}

abstract class CombinatorialParser {
	boolean compressed = false;
	Object parseWithContext(ParserContext ctxt){
		throw new RuntimeException("subclass responsibility"+this);
	}
	void bind(CombinatorialParser p){
		throw new RuntimeException("subclass responsibility"+this);
	}
	CombinatorialParser compress(){
		throw new RuntimeException("subclass responsibility"+this);
	}
	CombinatorialParser then(CombinatorialParser p) {
		return new SequencingParser( [this, p] );
	}
	CombinatorialParser character(char c){
		return new CharacterRangeParser(c,c);
	}
	CombinatorialParser characterRange(char p, char q){
		return new CharacterRangeParser(p,q);
	}
	CombinatorialParser eoi(){
		return new EOIParser();
	}
	CombinatorialParser star(){
		return new StarParser(this);
	}
	CombinatorialParser wrap(Transform t){
		return new WrappingParser(this, t);
	}
	CombinatorialParser or(CombinatorialParser q){
		return new AlternatingParser(this, q);
	}
}

class CharacterRangeParser extends CombinatorialParser {
	char lowerBound;
	char upperBound;
	CharacterRangeParser(char p, char q){
		lowerBound = p;
		upperBound = q;
	}
	Object parseWithContext(ParserContext ctxt){
		if(!ctxt.atEnd()){
			char c = ctxt.next();
			if( lowerBound.compareTo(c)<=0 && c.compareTo(upperBound)<=0 ){
				return c;
			}
		}
		throw new ParserError();
	}
	CombinatorialParser compress(){
		return this;
	}
}

class SequencingParser extends CombinatorialParser {
	List<CombinatorialParser> subparsers;
	SequencingParser(List<CombinatorialParser> subparsers){
		this.subparsers = subparsers;
	}
	CombinatorialParser then(CombinatorialParser p){
		List<CombinatorialParser> l = subparsers.toList(growable:true);
		l.add(p);
		return new SequencingParser(l);
	}
	Object parseWithContext(ParserContext ctxt){
		return subparsers.map((p)=>p.parseWithContext(ctxt)).toList(growable:false);
	}
	CombinatorialParser compress(){
		if(compressed) return this;
		compressed = true;
		for(int i=0; i<subparsers.length; i++){
			subparsers[i] = subparsers[i].compress();
		}
		return this;
	}
}

class AlternatingParser extends CombinatorialParser {
	CombinatorialParser p, q;
	AlternatingParser(CombinatorialParser p, CombinatorialParser q){
		this.p = p;
		this.q = q;
	}
	Object parseWithContext(ParserContext ctxt){
		int pos = ctxt.position;
		try {
			return p.parseWithContext(ctxt);
		} on ParserError catch (e) {
			ctxt.position = pos;
			return q.parseWithContext(ctxt);
		}
	}
	CombinatorialParser compress(){
		if(compressed) return this;
		compressed = true;
		p = p.compress();
		q = q.compress();
		return this;
	}
}

class StarParser extends CombinatorialParser {
	CombinatorialParser p;
	StarParser(CombinatorialParser p){
		this.p = p;
	}
	Object parseWithContext(ParserContext ctxt){
		List l = new List();
		for(;;){
			int pos = ctxt.position;
			try {
				l.add( p.parseWithContext(ctxt) );
			} on ParserError catch(e) {
				ctxt.position = pos;
				return l.toList(growable:false);
			}
		}
	}
	CombinatorialParser compress(){
		if(compressed) return this;
		compressed = true;
		p = p.compress();
		return this;
	}
}

class EOIParser extends CombinatorialParser {
	Object parseWithContext(ParserContext ctxt){
		if(ctxt.atEnd()) return null;
		throw new ParserError();
	}
	CombinatorialParser compress(){
		return this;
	}
}

class WrappingParser extends CombinatorialParser {
	CombinatorialParser p;
	Function t;
	WrappingParser(CombinatorialParser p, Function t){
		this.p = p;
		this.t = t;
	}
	Object parseWithContext(ParserContext ctxt){
		return t( p.parseWithContext(ctxt) );
	}
	CombinatorialParser compress(){
		if(compressed) return this;
		compressed = true;
		p = p.compress();
		return this;
	}
}

class ForwardReferenceParser extends CombinatorialParser {
	CombinatorialParser forwardee;
	void bind(CombinatorialParser p){
		if(forwardee!=null) throw new RuntimeException("already bound");
		forwardee = p;
	}
	CombinatorialParser compress(){
		return forwardee.compress();
	}
	Object parseWithContext(ParserContext ctxt){
		throw new RuntimeException("I should have been compressed away");
	}
}

class SimpleExpressionGrammar extends CombinatorialParser {

	CombinatorialParser start = new ForwardReferenceParser();
	CombinatorialParser exp = new ForwardReferenceParser();
	CombinatorialParser e1 = new ForwardReferenceParser();
	CombinatorialParser e2 = new ForwardReferenceParser();
	
	CombinatorialParser parenExp = new ForwardReferenceParser();
	CombinatorialParser number = new ForwardReferenceParser();
	
	CombinatorialParser plus = new ForwardReferenceParser();
	CombinatorialParser times = new ForwardReferenceParser();
	CombinatorialParser digit = new ForwardReferenceParser();
	CombinatorialParser lparen = new ForwardReferenceParser();
	CombinatorialParser rparen = new ForwardReferenceParser();
	
	SimpleExpressionGrammar(){
		start.bind(exp.then(eoi()).wrap(
		  (o){return o[0];} ));
		
		exp.bind(e1.then(plus.then(e1).star()).wrap(
      (o){
			int lhs = o[0];
			Object rhss = o[1];
			rhss.forEach( (rhs){lhs = (lhs + rhs[1]) % 0xFFFF;} );
			return lhs;} ));
		
		e1.bind(e2.then(times.then(e2).star()).wrap(
			(o){
			int lhs = o[0];
			Object rhss = o[1];
			rhss.forEach( (rhs){lhs = (lhs * rhs[1]) % 0xFFFF;} );
			return lhs;} ));
		
		e2.bind( number.or(parenExp) );

		parenExp.bind( lparen.then(exp).then(rparen).wrap(
		  (o){return o[1];} ));
				
		number.bind( digit.wrap(
		 (o){ return int.parse(o); } ));
		
		plus.bind(character('+'));
		times.bind(character('*'));
		digit.bind(characterRange('0','9'));
		lparen.bind(character('('));
		rparen.bind(character(')'));
	}
}
