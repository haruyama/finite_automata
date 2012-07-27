#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

require 'parslet'
include Parslet

class MyRegexpParser < Parslet::Parser
  # Single character rules
  rule(:lparen)     { str('(') }
  rule(:rparen)     { str(')') }
  rule(:plus)       { str('+') }
  rule(:star)       { str('*') }

  rule(:symbol)     { match['a-z'] }

  rule(:value)      { symbol | lparen >> expression >> rparen }

  rule(:kleene_star)    { value.as(:value) >> star.maybe.as(:star) }

  rule(:concatenation)    { kleene_star.as(:kleene_star) >> ( str('') >> kleene_star.as(:kleene_star) ).repeat }

  rule(:union)      { concatenation.as(:concat) >> ( plus >> concatenation.as(:concat)).repeat }

  rule(:expression) { union.as(:union) }

  root :expression
end


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

class KleeneStar < Struct.new(:exp)
  @@counter = 0
  def convert(s, f, states, symbols)
    im = NFAState.new('KLEENE STAR: ' + @@counter.to_s)
    @@counter += 1
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

class Concatenation < Struct.new(:left, :right);
  @@counter = 0
  def convert(s, f, states, symbols)
    im = NFAState.new('CONCATENATION: ' + @@counter.to_s)
    @@counter += 1
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

def make_concat_tree(concatenations)
  if concatenations.size == 1
    return concatenations[0]
  elsif concatenations.size == 2
    return Concatenation.new(concatenations[0], concatenations[1])
  end
  Concatenation.new(concatenations[0], make_concat_tree(concatenations[1..-1]))
end

def make_union_tree(unions)
  if unions.size == 1
    return unions[0]
  elsif unions.size == 2
    return Union.new(unions[0], unions[1])
  end
  Union.new(unions[0], make_union_tree(unions[1..-1]))
end

class MyRegexpTransform < Parslet::Transform
  rule(:value => subtree(:value),
       :star => '*')  { KleeneStar.new(value) }
  rule(:value => subtree(:value),
       :star => nil)  { Value.new(value) }
  rule( :kleene_star => subtree(:kleene_star) ) { kleene_star}
  rule( :concat => simple(:concat) ) { concat }
  rule( :union => simple(:union) ) { union }
  rule( :concat => sequence(:concat) ) { make_concat_tree(concat) }
  rule( :union => sequence(:union) ) { make_union_tree(union) }
end
