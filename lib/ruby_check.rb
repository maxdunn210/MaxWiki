require 'syntax'

class RubyCheck
  attr_accessor :errors
  
  def initialize(ok_cmds)
    @ok_cmds = ok_cmds
    clear_errors
  end  

  def clear_errors  
    self.errors = []
  end
    
  def add_error(s)
    @errors << s
  end
  
  def errors
    @errors.flatten
  end

  def check_cmd(cmd)
    if !@ok_cmds.include?(cmd)
      add_error("Bad call to '#{cmd}'")
    end
  end      

  def check(s)
    return if @ok_cmds.nil?
    
    @tokenizer = Syntax.load "ruby"
    @tokenizer.tokenize(s) do |token|
      if [:ident, :global, :constant, :attribute].include?(token.group)
        check_cmd(token)
      elsif token.group == :keyword
        if !%w{if else elsif end}.include?(token)
          add_error("Bad keyword '#{token}'")
        end
      elsif token.group == :expr
         if token =~ (/^\#\{(.*)\}$/)
           check($1)
         else
           add_error("Bad expression '#{token}'")
         end  
      end
    end    
  end
end



