require File.dirname(__FILE__) + '/../test_helper'

class RevisionTest < Test::Unit::TestCase
  fixtures :wikis, :pages, :revisions, :wiki_references
  
  def test_new
    revision = Revision.new
    assert_equal 1, revision.wiki_id, "Wrong wiki_id"
  end  
  
  def test_render
    page = pages(:html_sample)
    result = page.display_content
    result.gsub!("\t", '        ')
    compare_to_file(result, 'test/fixtures/convert_html.txt')
  end
  
  def test_include_references
    page = pages(:test_html)
    revision = page.revisions.last
    
    [
    "<%=include('Test Include') %>", # No space between '=' and 'include'
    "<%= include('Test Include') %>", # One space between '=' and 'include'
    "<%=  include('Test Include') %>", # Two spaces between '=' and 'include'
    "<%= include 'Test Include' %>",   # No (), one space
    "<%= include  'Test Include'%>",   # two spaces in front, none at end
    "<%= include( 'Test Include' ) %>" # space between ( and '
    ].each do |text|
      revision.content = text
      revision.update_references
      references = WikiReference.find(:all, :conditions => ['page_id = ?', page.id])
      assert_equal(["Test Include"], references.map {|r| r.referenced_name})
    end
  end
  
  def test_references
    page = pages(:html_sample)
    page.update_references
    
    references = WikiReference.find(:all, :conditions => ['page_id = ?', page.id])
    
    includes = references.map {|r| r.link_type == WikiReference::INCLUDED_PAGE ? r.referenced_name : nil}.compact
    assert_equal(['Test Include'], includes)
    
    linked_pages = references.map {|r| r.link_type == WikiReference::LINKED_PAGE ? r.referenced_name : nil}.compact.sort
    assert_equal(["HomePage", "Test"], linked_pages)
    
    wanted_pages = references.map {|r| r.link_type == WikiReference::WANTED_PAGE ? r.referenced_name : nil}.compact
    assert_equal(['Test new page'], wanted_pages)
    
    assert_equal(4, references.size)
  end  
  
  def test_href_dot_dot
    page = pages(:test_html)
    revision = page.revisions.last

    # Check href with double quotes
    revision.content = %q{<li><a href="../../Management">Management</a></li>}
    revision.update_references
    assert_equal(%q{<li><a href="/Management">Management</a></li>}, revision.display_content)  

    # Check href with single quotes
    revision.content = %q{<li><a href='../../Management'>Management</a></li>}
    revision.update_references
    assert_equal(%q{<li><a href='/Management'>Management</a></li>}, revision.display_content)  

    # Check href and src
    revision.content = %q{<a href="../../files/Calendar_04.jpg"><img width="192" src="../../files/Calendar_04.jpg?1190857529" />}
    revision.update_references
    assert_equal(%q{<a href="/files/Calendar_04.jpg"><img width="192" src="/files/Calendar_04.jpg?1190857529" />},
      revision.display_content)  
  end
  
  def test_email
    revision = Revision.new(:content => 'max@test.com', :content_type => 'html') 
    html = revision.display_content
    assert_equal("<%= email 'max@test.com' %>",html)
    
    revision = Revision.new(:content => "<p>Max's email is:&nbsp;max@test.com.</p>\n", :content_type => 'html')
    html = revision.display_content
    assert_equal("<p>Max's email is:&nbsp;<%= email 'max@test.com' %>.</p>\n",html)    
    
    revision = Revision.new(:content => "\nmarti@test.com Marti<br />\neileen@test.com Eileen&nbsp;", :content_type => 'html')
    html = revision.display_content
    assert_equal("\n<%= email 'marti@test.com' %> Marti<br />\n<%= email 'eileen@test.com' %> Eileen&nbsp;",html)
    
    # Make sure it doesn't change mailto references
    content = '<a href="mailto:eileen@test.com">eileen@test.com</a>Eileen'
    revision = Revision.new(:content => content, :content_type => 'html')
    html = revision.display_content
    assert_equal(content,html)

    # Make sure it doesn't change input fields (if three or more names, can only have a comma separating them)
    content = '<input type="hidden" value="name1@test.com,name2@test.com,name3@test.com" name="email_to" />'
    revision = Revision.new(:content => content, :content_type => 'html')
    html = revision.display_content
    assert_equal(content,html)
  end
  
  def test_left_menu
    page_link = 'about_us'
    menu_html = <<-EOS
      <ul class='left_menu'>
          <li class="submenu"><a href="/">Home</a></li>
          <li><a href="/#{page_link}">About Us</a></li>
          <li><a href="/Products">Products</a></li>
      </ul>
    EOS
    
    converted_html = <<-EOS1
      <ul class='left_menu'>
          <li class='submenu'><a href='/'>Home</a></li>
          <li><a href='/#{page_link}' class='selected'>About Us</a></li>
          <li><a href='/Products'>Products</a></li>
      </ul>
    EOS1
    
    assert_display_content(page_link, menu_html, converted_html)
  end
  
  def test_left_menu_id
    page_link = 'about_us'
    menu_html = <<-EOS
      <ul class='left_menu'>
          <li class="submenu"><a href="/">Home</a></li>
          <li><a href="/about_us" id='about'>About Us</a></li>
          <li><a href="/Products">Products</a></li>
      </ul>
    EOS

    converted_html = <<-EOS1
      <ul class='left_menu'>
          <li class='submenu'><a href='/'>Home</a></li>
          <li><a href='/about_us' class='selected' id='about'>About Us</a></li>
          <li><a href='/Products'>Products</a></li>
      </ul>
    EOS1
    
    assert_display_content(page_link, menu_html, converted_html)
  end

  def test_left_menu_invalid
    page_link = 'about_us'
    
    #No ending quote on "submenu"
    html = <<-EOS
      <ul class='left_menu'>  
          <li class="submenu><a href="/">Home</a></li>
          <li><a href="/about_us" id='about'>About Us</a></li>
          <li><a href="/Products">Products</a></li>
      </ul>
    EOS

    html_out = <<-EOS
      <!--- Error in HTML  -->\n<ul class='left_menu'>  
          <li class="submenu><a href="/">Home</a></li>
          <li><a href="/about_us" id='about'>About Us</a></li>
          <li><a href="/Products">Products</a></li>
      </ul>
    EOS

    assert_display_content(page_link, html, html_out)
  end
  
  def test_two_level_menu
    page_link = 'at_a_glance'

    html = <<-EOS
      <ul class='menu'>
        <li><a href='/'>Home</a></li>
        <li><a href='/about_us'>About Us</a>
          <ul class='submenu'>
            <li><a href='/at_a_glance'>At a Glance</a></li>
            <li><a href='/management'>Management</a></li>
            <li><a href='/contact_us'>Contact Us</a></li>
          </ul>
        </li>
        <li><a href='/news'>News</a>
          <ul class='submenu'>
            <li><a href='/news_1'>News 1</a></li>
            <li><a href='/news_2'>News 2</a></li>
          </ul>
        </li>  
      </ul>
    EOS
    
    html_out = <<-EOS
      <ul class='menu'>
        <li><a href='/'>Home</a></li>
        <li><a href='/about_us' class='selected'>About Us</a>
          <ul class='submenu'>
            <li><a href='/at_a_glance' class='selected'>At a Glance</a></li>
            <li><a href='/management'>Management</a></li>
            <li><a href='/contact_us'>Contact Us</a></li>
          </ul>
        </li>
        <li><a href='/news'>News</a></li>
      </ul>    
    EOS
    
    assert_display_content(page_link, html, html_out, 'About Us')
  end
  
  #------------
  private
  
  def assert_display_content(page_link, in_html, out_html, parent_name = nil) 
    wiki = Wiki.find(:first)
    Revision.current_wiki = wiki
    Revision.current_wiki.current_page_link = page_link
    page = wiki.pages.create(:name => page_link, :link => page_link)
    page.parent = Page.find_by_name(parent_name) unless parent_name.nil?
    page.save!
    revision = page.revisions.create(:content => in_html, :content_type => 'html', :revised_at => Time.now) 
    assert_equal(out_html.gsub("\n", '').gsub(' ', ''), revision.display_content.gsub("\n", '').gsub(' ', ''))
  end
  
end
