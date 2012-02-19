# The original code wasn't ideal when when using nested :includes 
# because the first association was named for the table, which
# wasn't descriptive. This uses more natural names.
# 
# I don't think we need the table_aliases anymore since I believe
# that the names will be unique. However, I haven't tested 3 level
# nested :includes so leaving it in for now.
# 
#TODO MD There could be a length issue with really long nested includes. 
#Should only be as long as active_record.connection.table_alias_length
#
# From: active_record/associations.rb
#
module ActiveRecord::Associations::ClassMethods
  class JoinDependency
    class JoinAssociation
      
      def initialize(reflection, join_dependency, parent = nil)
        reflection.check_validity!
        if reflection.options[:polymorphic]
          raise EagerLoadPolymorphicError.new(reflection)
        end
        
        super(reflection.klass)
        @parent             = parent
        @reflection         = reflection
        @aliased_prefix     = "t#{ join_dependency.joins.size }"
        @parent_table_name  = parent.active_record.table_name
        
        # MD 7-March-2007
        # Normally, we just want the alias name to be the same as the join name. 
        # We don't want it the same as the table, otherwise, using a "lookup" table will give weird names
        # The other case we need to handle is when a table is joined more than once, like home_team and visitor_team
        # which both join to the Teams table. So look at the parent and see if the table name is the same
        # as the alias name, and if not, prefix the alias name
        # This might not work for multi-level multi-joins, but I don't have a test case for that
        # 
        # Old line below:
        # @aliased_table_name = table_name #.tr('.', '_') # start with the table name, sub out any .'s
        prefix = ""
        if parent.instance_of?(JoinAssociation) && (parent.table_name.singularize != parent.aliased_table_name.singularize)
          prefix = "#{parent.aliased_table_name}_"
        end
        @aliased_table_name = prefix + reflection.name.to_s
        
        if !parent.table_joins.blank? && parent.table_joins.to_s.downcase =~ %r{join(\s+\w+)?\s+#{aliased_table_name.downcase}\son}
          join_dependency.table_aliases[aliased_table_name] += 1
        end
        
        unless join_dependency.table_aliases[aliased_table_name].zero?
          # if the table name has been used, then use an alias
          @aliased_table_name = active_record.connection.table_alias_for "#{pluralize(reflection.name)}_#{parent_table_name}"
          table_index = join_dependency.table_aliases[aliased_table_name]
          join_dependency.table_aliases[aliased_table_name] += 1
          @aliased_table_name = @aliased_table_name[0..active_record.connection.table_alias_length-3] + "_#{table_index+1}" if table_index > 0
        else
          join_dependency.table_aliases[aliased_table_name] += 1
        end
        
        if reflection.macro == :has_and_belongs_to_many || (reflection.macro == :has_many && reflection.options[:through])
          @aliased_join_table_name = reflection.macro == :has_and_belongs_to_many ? reflection.options[:join_table] : reflection.through_reflection.klass.table_name
          unless join_dependency.table_aliases[aliased_join_table_name].zero?
            @aliased_join_table_name = active_record.connection.table_alias_for "#{pluralize(reflection.name)}_#{parent_table_name}_join"
            table_index = join_dependency.table_aliases[aliased_join_table_name]
            join_dependency.table_aliases[aliased_join_table_name] += 1
            @aliased_join_table_name = @aliased_join_table_name[0..active_record.connection.table_alias_length-3] + "_#{table_index+1}" if table_index > 0
          else
            join_dependency.table_aliases[aliased_join_table_name] += 1
          end
        end
      end
    end
  end
end

# Fix expire_page so that it can recursively delete many pages based on a regular expression  
# Most of this code is taken from FileStore and expire_fragment
module ActionController::Caching::Pages
  
  module ClassMethods
    
    def delete(path) #:nodoc:
      File.delete(page_cache_path(path))
    rescue SystemCallError => e
      # If there's no cache, then there's nothing to complain about
    end
    
    def delete_matched(matcher) #:nodoc:
      search_dir(page_cache_directory) do |f|
        if f =~ matcher
          begin
            File.delete(f)
          rescue SystemCallError => e
            # If there's no cache, then there's nothing to complain about
          end
        end
      end
    end
    
    def search_dir(dir, &callback)
      Dir.foreach(dir) do |d|
        next if d == "." || d == ".."
        name = File.join(dir, d)
        if File.directory?(name)
          search_dir(name, &callback)
        else
          callback.call name
        end
      end
    end
    
    def expire_page(path)
      return unless perform_caching
      
      if path.is_a?(Regexp)
        delete_matched(path)
      else
        delete(path)
      end
    end
  end  
  
  # Expires the page that was cached with the +options+ as a key. Example:
  #   expire_page :controller => "lists", :action => "show"
  #MD Also accepts regular expressions and then does a recursive delete of those files
  def expire_page(options = {})
    return unless perform_caching
    if options.is_a?(Regexp)
      self.class.expire_page(options)
    elsif options[:action].is_a?(Array)
      options[:action].dup.each do |action|
        self.class.expire_page(url_for(options.merge({ :only_path => true, :skip_relative_url_root => true, :action => action })))
      end
    else
      self.class.expire_page(url_for(options.merge({ :only_path => true, :skip_relative_url_root => true })))
    end
  end
end

#Don't escape + in URLS
module ActionView::Helpers::UrlHelper
  alias mw_original_url_for url_for
  def url_for(options = {})
    mw_original_url_for(options).gsub('%2B','+')
  end
end

class File
  def File.suffix(name)
    suffix_size = File.basename(name).size - File.basename(name,'.*').size - 1
    if suffix_size <= 0
      return ''
    else
      return name.last(suffix_size)
    end  
  end
end

class Dir
  class << self
    alias mw_orig_entries entries
    
    def entries(path, *options)
      names = mw_orig_entries(path)
      if options.blank?
        return names
      end  
      
      list = []
      any_file = (options & [:files, :directories]).blank?
      names.each do |name|
        next if name[0,1] == "." if options.include?(:nodots)
        
        is_dir = File.directory?(File.join(path, name))
        if any_file ||
         (is_dir && options.include?(:directories)) ||
         (!is_dir && options.include?(:files))
          list << name
        end
      end
      list
    end
  end
end

module URI
  module Escape
    
    # Check first to see if there are already escaped characters so we don't escape them twice 
    alias maxwiki_old_escape escape
    def escape(str, unsafe = UNSAFE)
      if str =~ URI::REGEXP::ESCAPED
        str
      else
        maxwiki_old_escape(str, unsafe)
      end
    end
  end
end    

# PostgreSQL doesn't have the current_database method, so add it here
module ActiveRecord
  module ConnectionAdapters
    class PostgreSQLAdapter
      
      alias maxwiki_old_initialize initialize
      def initialize(connection, logger, params, config = {})
        @database = config[:database]
        maxwiki_old_initialize(connection, logger, params, config)
      end
      
      def current_database
        @database
      end
      
    end
  end
end

# Allow comma delimited lists in email addresses
module ActionMailer
  class Base
    
    alias :create_mail_maxwiki_old :create_mail
    
    def create_mail
      if @recipients.class == String
        @recipients = @recipients.scan(/\b#{EMAIL_VALID_RE_STR}\b/mi)
      end
      create_mail_maxwiki_old
    end
  end  
end

# Fix follow_redirect to be able to use a string
module Test
  module Unit
    class TestCase #:nodoc:
      
      def follow_redirect
        if (@response.redirected_to.is_a? String)
          action_hash = ActionController::Routing::Routes.recognize_path(@response.redirected_to.gsub(/^\w+:\/\/.*?\//,"/"))
        else
          action_hash = @response.redirected_to
        end
        redirected_controller = action_hash[:controller]
        
        if redirected_controller && redirected_controller != @controller.controller_name
          raise "Can't follow redirects outside of current controller (from #{@controller.controller_name} to #{redirected_controller})"
        end
        get(action_hash.delete(:action), action_hash.stringify_keys)
      end  
    end
  end
end

module ActionView
  module Helpers
    module DateHelper
      def select_hour(datetime, options = {}, html_options = {})
        hour_options = []
        
        0.upto(23) do |hour|
          hour_options << ((datetime && (datetime.kind_of?(Fixnum) ? datetime : datetime.hour) == hour) ?
          %(<option value="#{hour}" selected="selected">#{ampm(hour)}</option>\n) :
          %(<option value="#{hour}">#{ampm(hour)}</option>\n)
          )
        end

        select_html(options[:field_name] || 'hour', hour_options.join, options, html_options)
      end
      
      def ampm(hour)
        case hour
        when 0     : "12am" 
        when 1..11 : "#{hour}am" 
        when 12    : "12pm" 
        else         "#{hour-12}pm" 
        end
      end
    end
  end
end