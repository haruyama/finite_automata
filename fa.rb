# -*- encoding: utf-8 -*-

require 'set'
require 'graphviz'


class FA

end

class DFA

  def initialize(states, symbols, initial, acceptings)
    @states     = states
    @symbols    = symbols
    @initial    = initial
    @acceptings = acceptings
  end

  def process(inputs)
    s = @initial
    inputs.each_char { |i|
      s = s.process(i)
      return false unless s
    }

    if @acceptings.include? s
      return true
    else
      return false
    end
  end

  def to_graph(options = {})
    g = GraphViz.new( :G, :type => :digraph )
    nodes = @states.map{ |s|
      if s == @initial
        g.add_nodes(s.to_s, :style => 'dashed')
      elsif @acceptings.include? s
        g.add_nodes(s.to_s, :peripheries => '2')
      end
      g.add_nodes(s.to_s)
    }

    transposed_states = {}
    @states.each_index { |i|
      transposed_states[@states[i]] = i
    }

    @states.each_index { |i|
      @states[i].function.each { |symbol, state|
        g.add_edges(nodes[i], nodes[transposed_states[state]], :label => symbol)
      }
    }

    if !options.empty?
      return g.output(options)
    else
      return g.output( :dot => String )
    end

  end
end

class DFAState
  attr_accessor :function
  attr_reader   :name

  def initialize(name = 'dummy')
    @name = name
  end

  def to_s
    'DS: ' + @name
  end

  def process(input)
    @function[input]
  end

  def <=>(o)
    @name <=> o.name
  end
end

SYMBOL_E = 'ε'

class NFA

  attr_reader :symbols

  def initialize(states, symbols, initial, acceptings)
    @states     = states
    @symbols    = symbols
    @initial    = initial
    @acceptings = acceptings
  end

  def get_epsilon_closure(states)
    result = SortedSet.new(states)
    states = states.to_a

    while !states.empty?
      s = states.shift
      if s.has_move?(SYMBOL_E)
        s.function[SYMBOL_E].each { |t|
          if !result.include? t
            result << t
            states << t
          end
        }
      end
    end
    result.to_a
  end

  def create_dfa_acceptiongs(dfa_hash)
    dfa_acceptings = SortedSet.new
    @acceptings.each { |a|
      dfa_hash.each { |k, v|
        dfa_acceptings << v if k.include? a
      }
    }
    dfa_acceptings
  end

  def to_dfa
    dfa_states = {}
    nfas_initial = get_epsilon_closure([@initial])
    dfa_initial = DFAState.new(nfas_initial.to_a.to_s)
    dfa_states[nfas_initial] = dfa_initial

    unprocessed_nfa_states = [nfas_initial]

    while !unprocessed_nfa_states.empty?
      nfas = unprocessed_nfa_states.shift
      dfa = dfa_states[nfas]

      function = {}
      @symbols.each { |sym|
        movable_states = nfas.inject(SortedSet.new) { |states, nfa|
          if nfa.has_move?(sym)
            states + nfa.function[sym]
          else
            states
          end
        }
        movable_states = get_epsilon_closure(movable_states)
        if !dfa_states.key?(movable_states)
          dfa_states[movable_states] = DFAState.new(movable_states.to_a.to_s)
          unprocessed_nfa_states << movable_states
        end
        function[sym] = dfa_states[movable_states]
      }
      dfa.function = function
    end
    DFA.new(dfa_states.values, @symbols, dfa_initial, create_dfa_acceptiongs(dfa_states))
  end

  def to_graph(options = {})
    g = GraphViz.new( :G, :type => :digraph )
    nodes = @states.map{ |s|
      if s == @initial
        g.add_nodes(s.to_s, :style => 'dashed')
      elsif @acceptings.include? s
        g.add_nodes(s.to_s, :peripheries => '2')
      end
      g.add_nodes(s.to_s)
    }

    transposed_states = {}
    @states.each_index { |i|
      transposed_states[@states[i]] = i
    }

    @states.each_index { |i|
      @states[i].function.each { |symbol, ss|
        ss.each { |state|
          g.add_edges(nodes[i], nodes[transposed_states[state]], :label => symbol)
        }
      }
    }

    if !options.empty?
      return g.output(options)
    else
      return g.output( :dot => String )
    end

  end

end

class NFAState
  attr_accessor :function
  attr_reader :name

  def initialize(name = 'dummy')
    @name = name
    @function = {}
  end

  def to_s
    'NS: ' + @name
  end

  def has_move?(input)
    @function.key?(input)
  end

  def <=>(o)
    @name <=> o.name
  end

end
