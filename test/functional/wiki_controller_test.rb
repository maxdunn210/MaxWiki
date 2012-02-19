require File.dirname(__FILE__) + '/../test_helper'
require 'wiki_controller'

# Re-raise errors caught by the controller.
class WikiController; def rescue_action(e) raise e end; end

class WikiControllerTest < Test::Unit::TestCase
  fixtures :events, :teams, :lookups, :wikis, :system, :revisions, :pages, :wiki_references
  
  def setup
    @controller = WikiController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    super
  end
  
  NEW_PAGE = 'New Page'
  NEW_PAGE_LINK = 'new_page'
  
  EXISTING_PAGE = 'About Us' 
  EXISTING_PAGE_LINK = 'about_us' 
  
  TEST_PAGE = 'Test'
  TEST_PAGE_LINK = 'test'
  
  TEXTILE_PAGE = 'Textile Sample'
  TEXTILE_PAGE_LINK = 'textile_sample'
  
  HTML_PAGE = 'HTML Sample'
  HTML_PAGE_LINK = 'html_sample'
  
  def test_homepage
    assert_routing('', :controller => 'wiki', :action => 'show', :link => 'homepage')
    
    get :show, :link => 'homepage'
    assert_response(:success)
  end
  
  def test_print_page
    get :print, :link => EXISTING_PAGE_LINK
    assert_no_errors
    assert_select 'h1',5
    ['menu', 'buffer_header', 'left_column', 'right_column', 'buffer_footer', 'footer'].each do |id|
      assert_no_tag(:tag => 'div', :attributes => {:id => id})
    end
  end
  
  def test_new_page_access_denied
    get :new, :link => NEW_PAGE
    assert_access_denied
    
    get :edit, :link => NEW_PAGE_LINK
    assert_access_denied
  end
  
  def test_new_blank_page  
    login_editor
    get :new
    assert_edit('', 'textile')
  end
  
  # Test that if we pass in a parent page when creating a new page, that page is selected
  def test_new_page_with_parent
    login_editor
    
    get :new, :link => NEW_PAGE_LINK, :parent_link => TEST_PAGE_LINK
    assert_edit(NEW_PAGE_LINK, 'textile')
    assert_tag(:tag => 'option', :attributes => {:value => TEST_PAGE, :selected => "selected"})
    assert_tag(:tag => 'option', :attributes => {:value => ''})
  end
  
  def test_existing_page
    get :new, :link => EXISTING_PAGE_LINK
    assert_redirected_to :action => 'edit', :link => EXISTING_PAGE_LINK
    
    get :edit, :link => EXISTING_PAGE_LINK
    assert_access_denied
    
    get :edit, :link => EXISTING_PAGE_LINK
    assert_access_denied
    
    login_editor
    content = 'h1. Test Page'
    
    get :edit, :link => EXISTING_PAGE_LINK
    assert_edit(EXISTING_PAGE_LINK, 'textile')
    
    #unlock page
    get :cancel_edit, :link => EXISTING_PAGE_LINK
    
    get :edit, :link => EXISTING_PAGE_LINK
    assert_edit(EXISTING_PAGE_LINK, 'textile')
  end
  
  def test_save_new
    save_page(NEW_PAGE, NEW_PAGE_LINK, 'New page, access denied', :access_denied => true)
    
    login_editor
    save_page(NEW_PAGE, NEW_PAGE_LINK, 'New page text', :access_denied => false)
  end
  
  # Save a blank page    
  def test_save_blank
    login_editor
    
    name = 'New Blank Page'
    link = 'new_blank_page'
    content = 'This is a new, blank page'
    post :save, :author => 'Test Author', :content => content, :page_name => name
    assert_redirected_to_show(link, content)
  end
  
  # Test a new page with illegal characters in the name
  def test_save_illegal
    login_editor
    name = "Jim's & Mary's?"
    link = "jims_marys"
    content = 'This is a new page with illegal characters'
    post :save, :author => 'Test Author', :content => content, :page_name => name
    assert_redirected_to_show(link, content)
  end
  
  # Test that the parent selection is saved
  def test_save_parent
    login_editor
    
    name = 'New Page with Parent'
    link = 'new_page_with_parent'
    content = 'This is a new page with a parent'
    post :save, :author => 'Test Author', :content => content, :page_name => name, :page_parent => EXISTING_PAGE
    assert_redirected_to_show(link, content)
    assert_equal(EXISTING_PAGE, Page.find_by_name(name).parent.name)
  end
  
  # Test saving an existing page with a blank link should create a new link
  def test_save_blank_link
    login_editor
    name = 'Plus Page'
    old_link = 'Plus+Page'
    new_link = 'plus_page'
    content = 'This is an existing page with a blank link'
    post :save, :link => old_link, :page_link => '', :page_name => name, :author => 'Test Author', :content => content
    assert_redirected_to_show(new_link, content)
  end
  
  # Test saving an existing page with a blank link but with same link as previous page
  def test_save_blank_link_same
    login_editor
    content = 'This is an existing page with a blank link but will be the same as the existing link'
    post :save, :link => EXISTING_PAGE_LINK, :page_link => '', :page_name => EXISTING_PAGE, :author => 'Test Author', :content => content
    assert_redirected_to_show(EXISTING_PAGE_LINK, content)
  end
  
  def test_rename_page
    login_editor
    new_name = 'Renamed Page'
    content = 'This is a renamed page'
    
    post :save, :link => EXISTING_PAGE_LINK, :author => 'Test Author', :content => content, :page_name => new_name
    assert_redirected_to_show(EXISTING_PAGE_LINK, content)
  end
  
  def test_rename_page_link
    login_editor
    new_link = 'renamed_page_link'
    content = 'This is a renamed page link'
    
    post :save, :link => EXISTING_PAGE_LINK, :author => 'Test Author', :content => content, :page_link => new_link
    assert_redirected_to_show(new_link, content)
  end
  
  def test_rename_page_references
    login_editor
    new_name = 'Renamed Page'
    content = 'This is a renamed page to test the wiki references'
    
    # WikiReference.create(:page_id => 1, :referenced_name => EXISTING_PAGE, :link_type => 'L').save!
    old_references = WikiReference.pages_that_reference(EXISTING_PAGE).sort
    
    post :save, :link => EXISTING_PAGE_LINK, :author => 'Test Author', :content => content, :page_name => new_name
    assert_redirected_to_show(EXISTING_PAGE_LINK, content)
    
    references = WikiReference.pages_that_reference(new_name).sort
    assert_equal(old_references, references)
  end
  
  def test_new_blank_name
    login_editor
    blank_name = ''
    content = 'This is a new page with a blank page name'
    
    post :save, :author => 'New Author', :content => content, :page_name => blank_name
    assert_redirected_to :action => 'new'
    assert_equal('Please enter a page name', flash[:error].to_s)
  end
  
  def test_rename_blank_name
    login_editor
    blank_name = ''
    content = 'Rename this page to a blank name'
    
    post :save, :link => EXISTING_PAGE_LINK, :author => 'Test Author', :content => content, :page_name => blank_name
    assert_redirected_to_show(EXISTING_PAGE_LINK, content)
  end
  
  def test_rename_to_existing
    login_editor
    content = 'Renamed this page to an existing name'
    
    post :save, :link => HTML_PAGE_LINK, :author => 'Test Author', :content => content, :page_name => EXISTING_PAGE
    assert_redirected_to :action => 'edit', :link => HTML_PAGE_LINK
    assert_equal('There is already a page with that name. Please use another name', flash[:error].to_s)
  end
  
  def test_rename_link_to_existing
    login_editor
    content = 'Renamed this page to an existing link'
    
    post :save, :link => HTML_PAGE_LINK, :author => 'Test Author', :content => content, :page_name => HTML_PAGE,
    :page_link => EXISTING_PAGE_LINK
    assert_redirected_to :action => 'edit', :link => HTML_PAGE_LINK
    assert_equal('There is already a page with that permalink. Please use another permalink', flash[:error].to_s)
  end
  
  def test_new_to_existing
    login_editor
    content = 'New page with an existing name'
    
    post :save, :author => 'Test Author', :content => content, :page_name => EXISTING_PAGE
    assert_redirected_to :action => 'new'
    assert_equal('There is already a page with that name. Please use another name', flash[:error].to_s)
  end
  
  def test_new_html
    login_editor
    save_page(NEW_PAGE, NEW_PAGE_LINK, 'h1. New html page text. No textile rendering', :access_denied => false, :content_type => :html)
  end
  
  def test_save_existing
    save_page(EXISTING_PAGE, EXISTING_PAGE_LINK, 'Try to update, but access will be denied', :access_denied => true)
    
    login_editor
    save_page(EXISTING_PAGE, EXISTING_PAGE_LINK, 'Updated text', :access_denied => false)
  end
  
  def test_delete_authorization
    get :delete_page, :page => EXISTING_PAGE
    assert_redirected_to :controller => 'user', :action => 'login'
  end
  
  def test_delete_page
    login_admin
    get :delete_page, :page => EXISTING_PAGE, :return_to => 'recently_revised'
    assert_redirected_to :action => 'recently_revised'
    page = Page.find_by_name(EXISTING_PAGE)
    assert(!page, "Page #{EXISTING_PAGE} not deleted!")
  end
  
  def test_delete_before_after
    login_admin
    assert_equal(57, Page.count)
    get :delete_page, :before => TEST_PAGE, :return_to => 'recently_revised'
    assert_redirected_to :action => 'recently_revised'
    assert_equal(18, Page.count)
    
    get :delete_page, :after => TEST_PAGE, :return_to => 'recently_revised'
    assert_redirected_to :action => 'recently_revised'
    assert_equal(1, Page.count)
    
    page = Page.find_by_name(TEST_PAGE)
    assert(page, "Page #{TEST_PAGE} deleted!")
  end
  
  # This test is in WikiControllerTest because the default pages are created only when the WikiController is used
  # However, the default pages are actually created in the Wiki model
  def test_default_pages
    get :show, :link => 'HomePage' # Trigger creation of default pages
    page = nil
    ['header'].each do |page_name|
      page = Page.find_by_name(page_name)
      assert(page, "Page #{page_name} doesn't exist")
      assert_equal(:html, page.content_type, "Page '#{page.name}")
      assert_equal('system', page.author, "Page '#{page.name}")
    end
  end
  
  def test_locked_page
    login_editor
    @wiki.config[:editor] = 'textile'    
    @wiki.save!
    page = Page.find_by_name(HTML_PAGE)
    
    # Lock the page    
    get :edit, :link => HTML_PAGE_LINK, :editor => 'textile'
    assert_edit(HTML_PAGE_LINK, 'textile')
    
    #Now get the page in wysiwyg mode, break the lock, and make sure the editor sticks
    get :edit, :link => HTML_PAGE_LINK, :editor => 'wysiwyg'
    assert_no_errors
    assert_redirected_to(:controller => 'wiki', :action => 'locked', :link => 'html_sample', :editor_1 => 'wysiwyg')
    
    get :locked, :link => HTML_PAGE_LINK, :editor_1 => 'wysiwyg'
    find_attributes = {:tag => 'a', :content => 'Edit the page anyway', 
      :ancestor => {:tag => 'div', :attributes => {:id => "middle_column"}}}
    assert_tag(find_attributes)
    tag = find_tag(find_attributes).to_s
    tag =~ /href="(.*?)"/
    link = $1
    assert_equal('/_editw/html_sample?break_lock=1', link)
    
    get :edit, :link => HTML_PAGE_LINK, :editor => 'wysiwyg', :break_lock => 1
    assert_edit(HTML_PAGE_LINK, 'html')
  end
  
  def test_rss
    get :feeds
    assert_template 'feeds'
    assert_tag_link("http://#{@request.host}/rss_with_headlines")
    assert_tag_link("http://#{@request.host}/rss_with_content")
    assert_tag_feed("/rss_with_content", "Full content - Most Recent 15 (RSS 2.0)")
    assert_tag_feed("/rss_with_headlines", "Headlines - Most Recent 15 (RSS 2.0)")
    assert_tag_feed("/rss_with_headlines?limit=0", "Headlines - All (RSS 2.0)")
    
    get :rss_with_headlines
    assert_feed_common
    assert_correct_role('Public')
    assert_count('<item>', 15)
    assert_includes('<link>http://www.maxwiki.com/majors_schedule</link>')
    
    get :rss_with_content
    assert_feed_common
    assert_feed_content
    assert_correct_role('Public')
    assert_count('<item>', 15)
    
    get :rss_with_content, :limit => 0
    assert_feed_common
    assert_feed_content
    assert_correct_role('Public')
    base_num = 36
    assert_count('<item>', base_num)
    
    login_editor
    
    get :rss_with_headlines
    assert_feed_common
    assert_correct_role('Editor')
    assert_count('<item>', 15)
    
    get :rss_with_content
    assert_feed_common
    assert_feed_content
    assert_correct_role('Editor')
    assert_count('<item>', 15)
    
    get :rss_with_headlines, :limit => 0
    assert_feed_common
    assert_correct_role('Editor')
    assert_count('<item>', base_num + 1)
    
    login_admin
    
    get :rss_with_headlines, :limit => 0
    assert_feed_common
    assert_correct_role('Admin')
    assert_count('<item>', base_num + 2)
  end
  
  def test_content_type_force_editor
    login_editor
    
    assert_content_type(TEXTILE_PAGE_LINK, :textile, 'textile')
    assert_content_type(TEXTILE_PAGE_LINK, :html, 'wysiwyg')
    assert_content_type(HTML_PAGE_LINK, :textile, 'textile')
    assert_content_type(HTML_PAGE_LINK, :html, 'wysiwyg')
  end
  
  def test_content_textile_textile
    login_editor
    
    @wiki.config[:editor] = 'textile'    
    @wiki.save!
    assert_content_type(TEXTILE_PAGE_LINK, :textile)
  end
  
  def test_content_textile_wysiwyg
    login_editor
    
    @wiki.config[:editor] = 'textile'    
    @wiki.save!
    assert_content_type(HTML_PAGE_LINK, :html)
  end
  
  def test_content_wysiwyg_textile
    login_editor
    
    @wiki.config[:editor] = 'wysiwyg'    
    @wiki.save!
    assert_content_type(TEXTILE_PAGE_LINK, :html)
  end
  
  def test_content_wysiwyg_wysiwyg
    login_editor
    
    @wiki.config[:editor] = 'wysiwyg'    
    @wiki.save!
    assert_content_type(HTML_PAGE_LINK, :html)
  end
  
  def test_include_textile
    assert_include(TEXTILE_PAGE_LINK)
  end
  
  def test_include_html
    assert_include(HTML_PAGE_LINK)
  end
  
  def test_left_menu_list
    html_simple = <<-EOS
      <ul class='left_menu'>
          <li class="submenu"><a href="/">Home</a></li>
          <li><a href="/#{HTML_PAGE_LINK}">About Us</a></li>
          <li><a href="/products">Products</a></li>
      </ul>
    EOS
    
    create_revision(html_simple, HTML_PAGE_LINK) 
    get :show, :link => HTML_PAGE_LINK
    assert_select 'ul.left_menu',1
    select = assert_select 'ul>li>a[href]',3
    assert_equal('selected', select[1].attributes['class'])
    assert_equal(["Home", "About Us", "Products"], select.map {|s| s.children.to_s})
    
    html_with_img = <<-EOS1
      <ul class="left_menu">
        <li class="submenu"><a href="/"><img src="left.gif"/>Home</a></li>
        <li><a href="/#{HTML_PAGE_LINK}"><img src="right.gif"/>About Us</a></li>
        <li><a href="/products"><img src="left.gif"/>Products</a></li>
      </ul>
    EOS1
    
    create_revision(html_with_img, HTML_PAGE_LINK) 
    get :show, :link => HTML_PAGE_LINK
    assert_select 'ul.left_menu',1
    select = assert_select 'ul>li>a[href]',3
    assert_equal('selected', select[1].attributes['class'])
    assert_equal(["<img src=\"left.gif\" />Home",
      "<img src=\"right.gif\" />About Us",
      "<img src=\"left.gif\" />Products"], 
    select.map {|s| s.children.to_s})
  end
  
  def test_convert
    @wiki.config[:editor] = 'wysiwyg'    
    @wiki.save!
    
    result = convert_for_edit
    file_name = 'test/fixtures/convert_textile_for_edit.txt'
    compare_to_file(result, file_name)
    
    get :rollback, :link => TEXTILE_PAGE_LINK, :rev => 0
    assert_edit(TEXTILE_PAGE_LINK, 'html')
    
    rollback_result = get_fck_value(@response.body)
    assert_equal(result, rollback_result)
  end
  
  def test_convert_link_to
    result = convert_for_edit(%Q{<%= link_to(image_tag("btn_register.gif", :border => '0'), :controller => 'register') %>})
    assert_equal("<a href=\"/_action/register\"><img alt=\"Btn_register\" border=\"0\" src=\"/images/btn_register.gif\" /></a>\n", result)  
  end
  
  def test_convert_include
    result = convert_for_edit("[[!include About Us_left_menu]]")
    assert_equal("<p><%= include 'About Us_left_menu' %></p>", result)  
  end
  
  def test_index
    get :index
    assert_redirected_to  :controller => "wiki", :action => "list"
  end
  
  def test_list
    get :list
    select = assert_select 'div#middle_column>table>tr>td>a[href]'
    assert_equal(pages_all(:main_only, :public_only, :layout, :auto_created), select.map {|s| s.children.to_s})
    
    get :list, :all => true
    select = assert_select 'div#middle_column>table>tr>td>a[href]'
    assert_equal(pages_all(:public_only, :layout, :auto_created), select.map {|s| s.children.to_s})    
  end  
  
  def test_wanted
    get :wanted
    select = assert_select 'div#middle_column>ul>li>span.new_page_link>a[href]'
    assert_equal(pages_wanted, select.map {|s| s.children.to_s.chomp('?')})
  end
  
  def test_orphan
    get :orphan
    select = assert_select 'div#middle_column>ul>li>a[href]'
    assert_equal(pages_orphan(:public_only), select.map {|s| s.children.to_s})
    
    login_admin
    get :orphan
    select = assert_select 'div#middle_column>ul>li>a[href]'
    assert_equal(pages_orphan, select.map {|s| s.children.to_s})
  end
  
  def test_navigation
    get :list
    select = assert_select 'div#left_column>ul.left_menu>li>a[href]'
    assert_equal(["Navigation", 
      "All Pages", 
      "Recently Revised", 
      "Authors", 
      "Feeds", 
      "Export"], select.map {|s| s.children.to_s})
    
    login_editor
    get :list
    select = assert_select 'div#left_column>ul.left_menu>li>a[href]'
    assert_equal(["Navigation",
     "All Pages",
     "Wanted",
     "Orphan",
     "Recently Revised",
     "Authors",
     "Feeds",
     "Export"], select.map {|s| s.children.to_s})
  end
  
  def test_redirect
    get :show, :link => TEST_PAGE
    assert_redirected_to :link => TEST_PAGE_LINK
    
    get :show, :link => HTML_PAGE
    assert_redirected_to :link => HTML_PAGE_LINK
  end
  
  def test_show    
    get :show, :link => EXISTING_PAGE_LINK
    assert_response(200)
  end
  
  #-----------------
  private
  
  def assert_include(page_link)
    # Check bad page error message
    create_revision("<%= include('Bad Page') %>", page_link) 
    get :show, :link => page_link
    assert_tag(:tag => 'div', :attributes => {:id => 'middle_column'}, 
    :content => "Page 'Bad Page' not found")
    
    # Check include page is expanded correctly
    include_text = "<%= include('Test Include') %>"
    create_revision(include_text, page_link) 
    get :show, :link => page_link
    assert_tag_middle_col(:tag => 'ul', :attributes => {:class => "left_menu"})
    assert_tag_middle_col(:tag => 'li', :attributes => {:class => "submenu"})
    assert_tag_middle_col(:tag => 'a', :attributes => {:href => "/about_us"})
    assert_tag_middle_col(:tag => 'a', :attributes => {:href => "/contact_us"})
    assert_tag_middle_col(:tag => 'a', :attributes => {:href => "/navigation"})
    
    # Make sure original page is not changed
    page = Page.find_by_link(page_link)
    assert_equal(include_text, page.content)
  end
  
  def create_revision(content = nil, page_link = HTML_PAGE_LINK)
    page = Page.find_by_link(page_link)
    revision = page.revisions.last
    
    if content
      revision.content = content
      revision.save!
    end 
  end
  
  def convert_for_edit(content = nil)
    create_revision(content, TEXTILE_PAGE_LINK)
    
    login_editor
    get :edit, :link => TEXTILE_PAGE_LINK, :editor => 'wysiwyg'
    get_fck_value(@response.body)
  end  
  
  def get_fck_value(text)
    # MD Oct-2007 
    # This is for the "value" way of setting up the fckeditor, we are now using the "text_area" way
    # Leaving this here for now in case we need to switch back
    #    text =~ /oFCKeditor\.Value\s*=\s*\"(.*?)oFCKeditor\.Create/m
    #    return '' if $1.nil?
    #    $1.chomp =~ /(.*)\"\s*;\s*$/m
    #    $1.gsub('\r',"\r").gsub('\n',"\n").gsub('\t','        ').gsub('\"','"')
    
    html = find_tag(:tag => 'textarea').children[0].content
    html = CGI.unescapeHTML(html)
    html.gsub!("\t",'        ')
    html
  end
  
  TITLE_EDITOR = '<title>Editor Only</title>'
  TITLE_ADMIN = '<title>Admin Only</title>'
  
  def assert_correct_role(role)
    if role == 'Admin'
      assert_includes(TITLE_EDITOR)
      assert_includes(TITLE_ADMIN)
    elsif role == 'Editor'
      assert_includes(TITLE_EDITOR)
      assert_not_included(TITLE_ADMIN)
    else
      assert_not_included(TITLE_EDITOR)
      assert_not_included(TITLE_ADMIN)
    end
  end  
  
  def assert_content_type(page_link, content_type, editor = nil)
    page = Page.find_by_link(page_link)
    
    get :edit, :link => page_link, :editor => editor
    assert_edit(page_link, content_type.to_s)
    
    save_page(nil, page_link, "New content", :access_denied => false, :content_type => content_type.to_s)
    page.reload
    assert_equal(content_type, page.revisions.last.content_type)
  end
  
  def assert_feed_content
    assert_includes_in_description('Welcome to the official site of Tri-Cities Little League')
    assert_includes_in_description('Boys and girls ages 5-17')
    assert_includes_in_description('In this section are the home pages for each of the teams')
  end
  
  def assert_includes_in_description(text)
    descriptions = @response.body.scan(/<description>(.*?)<\/description>/m).flatten
    found = descriptions.find {|description| description.include?(text)}         
    assert(found, "'#{text}' not found in description")
  end
  
  def assert_feed_common
    assert_includes('<rss version="2.0">')
    assert_includes('<title>Test Web Site</title>')
    assert_includes('<link>http://www.maxwiki.com/</link>')
    assert_includes('<description>MaxWiki</description>')
    assert_includes('<title>Majors Schedule</title>')
    assert_includes('<title>T-Ball Schedule</title>')
    assert_not_included('<title>header</title>')
    assert_not_included('<title>footer</title>')
    assert_not_included('<title>menu</title>')
    assert_not_included('<title>HomePage_left</title>')
    assert_not_included('<title>HomePage_right</title>')
    assert_not_included('<title>schedule_left_menu</title>')
  end
  
  def assert_tag_feed(href, content)
    assert_tag(:tag => 'ul', :attributes => {:id => 'feedsList'}, 
    :descendant => {:tag => 'a', :attributes => {:href => href}, :content => content} )
  end
  
  def assert_tag_link(href)
    assert_tag(:tag => 'link', :attributes => {:href => href, 
      :title => 'RSS', :rel => "alternate", :type => "application/rss+xml"})
  end
  
  def assert_count(text, num)
    pos = 0
    count = 0
    while pos
      pos = @response.body.index(text, pos)
      if pos
        pos += 1
        count += 1
      end
    end
    assert(count == num, "'#{text}' was supposed to occur #{num} times but occurred #{count} times")
  end
  
  def save_page(name, link, content, options = nil)
    post :save, :link => link, :page_name => name, :author => 'Test Author', :content => content, :content_type => options[:content_type]
    
    if options and options[:access_denied]
      assert_access_denied
    else
      assert_redirected_to_show(link, content)
    end  
  end  
  
  def assert_redirected_to_show(page_link, content)
    assert_no_errors
    assert_redirected_to :action => 'show', :link => page_link
    assert_equal(content, Page.find_by_link(page_link).content)
  end
  
  def assert_access_denied
    assert_response(401)
    assert_template 'access_denied'
    assert_tag(:tag => 'h1', :content => 'Access Denied')
  end
  
end
