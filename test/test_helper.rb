ENV["RAILS_ENV"] = "test"
require 'time'
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'

#To turn off deprecation warnings
#ActiveSupport::Deprecation.silenced = true

class Test::Unit::TestCase
  # Transactional fixtures accelerate your tests by wrapping each test method
  # in a transaction that's rolled back on completion.  This ensures that the
  # test database remains unchanged so your fixtures don't have to be reloaded
  # between every test method.  Fewer database queries means faster tests.
  #
  # Read Mike Clark's excellent walkthrough at
  #   http://clarkware.com/cgi/blosxom/2005/10/24#Rails10FastTesting
  #
  # Every Active Record database supports transactions except MyISAM tables
  # in MySQL.  Turn off transactional fixtures in this case; however, if you
  # don't care one way or the other, switching from MyISAM to InnoDB tables
  # is recommended.
  self.use_transactional_fixtures = true
  
  # Instantiated fixtures are slow, but give you @david where otherwise you
  # would need people(:david).  If you don't want to migrate your existing
  # test cases which use the @david style and don't mind the speed hit (each
  # instantiated fixtures translates to a database query per test method),
  # then set this back to true.
  self.use_instantiated_fixtures  = false
  
  if not defined?('WEBDAV_SERVER')
    WEBDAV_SERVER = 'http://local.xythos.com:8080' 
    WEBDAV_PATH = '/Users/mdunn@maxwiki.com/Test Dir'
    WEBDAV_USERNAME = 'mdunn@maxwiki.com'
    WEBDAV_PASSWORD = 'itssonice'
  end
  
  fixtures :wikis, :pages, :revisions
  
  # this is called by all tests
  def setup
    setup_wiki
    setup_host_map
    setup_host
  end
  
  def setup_wiki
    @wiki = Wiki.find(:first)
    MaxWikiActiveRecord.current_wiki = @wiki
  end
  
  def setup_host_map
    MY_CONFIG[:host_map] =  [{:host => 'www.maxwiki.com', :name => 'maxwiki'},
    {:host => 'www.maxwiki2.com', :name => 'maxwiki2'},
    {:host => 'redirect.maxwiki.com', :redirect_to => 'test.maxwiki.com'},
    {:host => 'new.maxwiki.com', :name => 'new_maxwiki'},
    {:host => 'www.cachetest.com', :name => 'maxwiki'}]
  end
  
  def setup_host(default_host = 'www.maxwiki.com')
    MY_CONFIG[:host] = default_host
    @request.host = MY_CONFIG[:host] if @request && @request.respond_to?('host=')
  end  
  
  def login_helper(role, id=1000)
    @request.session[:user] = {}
    @request.session[:user][:id] = id
    @request.session[:user][:role] = role
    Role.current = role
  end
  
  def login_admin
    login_helper('Admin')
  end
  
  def login_editor
    login_helper('Editor')
  end
  
  # Both of these need to be called from a test that instantiates UserController
  # They are placed here because the auth providers also need to call them
  def login_user_controller(login, password, good_login = true)
    post :login, :user => {:login => login, :password => password}
    if good_login
      assert_no_errors
      assert_not_nil(session[:user], "Username '#{login}' or password '#{password}' was bad")
      user = User.find_by_login(login)
      assert session[:user][:id] , user.id
      assert_equal login, user.login, "Login name '#{login}' should match session name '#{user.login}'"
      assert_redirected_to_welcome
    else
      assert_msg_notice('Login unsuccessful')
      assert_msg_error('Not authorized')    
      assert_nil(session[:user], "Login '#{login}' with password '#{password}' succeeded but it should have failed")
    end  
  end
  
  def logout_user_controller
    get :logout
    assert_response :success
    assert_template "logout"
    assert @response.session[:user].nil?
  end
  
  def login_integrated(login = nil, password = nil)
    login = 'admin@test.com' if login.nil?
    password = 'password' if password.nil?
    
    post(url_for(:controller => 'user', :action => 'login'),
    { :user => { :login => login, :password => password}})
    assert_no_errors
    assert_redirected_to :controller => 'wiki', :action => 'show', :link => 'welcome'
  end
  
  def login_admin_integrated
    login_integrated
  end
  
  def login_editor_integrated
    login_integrated('editor@test.com', 'password')
  end
  
  def tag_hash(klass, msg)
    if msg.blank?
      {:tag => 'div', :attributes => { :class => klass}}
    else
      {:tag => 'div', :attributes => { :class => klass}, :content => msg}
    end
  end
  
  def tag_hash_msg_error(msg)
    tag_hash('msg_error', msg)
  end
  
  def tag_hash_msg_notice(msg)
    tag_hash('msg_notice', msg)
  end
  
  def assert_msg_error(msg)
    assert_tag(tag_hash_msg_error(msg))
  end
  
  def assert_no_msg_error(msg = nil)
    assert_no_tag(tag_hash_msg_error(msg))
  end
  
  def assert_msg_notice(msg)
    assert_tag(tag_hash_msg_notice(msg))
  end
  
  def assert_no_errors
    assert_nil flash[:error] unless flash.nil?
    assert_no_msg_error
    assert(@response.success? || @response.redirect?, "Response was #{@response.response_code}")
  end
  
  def assert_tag_middle_col(tag)
    assert_tag(tag.merge({:ancestor => {:tag => 'div', :attributes => {:id => 'middle_column'}}}))
  end
  
  def assert_includes(partial_str, full_str = nil)
    if full_str.blank?
      assert_body_includes(partial_str)
    else
      assert(full_str.include?(partial_str), "<#{partial_str}> expected in\n<#{full_str}>")
    end
  end
  
  def assert_not_included(partial_str, full_str = nil)
    if full_str.blank?
      assert_body_not_includes(partial_str)
    else
      assert(!full_str.include?(partial_str), "<#{partial_str}> not expected in\n<#{full_str}>")
    end
  end
  
  def assert_body_includes(text)
    if text.is_a?(Regexp)
      test = (@response.body =~ text)
    else
      test = @response.body.include?(text)
    end
    assert(test, "'#{text}' not found in response body.")
  end
  
  def assert_body_not_includes(text)
    if text.is_a?(Regexp)
      test = !(@response.body =~ text)
    else
      test = !@response.body.include?(text)
    end
    assert(test, "'#{text}' was found in response body.")
  end
  
  def assert_edit(link, content_type)
    assert_no_errors
    assert_template 'edit'
    
    content_type_param = "?content_type=#{content_type.to_s}"
    link.blank? ? link_url = '/' : link_url = "/#{link}"
    assert_tag(:tag => 'form', :attributes => {:id => 'editForm', :action => "/_action/wiki/save#{link_url}#{content_type_param}"}) 
  end
  
  def verify_return(button_name, controller, action, id = nil)
    form_tag = find_tag(:tag => 'form', :child => {:tag => 'input', :attributes => { :value => button_name}} ).to_s
    
    assert(!form_tag.empty?, "Can't find #{button_name} button")  
    assert(form_tag =~ (/action=['"](.*?)['"]/) )
    url = $1
    #assert_equal(url, '/_action/events/return_to_last_list')
    url_parts = url.split('/')
    button_action = url_parts[3]
    button_controller = url_parts[2]
    
    # Get is different for functional tests versus integration tests
    if self.kind_of?(ActionController::IntegrationTest)
      get url
      if action == 'show'
        assert_redirected_to url_for(:controller => controller, :action => action, :link => id)
      else
        assert_redirected_to url_for(:controller => controller, :action => action, :id => id)
      end
    else
      get button_action, {:id => id}
      if action == 'show'
        assert_redirected_to(:controller => controller, :action => action, :link => id)
      else
        assert_redirected_to(:controller => controller, :action => action, :id => id)
      end
    end  
  end
  
  def compare_to_file(result, file_name)
    last_dot_pos = file_name.rindex('.')
    actual_file_name = file_name.dup
    actual_file_name.insert(last_dot_pos, '.actual')
    
    baseline_result = File.open(file_name) {|f| f.read}
    
    if baseline_result != result
      File.open(actual_file_name, 'w') {|f| f.write(result)}
      assert_equal(actual_file_name, file_name, "Results differ")
    end
    File.delete(actual_file_name) rescue nil
  end
  
  def assert_redirected_to_welcome
    assert_redirected_to :controller => 'wiki', :action => 'show', :link => 'welcome'
  end    
  
  def update_test_page(content)
    post url_for(:controller => 'wiki', :action => 'save', :link => 'test',
    :author => 'Test Author', :content => content)
    
    assert_redirected_to(:controller => 'wiki', :action => 'show', :link => 'test')
    
    follow_redirect!      
  end
  
  def pages_all(*options)
    pages = ["About Us",
 "About Us_left",
 "Admin",
 "Admin Only",
 "Boundaries",
 "Contact Us",
 "Contact Us_left",
 "Editor Only",
 "FAQ",
 "FAQ_left",
 "Farm Schedule",
 "HTML Sample",
 "HomePage",
 "HomePage_left",
 "HomePage_right",
 "Juniors Schedule",
 "League Levels",
 "League Levels_left",
 "Majors Schedule",
 "Majors: Giants",
 "Majors: Mariners_left",
 "Minors Schedule",
 "Minors: Giants",
 "Minors: Giants_left",
 "Minors: Padres",
 "Minors: Padres_left",
 "Minors: Yankees",
 "Minors: Yankees_left",
 "Navigation",
 "Plus Page",
 "Products",
 "Registration",
 "Registration_left",
 "Schedules",
 "Seniors Schedule",
 "Sponsoring",
 "Sponsoring_left",
 "Survey",
 "SurveyResults",
 "T-Ball Schedule",
 "Teams",
 "Teams_Menu",
 "Teams_left",
 "Test",
 "Test HTML",
 "Test Include",
 "Test Textile",
 "Test_left",
 "Textile Sample",
 "Tri-Cities Board",
 "Tri-Cities Board_left",
 "Welcome",
 "schedule_left_menu",
 "volunteering",
 "volunteering_left"]
    if options
      if options.include?(:layout)
        pages = pages + (MY_CONFIG[:layout_sections] - pages_auto_created)
      end
      if options.include?(:auto_created)
        pages = pages + pages_auto_created
      end 
      if options.include?(:public_only)
        pages = pages - pages_restricted
      end
      if options.include?(:main_only)
        pages = pages.select {|name| name !~ /(_left|_right|_menu)$/}
      end
    end
    pages.sort
  end
  
  def pages_restricted
    ["Admin Only", "Editor Only"]
  end
  
  def pages_auto_created
    ['header']
  end
  
  def pages_wanted
    ["Majors: Mariners",
 "Max Dunn",
 "Minors: As",
 "Steve Cousins",
 "Suzanne Dunn",
 "Volunteering",     # There is a lowercase 'volunteering' - this case sensitivity should be fixed
 "boundaries"]
  end
  
  def pages_orphan(*options)
    pages = ["Admin Only",
 "Editor Only",    
 "Farm Schedule",
 "HTML Sample",
 "Juniors Schedule",
 "Majors Schedule",
 "Majors: Mariners_left",
 "Minors Schedule",
 "Navigation",
 "Plus Page",
 "Products",
 "Seniors Schedule",
 "Survey",
 "SurveyResults",
 "T-Ball Schedule",
 "Test",
 "Test HTML",
 "Test Include",
 "Test Textile",
 "Test_left",
 "Textile Sample",
 "schedule_left_menu"]
    if options && options.include?(:public_only)
      pages = pages - pages_restricted
    end
    pages
  end
  
  def build_wiki
    Revision.delete_all
    Page.delete_all
    WikiReference.delete_all
    
    # One of the pages always included is "menu" so start here and create some links including "About Us"
    # Next create an "About Us" page and "About Us_left" to check that left pages are processed correctly
    # On About Us_left, put an include to a menu page that links the Contacts page
    # Finally create the only orphan page
    create_page('menu', <<-EOS_menu
    <ul>
	  <li><a href="/Wanted+Page">Wanted Page</a></li>
	  <li><a href="/about_us">About Us</a></li>
	  <li><a href="/admin_info">Admin Info</a></li>
    </ul>
    EOS_menu
    )  
    create_page('About Us', '<h1>About Us</h1>')
    create_page('About Us_menu', <<-EOS_About_us_menu
    <ul>
	  <li><a href="/About Us">About Us</a></li>
	  <li><a href="/Contact">Contact</a></li>
    </ul>
    EOS_About_us_menu
    )
    create_page('About Us_left',"<%= include 'About Us_menu' %>")
    create_page('Contact','<h1>Contact</h1>')
    create_page('Orphan','<p>Orphan page</p>')
    page = create_page('Admin Info','<h1>Admin Access Only</h1>')
    page.access_read = 'Admin'
    page.save!
  end
  
  def create_page(name, content, parent = nil, kind = nil)
    access = {}
    author = 'test'
    @page = Page.new  
    @page.name = name
    @page.link = Page.create_link(name)
    @page.revise(content, 'html', parent, access, Time.now, author, kind)
  end
  
  def setup_blog(blog_name = 'Blog')
    create_page(blog_name,"<h1>My Blog</h1>\n[%= blog %]", nil, 'Blog')
    create_page('Blog Entry 1',"<p>This is my blog entry 1<br />\nThis is a long entry<br />\nSo this is truncated after this line</p>\n<p>-----</p>\n<p>Now this is the extended content</p>\n",blog_name, 'Post')
    create_page('Blog Entry 2','<p>This is my blog entry 2</p>',blog_name, 'Post')
    create_page('Blog Entry 3','<p>This is my blog entry 3</p>',blog_name, 'Post')
    create_page('Blog Entry 4','<p>This is my blog entry 4</p>',blog_name, 'Post')  
  end
end


#---------------------
module ActionController
  module TestProcess
    
    # Fix bug in /usr/local/lib/ruby/gems/1.8/gems/actionpack-1.12.5/lib/action_controller/test_process.rb:378
    # It just tests for nil, but it should also test to see if the controller name is the same
    # Also test if it is really a redirect
    def follow_redirect
      raise "Not redirected" if @response.redirected_to.nil?
      
      unless @response.redirected_to[:controller].nil? || 
       (@response.redirected_to[:controller] ==  @request.parameters[:controller])
        raise "Can't follow redirects outside of current controller (#{@response.redirected_to[:controller]})"
      end
      
      get(@response.redirected_to.delete(:action), @response.redirected_to.stringify_keys)
    end
    
  end
end

# in Rails 1.1.6, there is a problem with render_component and integration tests where the
# old controller is always used. See: http://dev.rubyonrails.org/ticket/4632
# 
# This has been fixed, but is not in the release yet.
# Here is the fix from: http://dev.rubyonrails.org/changeset/4582     
# 
# From: action_controller/integration.rb
# 
class ActionController::Base
  
  def self.new_with_capture(*args)
    controller = new_without_capture(*args) 
    self.last_instantiation ||= controller 
    controller     
  end
end

# If a :tag option is included, only show those tags. This makes it
# easier to see what is wrong rather than wading through an html dump
# of the entire page
# 
# From: action_controller/assertions.rb
# 
module TagAssertionsPatch
  
  def assert_tag(*opts)
    clean_backtrace do
      opts = opts.size > 1 ? opts.last.merge({ :tag => opts.first.to_s }) : opts.first
      tag = find_tag(opts)
      
      # Wrap this so html_to_show is not called unless it is really needed
      if !tag
        assert tag, "expected tag, but no tag found matching #{opts.inspect} in:\n#{html_to_show(opts)}"
      end
    end
  end
  
  def assert_no_tag(*opts)
    clean_backtrace do
      opts = opts.size > 1 ? opts.last.merge({ :tag => opts.first.to_s }) : opts.first
      tag = find_tag(opts)
      
      # Wrap this so html_to_show is not called unless it is really needed
      if tag
        assert !tag, "expected no tag, but found tag matching #{opts.inspect} in:\n#{html_to_show(opts)}"
      end
    end
  end
  
  # Show only the relevant tags, rather than the whole html page dump.
  def html_to_show(opts)
    if opts[:tag]
      tags = find_all_tag(opts)
      return tags.to_s unless tags.blank?
      
      if opts[:attributes]
        find_opts = opts.dup
        find_opts[:attributes] = opts[:attributes].reject{|key, value| key == :action}
        tags = find_all_tag(find_opts)
        return tags.to_s unless tags.blank?
      end
      
      find_opts = opts.reject{|key, value| key != :tag && key != :attributes}
      tags = find_all_tag(find_opts)
      return tags.to_s unless tags.blank?
      
      find_opts = opts.reject{|key, value| key != :tag}
      tags = find_all_tag(find_opts)
      return tags.to_s
    else
      @response.body  
    end
  end
end

Test::Unit::TestCase.send(:include, TagAssertionsPatch)
ActionController::IntegrationTest.send(:include, TagAssertionsPatch)

# There is a bug in Rails 1.2.1 where it checks strings by '@content == conditions' 
# rather than the old way of @content.index(conditions)
# The problem is that this requires matching the *entire* string rather than just a substring
# which is what the documentation states
# This is from action_controller/assertions/tag_assertions.rb from ActionPack 1.13.1
class HTML::Text
  def match(conditions)
    case conditions
    when String
      @content.index(conditions)
    when Regexp
      @content =~ conditions
    when Hash
      conditions = validate_conditions(conditions)
      
      # Text nodes only have :content, :parent, :ancestor
      unless (conditions.keys - [:content, :parent, :ancestor]).empty?
        return false
      end
      
      match(conditions[:content])
    else
      nil
    end
  end
end

# The IntegrationTest controller sets the host to 'www.example.com' when it resets. So catch it
# and set it back to the correct name
module ActionController
  module Integration
    class Session
      alias reset_test_helper_old! reset! 
      def reset!
        reset_test_helper_old!
        self.host = MY_CONFIG[:host] 
      end
    end
  end
end

