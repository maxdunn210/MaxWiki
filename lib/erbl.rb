#!/usr/local/bin/ruby
# Tiny Tiny eRuby 
# $Id: erbl.rb,v 1.5 1999/08/03 07:25:32 mas Exp $
# $Author: mas $
# Copyright (c) 1999 Masatoshi SEKI
# Modified 2006/10/13 MaxDunn
 
require "ruby_check"

class ARegexpAbstract
  def initialize
    @greedy = true
    @min = 1
    @max = 1
  end

  def match_one(list, start=0)
    []
  end

  def match_set(list, currSet)
    fwdSet = []
    currSet.each do |start|
      self.match_one(list, start).each do |fwd|
	fwdSet.push(fwd)
      end
    end
    fwdSet.sort.uniq
  end

  # $BI>2A$9$k%j%9%H$H@hF,$N(Bindex$B$r@_Dj$9$k(B
  def match(list, idx=0)
    fwd_set = []      	# fwd_set $B$O0\F0@h$N=89g(B
    # 0$B2s$H%^%C%A$9$k$J$i:#$N%$%s%G%C%/%9$rJV$9(B
    fwd_set.push(idx) if matchEmpty?
    
    # min$B2sD4$Y$k(B
    next_set = [idx]	# next_set $B$O?7$?$K8+$D$+$C$?0\F0@h$N=89g(B
    @min.times do 
      next_set = self.match_set(list, next_set).uniq.sort
    end
    fwd_set = fwd_set + next_set
    
    # $B2?EY$b%^%C%A(B?
    if matchMany?
      # $B?7$?$K8+$D$+$C$?0\F0@h$,$"$k4V(B
      # $B<!$N0\F0@h$N=89g$r5a$a$k(B
      while(next_set.size > 0)
	tmp = next_set
	next_set = []
	self.match_set(list, tmp).each do |i|
	  unless fwd_set.include? i
	    fwd_set.push(i)
	    next_set.push(i)
	  end
	end
      end
    end

    self.fwd_list(fwd_set)
  end

  # $B7+JV$72s?t$r@_Dj(B
  # max == -1 $B$O>e8B$N;XDj$,$J$$$3$H$r0UL#$9$k(B
  def repeat(min, max)
    @min = min
    max = -1 unless max
    @max = max
    self
  end
  def matchEmpty?
    (@min == 0)
  end
  def matchMany?
    (@max < 0)
  end
  
  # 
  def greedy(v)
    @greedy = v
    self
  end
  def fwd_list(list)
    list = list.uniq.sort
    unless @greedy
      list.reverse!
    end
    list
  end
end

class ARegexpProc < ARegexpAbstract
  def initialize(proc)
    @proc = proc
    @neg = false
    super()
  end

  def match_one(list, idx=0)
    if (list.size > idx) and (self.test(list[idx]))
      [idx + 1]
    else
      []
    end
  end

  def test(v)
    result = @proc.call(v)
    if @neg 
      not result
    else
      result
    end
  end

  def negate(neg=true)
    @neg = neg
    self
  end
end

class ARegexpEq < ARegexpProc
  def initialize(r)
    p = proc{|v| v==r}
    super(p)
  end
end

class ARegexpInclude < ARegexpProc
  def initialize(list)
    p = proc{|v| list.include?(v)}
    super(p)
  end
end

class ARegexpSeq < ARegexpAbstract
  def initialize(patterns = [])
    @seq = patterns
    super()
  end
  def add(pat)
    @seq.push(pat)
  end

  # $B;OE@(B $B$+$i(B $B0\F0@h$N=89g(B $B$r5a$a$k(B
  def match_one(list, idx=0)
    aSet = []
    i = seq_match(list, idx, 0)
    aSet.push(i) if i
    aSet.uniq
  end

  def seq_match(list, idx, seqIdx)
    if seqIdx >= @seq.size
      return idx
    end
    @seq[seqIdx].match(list, idx).reverse_each do |fwd|
      idx = seq_match(list, fwd, seqIdx + 1)
      return idx if idx
    end
    nil
  end
end

class ARegexpAlt < ARegexpAbstract
  def initialize(patterns = [])
    @alt = patterns
    super()
  end
  def add(pat)
    @alt.push(pat)
  end

  # list $B$N(B $B;OE@$N=89g(B $B$+$i(B $B0\F0@h$N=89g(B $B$r5a$a$k(B
  def match_one(list, idx=0)
    aSet = []
    @alt.each do |re|
      aSet.push(re.match(list, idx))
    end
    aSet.flatten.uniq.sort
  end
end

class ARegexpAny < ARegexpAbstract
  def match_one(list, idx=0)
    if list.size > idx
      [idx + 1]
    else
      []
    end
  end
end

class ARegexpFirst < ARegexpAbstract
  def match_one(list, idx=0)
    if idx == 0
      [idx]
    else
      []
    end
  end

  def match(list, idx=0)
    match_one(list, idx)
  end
end

class ARegexpLast < ARegexpAbstract
  def match_one(list, idx=0)
    if list.size == idx
      [idx]
    else
      []
    end
  end

  def match(list, idx=0)
    match_one(list, idx)
  end
end

