#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

require 'parslet'
include Parslet

class RegexpParser < Parslet::Parser
  # Single character rules
  rule(:lparen)     { str('(') }
  rule(:rparen)     { str(')') }
  rule(:plus)       { str('+') }
  rule(:star)       { str('*') }

  rule(:symbol)     { match['a-z'] }

  rule(:value)      { symbol | lparen >> expression >> rparen }

  rule(:closure)    { value.as(:value) >> star.maybe.as(:star) }

  rule(:conjunction)    { closure.as(:clos) >> ( str('') >> closure.as(:clos) ).repeat }

  rule(:union)      { conjunction.as(:conj) >> ( plus >> conjunction.as(:conj)).repeat }

  rule(:expression) { union.as(:union) }

  root :expression
end

$counter = 0

class Value < Struct.new(:value)
  def convert(s, f, states, symbols)
    if value.is_a? Slice
      s.function[value.to_s] ||= []
      s.function[value.to_s] << f
      symbols << value.to_s
      return [s, f, states, symbols]
    else
      return value.convert(s, f, states, symbols)
    end
  end
end

class Closure < Struct.new(:exp)
  def convert(s, f, states, symbols)
    im = NFAState.new('CLOSURE:' + $counter.to_s)
    $counter += 1
    s.function[SYMBOL_E] ||= []
    s.function[SYMBOL_E] << im
    im.function = { SYMBOL_E => [f]}
    if exp.is_a? Slice
      im.function[exp.to_s] = [im]
      symbols << exp.to_s
    else
      exp.convert(im, im, states, symbols)
    end
    states << im
    [s, f, states, symbols]
  end
end

class Conjunction < Struct.new(:left, :right);
  def convert(s, f, states, symbols)
    im = NFAState.new('CONJECTION: ' + $counter.to_s)
    $counter += 1
    left.convert(s, im, states, symbols)
    right.convert(im, f, states, symbols)
    states << im
    [s, f, states, symbols]
  end
end

class Union < Struct.new(:left, :right)
  def convert(s, f, states, symbols)
    left.convert(s, f, states, symbols)
    right.convert(s, f, states, symbols)
    [s, f, states, symbols]
  end
end

def make_conj_tree(conjunctions)
  if conjunctions.size == 1
    return conjunctions[0]
  elsif conjunctions.size == 2
    return Conjunction.new(conjunctions[0], conjunctions[1])
  end
  Conjunction.new(conjunctions[0], make_conj_tree(conjunctions[1..-1]))
end

def make_union_tree(unions)
  if unions.size == 1
    return unions[0]
  elsif unions.size == 2
    return Union.new(unions[0], unions[1])
  end
  Union.new(unions[0], make_union_tree(unions[1..-1]))
end

class RegexpTransformer < Parslet::Transform
  rule(:value => subtree(:value),
       :star => '*')  { Closure.new(value) }
  rule(:value => subtree(:value),
       :star => nil)  { Value.new(value) }
  rule( :clos => subtree(:clos) ) { clos }
  rule( :conj => simple(:conj) ) { conj }
  rule( :union => simple(:union) ) { union }
  rule( :conj => sequence(:conj) ) { make_conj_tree(conj) }
  rule( :union => sequence(:union) ) { make_union_tree(union) }
end
