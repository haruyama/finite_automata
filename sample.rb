#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

require './regexp.rb'


r = MyRegexp.new('(a+ab)*a')

require 'pp'

pp r.gnfa

print r.nfa.to_graph

print r.dfa.to_graph

r.nfa.to_graph(:png => 'nfa.png')

r.dfa.to_graph(:png => 'dfa.png')