class ARegexp < ARegexpSeq
  def initialize(patterns = [])
    super(patterns)
  end
  undef repeat
  undef greedy

  def shallow_copy
    ARegexp.new(@seq)
  end
  alias cp shallow_copy

  def match(list, idx=0)
    @list = list
    @matching_offset = Array.new(@seq.size + 1)
    @matching_offset[0] = idx
    v = fwd_list(match_one(list, idx))
    @matching_offset = nil if v.size == 0
    v
  end

  def seq_match(list, idx, seqIdx)
    @matching_offset[seqIdx] = idx
    super(list, idx, seqIdx)
  end
  attr :matching_offset

  def matching_data
    return [] unless @matching_offset
    curr = @matching_offset[0]
    @matching_offset[1..-1].collect { |fwd|
      len = fwd - curr
      if len > 0
	v = @list[curr, len]
      else
	v = []
      end
      curr = fwd
      v
    }
  end

  def =~(list)
    list.each_index do |idx|
      fwd = self.match(list, idx)
      if fwd.size > 0
	return idx
      end
    end
    nil
  end

  def gsub(list)
    v = []
    idx = 0
    while idx < list.size
      fwd = self.match(list, idx)
      if fwd.size == 0
	v.push(list[idx])
	idx += 1
      else
	fwdidx = fwd.max
	len = fwdidx - idx
	if len == 0
	  s = yield([])
	  v += s if s 
	  idx += 1
	else
	  s = yield(list[idx, len])
	  v += s if s 
	  idx = fwdidx
	end
      end
    end
    v
  end

  def scan(list)
    idx = 0
    while idx < list.size
      fwd = self.match(list, idx)
      if fwd.size == 0
	idx += 1
      else
	fwdidx = fwd.max
	len = fwdidx - idx
	if len == 0
	  yield([])
	  idx += 1
	else
	  yield(list[idx, len])
	  idx = fwdidx
	end
      end
    end
    self
  end

  def sub(list)
    v = list.dup
    idx = 0
    while idx < list.size
      fwd = self.match(list, idx)
      if fwd.size == 0
	idx += 1
      else
	fwdidx = fwd.max
	len = fwdidx - idx
	if len <= 0
	  v[idx, 0] = yield([])
	else
	  v[idx, len] = yield(list[idx, len])
	end
	return v
      end
    end
    v
  end
end

class ERbLight
  Revision = '$Date: 1999/08/03 07:25:32 $'

class << self
  def version
    "erb.rb [#{ERb::Revision.split[1]}]"
  end

  def pre_compile(s)
    list = []
    s.each_line do |line|
      line.gsub!(/(<%%)|(%%>)|(<%=)|(<%#)|(<%)|(%>)|(-%>)/) do |m|
	"\n#{m}\n"
      end
      list += line.split("\n")
      list.push("\n")
    end

    escape = @escape.cp
    list = escape.gsub(list) { 
      case escape.matching_data[0].join
      when '<%%'
	['<', '%']
      when '%%>'
	['%', '>']
      end
    }    	
  end
  
  def compile(s, ok_methods, safe_level)
    cmdlist = []
    str_table = []
    list = pre_compile(s)

    cmdlist.push('begin')
    cmdlist.push('_erbout = ""')
    cmdlist.push('$SAFE = @safe_level') if safe_level

    head = @head.cp
    list = head.sub(list) {
      match = head.matching_data
      match[1].join.each do |line|
        cmdlist.push("_erbout.concat #{line.dump}")
      end
      nil
    }
    ruby_check = RubyCheck.new(ok_methods)
    compile = @compile.cp
    list = compile.gsub(list) {
      match = compile.matching_data
      content = match[1].join

      ruby_check.clear_errors      
      ruby_check.check(content)
      unless ruby_check.errors.empty?
        ruby_check.errors.each do |error|
          cmdlist.push("_erbout.concat #{error.dump}")
          cmdlist.push("_erbout.concat \" \"")
        end
      else
        case match[0].join
        when '<%'
          cmdlist.push(content)
        when '<%='
          cmdlist.push("_erbout.concat((#{content}).to_s)")
        when '<%#'
          cmdlist.push("# #{content.dump}")
        end
      end
        
      match[3].join.each do |line|
        cmdlist.push("_erbout.concat #{line.dump}")
      end
      nil
    }
    list.join.each do |line|
      cmdlist.push("_erbout.concat #{line.dump}")
    end
    cmdlist.push('ensure')
    cmdlist.push('_erbout')
    cmdlist.push('end')
    cmdlist.join("\n")
  end

  def setup_compiler
    first = ARegexpFirst.new
    stag = ARegexpInclude.new(['<%=', '<%#', '<%'])
    notstag = stag.dup.negate.repeat(0, nil).greedy(true)
    etag = ARegexpInclude.new(['%>','-%>'])
    any = ARegexpAny.new.repeat(0, nil).greedy(false)
    @head = ARegexp.new([first, notstag]);
    @compile = ARegexp.new([stag, any, etag, notstag])
    escape = ARegexpInclude.new(['<%%', '%%>'])
    @escape = ARegexp.new([escape])
  end
end

  def initialize(str, ok_methods, safe_level=nil)
    @safe_level = safe_level
    # Allow alternate syntax for ERB commands and hash pairs so they are visible in normal edit window
    str = str.gsub('[%', '<%').gsub('%]', '%>').gsub('=^', '=>')
    @src = ERbLight.compile(str, ok_methods, safe_level)
  end
  attr :src

  setup_compiler

  def run(b=TOPLEVEL_BINDING)
    print self.result(b)
  end

  def result(b=TOPLEVEL_BINDING)
    if @safe_level
      th = Thread.start { 
	eval(@src, b)
      }
      return th.value
    else
      return eval(@src, b)
    end
  end
end
