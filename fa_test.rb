#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

require 'minitest/unit'
require './fa.rb'

MiniTest::Unit.autorun

class TestFa < MiniTest::Unit::TestCase

  def test_dfa
    r = DFAState.new('r')
    s = DFAState.new('s')

    r.function = {'0' => r, '1' => s}
    s.function = {'0' => s, '1' => r}

    dfa = DFA.new([r, s], ['0', '1'], r, [s])

    assert_same true,  dfa.process('1011')
    assert_same false,  dfa.process('110')

#     print dfa.to_graph
  end

  def test_nfa
    r = NFAState.new('r')
    s = NFAState.new('s')
    t = NFAState.new('t')

    r.function = {'0' => [r], SYMBOL_E => [s]}
    s.function = {'1' => [s], SYMBOL_E => [t]}
    t.function = {'2' => [t], SYMBOL_E => [t]}

    nfa = NFA.new([r, s, t], ['0', '1', '2'], r, [t])

    assert_equal [r, s, t], nfa.get_epsilon_closure([r])
    assert_equal [s, t],    nfa.get_epsilon_closure([s])
    assert_equal [t],       nfa.get_epsilon_closure([t])

    dfa = nfa.to_dfa

    assert_same true, dfa.process('012')
    assert_same false, dfa.process('021')

  end
end

