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

  def to_graph
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

    g.output( :dot => String )

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

  def get_states_can_be_e_moved(states)
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

  def convert_to_dfa
    dfa_hash = {}
    nfas_initial = get_states_can_be_e_moved([@initial])
    dfa_initial = DFAState.new(nfas_initial.to_a.to_s)
    dfa_hash[nfas_initial] = dfa_initial

    unprocessed_nfas = [nfas_initial]

    while !unprocessed_nfas.empty?
      nfas = unprocessed_nfas.shift
      dfa = dfa_hash[nfas]

      function = {}
      @symbols.each { |sym|
        states_can_be_moved = nfas.inject(SortedSet.new) { |states, nfa|
          if nfa.has_move?(sym)
            states + nfa.function[sym]
          else
            states
          end
        }
        states_can_be_moved = get_states_can_be_e_moved(states_can_be_moved)
        if !dfa_hash.key?(states_can_be_moved)
          dfa_hash[states_can_be_moved] = DFAState.new(states_can_be_moved.to_a.to_s)
          unprocessed_nfas << states_can_be_moved
        end
        function[sym] = dfa_hash[states_can_be_moved]
      }
      dfa.function = function
    end
    DFA.new(dfa_hash.values, @symbols, dfa_initial, create_dfa_acceptiongs(dfa_hash))
  end

  def to_graph
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

    g.output( :dot => String )

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
