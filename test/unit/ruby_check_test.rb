require File.dirname(__FILE__) + '/../test_helper'

class RubyCheckTest < Test::Unit::TestCase
  
  def test_all
    test(%q{"#{link_to} and #{image_tag}"})
    test(%q{"#{link_to('image.gif')} and #{image_tag}"})
    test(%q{"#{foo1} and #{foo2}"}, ["Bad call to 'foo1'", "Bad call to 'foo2'"])
    test("image_tag('test.gif')")
    test("`dir`", ["Bad call to 'dir`'"])
    test("image_tag(`cd`)", ["Bad call to 'cd`'"])
    test(%q{image_tag("#{$_}")}, ["Bad call to '$_'"])
    test("image_tag_foo('test.gif')", ["Bad call to 'image_tag_foo'"])
    test("link_to(image_tag('test.gif'), :action => 'show')")
    test(%q{link_to(image_tag("test#{File.read('secret')}.gif"), :action => 'show')}, ["Bad call to 'File'", "Bad call to 'read'"])
    test(%q{link_to(image_tag('test.gif', "#{evil}"), :action => 'show')}, ["Bad call to 'evil'"])
    test(%q{link_to(image_tag('test.gif'), :action => "#{evil_action}")}, ["Bad call to 'evil_action'"])
    test(%q{link_to(image_tag('test.gif'), :action => evil_action)}, ["Bad call to 'evil_action'"])
    test(%q{link_to(image_tag("#{evil1}test.gif"), :action => "#{evil2}")}, ["Bad call to 'evil1'", "Bad call to 'evil2'"])
    test(%q{"#{link_to(system('dir'))}"}, ["Bad call to 'system'"])
    test("if image_tag('test.gif')")
    test("else")
    test("end")
    test("end system('evil call')", ["Bad call to 'system'"])
    test("def", ["Bad keyword 'def'"])
    test("module EvilModule", ["Bad keyword 'module '"])
    test("include EvilModule", ["Bad call to 'include'", "Bad call to 'EvilModule'"])
    test("require 'evil_module'", ["Bad call to 'require'"])
    test("@variable'", ["Bad call to '@variable'"])
    test("/hello.*/")
    test("/Number \\d*/")
  end

private

  def test(s, results = [])
    sc = RubyCheck.new(['link_to','image_tag'])
    sc.check(s)
    assert_equal(results, sc.errors)
  end  
  
end
