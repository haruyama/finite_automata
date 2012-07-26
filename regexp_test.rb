#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

require 'minitest/unit'
require './regexp.rb'

MiniTest::Unit.autorun

class TestFa < MiniTest::Unit::TestCase

  def test_regexp_001
    r = MyRegexp.new('a')
    assert_same false, r.match('')
    assert_same true,  r.match('a')
    assert_same false, r.match('aa')
    assert_same false, r.match('aaa')
  end

  def test_regexp_002
    r = MyRegexp.new('a+b')
    assert_same false, r.match('')
    assert_same true,  r.match('a')
    assert_same false, r.match('aa')
    assert_same true,  r.match('b')
    assert_same false, r.match('ab')
    assert_same false, r.match('bb')
  end

  def test_regexp_003
    r = MyRegexp.new('a*')
    assert_same true,  r.match('')
    assert_same true,  r.match('a')
    assert_same true,  r.match('aa')
    assert_same false, r.match('b')
    assert_same false, r.match('ab')
    assert_same false, r.match('bb')
  end

  def test_regexp_004
    r = MyRegexp.new('ab')
    assert_same false, r.match('')
    assert_same false, r.match('a')
    assert_same false, r.match('aa')
    assert_same false, r.match('b')
    assert_same true,  r.match('ab')
    assert_same false, r.match('bb')
    assert_same false, r.match('aba')
  end

  def test_regexp_005
    r = MyRegexp.new('a*+b')
    assert_same true, r.match('')
    assert_same true, r.match('a')
    assert_same true, r.match('aa')
    assert_same true, r.match('b')
    assert_same false, r.match('ab')
    assert_same false, r.match('bb')
    assert_same false, r.match('aba')
  end

  def test_regexp_006
    r = MyRegexp.new('(a*+b)')
    assert_same true, r.match('')
    assert_same true, r.match('a')
    assert_same true, r.match('aa')
    assert_same true, r.match('b')
    assert_same false, r.match('ab')
    assert_same false, r.match('bb')
    assert_same false, r.match('aba')
  end

  def test_regexp_007
    r = MyRegexp.new('(a*+b)a')
    assert_same false, r.match('')
    assert_same true, r.match('a')
    assert_same true, r.match('aa')
    assert_same false, r.match('b')
    assert_same false, r.match('ab')
    assert_same false, r.match('bb')
    assert_same false, r.match('aba')
    assert_same true,  r.match('ba')
  end

  def test_regexp_008
    r = MyRegexp.new('a(a*+b)')
    assert_same false, r.match('')
    assert_same true,  r.match('a')
    assert_same true,  r.match('aa')
    assert_same true,  r.match('aaa')
    assert_same false, r.match('b')
    assert_same true,  r.match('ab')
    assert_same false, r.match('bb')
    assert_same false, r.match('aba')
    assert_same false, r.match('ba')
  end

  def test_regexp_009
    r = MyRegexp.new('(a+ab)*a')
    assert_same false, r.match('')
    assert_same true,  r.match('a')
    assert_same true,  r.match('aa')
    assert_same true,  r.match('aaa')
    assert_same false, r.match('b')
    assert_same false, r.match('ab')
    assert_same true,  r.match('aba')
    assert_same false, r.match('bb')
    assert_same false, r.match('ba')
  end

  def test_regexp_010
    r = MyRegexp.new('abc')
    assert_same false, r.match('')
    assert_same false,  r.match('a')
    assert_same false,  r.match('ab')
    assert_same true,  r.match('abc')
    assert_same false, r.match('abca')
  end

  def test_regexp_011
    r = MyRegexp.new('(a+b)+c')
    assert_same false, r.match('')
    assert_same true,  r.match('a')
    assert_same false,  r.match('ab')
    assert_same false,  r.match('abc')
    assert_same true,  r.match('b')
    assert_same true,  r.match('c')
    assert_same false,  r.match('d')
  end

  def test_regexp_012
    r = MyRegexp.new('a+b+c')
    assert_same false, r.match('')
    assert_same true,  r.match('a')
    assert_same false,  r.match('ab')
    assert_same false,  r.match('abc')
    assert_same true,  r.match('b')
    assert_same true,  r.match('c')
    assert_same false,  r.match('d')
  end
end

