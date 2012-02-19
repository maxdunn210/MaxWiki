# Schema as of Wed Apr 05 20:13:53 Pacific Daylight Time 2006 (schema version 7)
#
#  id                  :integer(11)   not null
#  created_at          :datetime      not null
#  updated_at          :datetime      not null
#  revised_at          :datetime      not null
#  page_id             :integer(11)   default(0), not null
#  content             :text          default(), not null
#  author              :string(60)    
#  ip                  :string(60)    
#

# MD Oct-2007
# PageRenderer is used just for textile editing
# Textile is going away and we will be using WYSIWYG editing directly in HTML
# So some functions here are duplicates of those in PageRenderer 
require 'page_renderer'

class Revision < MaxWikiActiveRecord
  include ActionController::UrlWriter
  
  belongs_to :wiki
  belongs_to :page
  composed_of :author, :mapping => [ %w(author name), %w(ip ip) ]
  
  def content_type
    type = read_attribute(:content_type)
    if type.blank?
      :textile
    else
      type.downcase.to_sym unless type.class == Symbol
    end
  end
  
  def display_content(options = {})
    render(options)
  end 
  
  def display_content_for_export
    render :mode => :export
  end
  
  def update_references
    if content_type == :textile
      PageRenderer.new(self).display_content(true)
    else
      update_references_html
    end
  end
  
  def display_diff
    previous_revision = page.previous_revision(self)
    if previous_revision
      rendered_previous_revision = WikiContent.new(previous_revision).render!
      HTMLDiff.diff(rendered_previous_revision, display_content) 
    else
      display_content
    end
  end
  
  #--------------------
  private
  
  def render(options = {})
    if content_type == :textile
      renderer = PageRenderer.new(self, options[:render_for_edit])
      html = renderer.display_content
    else
      html = process_html(content)
    end
    
    # If a blog post, look a line with just 5 dashes or more ----- as an indicator of where to break the post
    # On the main blog page, truncate at this point, on the post show page, take it out
    if page && page.kind == Page::POST && html =~ /(.*?)<p>-{5,}<\/p>(.*)/m
      if options[:blog_summary] 
        html = $1 + "<p><a href='/#{page.link}'>Read more...</a></p>"
      else 
        html = $1 + $2
      end
    end
    html
  end
  
  # Process the html before displaying it. This doesn't change the html
  # that is saved in the DB, only what is shown
  def process_html(html)
    html = email_process(html)
    process_menu(html)
  end
  
  # Updated the references for html content
  # First, do any fixups that should happen when the page is saved
  # Second look for page links and include statements. 
  # We don't need to look in the includes for links
  def update_references_html
    fixup_page
    html = display_content
    includes = find_includes(html)
    page_names = find_referenced_names(html)
    save_references(page_names, includes)
  end
  
  # When using file upload, or copy-and-pasting old left menu to new style, FireFox will
  # insert ../.. front of the url, so fix it here.
  def fixup_page
    html = content
    if html.gsub!(/(href|src)=(['"])..\/..\//, '\1=\2/')
      content = html
      save!
    end
  end
  
  def save_references(page_names, includes)
    # Delete all references to this page because we will rebuild them all
    WikiReference.delete_all ['page_id = ?', page_id]
    
    page_names.each do |referenced_name|
      # Links to self are always considered linked
      if referenced_name == page.name
        link_type = WikiReference::LINKED_PAGE
      else
        link_type = WikiReference.link_type(referenced_name)
      end
      page.wiki_references.build(:referenced_name => referenced_name, :link_type => link_type)
    end
    
    includes.each do |included_page_name|
      page.wiki_references.build(:referenced_name => included_page_name, :link_type => WikiReference::INCLUDED_PAGE)
    end
    page.save!
  end
  
  # This RE looks for ERB style includes, like <%= include('Page') %> or <%=include 'Page'%>
  INCLUDE_RE = /
  <%=             # start of ERB
   \s*            # any number of spaces okay, including none
   include        # 'include' keyword
   (?:\s+|\(\s*)  # needs either one or more spaces, or (
   ['"]           # start with either quote
   (.*?)          # the page name, 
   ['"]           # end with either quote
   \s*\)?\s*      # after can be any number of spaces with optional ) and then any number of spaces
   %>             # end of ERB
   /xmi
  FIND_PAGE_RE = /<a.*?href=['"]\/([^'"\/]*)['"]/mi
  
  def find_referenced_names(html)
    references = html.scan(FIND_PAGE_RE).flatten.uniq.map {|ref| CGI::unescape(ref)}
    # Go through each reference and if a link, replace with the page name
    references.map do |reference|
      current_wiki.lookup_name_by_link(reference)  
    end
  end
  
  def find_includes(html)
    html.scan(INCLUDE_RE).map {|i| i[0].strip}.uniq
  end
  
  def email_process(html)
    html.gsub(/
     (^|                      # look for start of line
     \s|                      # blank space
     &nbsp;|                  # a non-break space
     <(?!a)[^>]+>             # Or tag that doesn't start with 'a"
    \s*)                     # Spaces after tag okay. Capture this in $1
     (#{EMAIL_VALID_RE_STR})  # Look for email and capture in $2
     ($|                      # Close with end of line, 
     \.|\,|                   # period or comma (i.e. "Max's email is: max@test.com.")
     \s|                      # space
     &nbsp;|                  # a non-break space
     \s*<[^>]+>)              # or tag (that may have spaces in front). Capture in $3
    /xmi) do |match| 
      "#{$1}<%= email '#{$2}' %>#{$3}"
    end
  end
  
  def process_menu(html)
    return html unless html =~ /<ul class=['"].*?menu['"]/
    
    # Add this page and all parents    
    selected_page_links = []
    page_link = MaxWikiActiveRecord.current_page_link rescue nil
    while page_link
      selected_page_links << '/' + page_link
      page_link = current_wiki.read_page_by_link(page_link).parent.link rescue nil
    end
    selected_page_links << '/' if selected_page_links.include?('/HomePage') || selected_page_links.include?('/homepage')
    
    # if there is another list after the left_menu, put <!-- end_menu --> after the menu 
    # so that the extra list won't be included in the menu processing
    end_menu = '<!-- end_menu -->'
    if html =~ /end_menu/
      end_exp = end_menu
    else
      end_exp = '</ul>'
    end
    html.gsub(/<ul class=['"].*?menu['"]>.*#{end_exp}/mi) do |list|
      begin
        doc = REXML::Document.new(list)
        process_ul(doc.elements["ul"], selected_page_links)
        doc.to_s
      rescue REXML::ParseException => msg
        logger.error msg
         "<!--- Error in HTML  -->\n#{list}"
      end
    end
  end
end

#-----------
private

def process_ul(ul, selected_page_links)
  return if ul.nil?
  
  ul.elements.each("li") do |li|
    process_li(li, selected_page_links)
  end
end

def process_li(li, selected_page_links)
  a = li.elements['a']
  if a
    a.attributes['href'] = a.attributes['href'].gsub(' ','+')
    if a.attributes['id']
      selected = selected_page_links.find {|page_name| page_name =~ /#{a.attributes['id']}/i}
    else
      selected = selected_page_links.include?(a.attributes['href'])
    end
    if selected
      a.attributes['class'] = 'selected'
      process_ul(li.elements["ul"], selected_page_links)
    else
      # If not selected, delete any submenus that may be present
      li.elements.delete_all("ul")
    end
  end        
end