#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

require './fa.rb'
require './parse.rb'
require 'set'

class MyRegexp
  attr_reader :gnfa, :nfa, :dfa
  def initialize(str)
    parser = MyRegexpParser.new
    transf = MyRegexpTransform.new
    @gnfa = transf.apply( parser.parse(str))
    s = NFAState.new('s')
    f = NFAState.new('f')
    s, f, set, symbols = gnfa.convert(s, f, [s, f], Set.new)
    @nfa = NFA.new(set.uniq.sort, symbols.to_a, s, [f])
    @dfa = @nfa.to_dfa
  end

  def match(str)
    @dfa.process(str)
  end
end
