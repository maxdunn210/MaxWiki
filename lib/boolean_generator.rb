class BooleanGenerator
  
  def initialize
    @top = BooleanNode.new
    @current = @top.dup
    @stack = Array.new
  end
  
  def add(condition = '', operator = '')
    @current.add(condition, operator)
  end

  
  def paren_open
    node = BooleanNode.new
    @current.add_level(node)
    @stack.push(@current)
    @current = node
  end
  
  def paren_close(operator = '')
    @current = @stack.pop
    @current.nodes.last[:operator] = operator
  end
  
  def to_s
    @top.to_s
  end  
end

class BooleanNode

  attr_reader :nodes
  
  def initialize
    @nodes = Array.new
  end
  
  def add(condition = '', operator = '')
    unless condition.nil? or condition.empty?
      @nodes << {:condition => condition, :operator => operator}
    end 
  end
  
  def add_level(level, operator = '')
    @nodes << {:level => level, :operator => operator}
  end
  
  # Recursively construct the condition string but leave out the last operator
  def to_s
    bool_s = ''
    last_op = ''
    @nodes.each do |node|
      if node[:level]
        s = node[:level].to_s
        s = " (#{s}) " unless s.empty?
      else
        s = node[:condition].to_s
     end  
     
     # s could be empty if the whole lower level is empty
     unless s.empty?
       bool_s << " #{last_op} " unless last_op.nil? or last_op.empty?
       bool_s << s
       last_op = node[:operator].to_s
     end  
    end
    
    bool_s.lstrip.rstrip.squeeze(" ")
  end

end
