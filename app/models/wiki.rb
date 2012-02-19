# Schema as of Wed Apr 05 20:13:53 Pacific Daylight Time 2006 (schema version 7)
#
#  id                  :integer(11)   not null
#  created_at          :datetime      not null
#  updated_at          :datetime      not null
#  name                :string(60)    default(), not null
#  address             :string(60)    default(), not null
#  password            :string(60)    
#  additional_style    :string(255)   
#  allow_uploads       :integer(11)   default(1)
#  published           :integer(11)   default(0)
#  count_pages         :integer(11)   default(0)
#  markup              :string(50)    default(textile)
#  color               :string(6)     default(008B26)
#  max_upload_size     :integer(11)   default(100)
#  safe_mode           :integer(1)    default(0)
#  brackets_only       :integer(11)   default(0)
#

class Wiki < MaxWikiActiveRecord
  include ActionController::UrlWriter
  
  has_many :pages
  has_many :wiki_files
  has_many :users
  serialize :config
  
  DEFAULT_DESCRIPTION = 'MaxWiki'
  DEFAULT_NAME = 'maxwiki'
  EXISTING_PAGE_CLASS = 'existing_page_link'
  NEW_PAGE_CLASS = 'new_page_link'
  
  def edit_wiki(new_name, description, markup, color, additional_style, safe_mode = false, 
                password = nil, published = false, brackets_only = false, count_pages = false, 
                allow_uploads = true, max_upload_size = nil)
    
    #TODO check for name conflicts
    update_attributes(:name => new_name, :description => description, :markup => markup, :color => color, 
                      :additional_style => additional_style, :safe_mode => safe_mode, :password => password, :published => published,
                      :brackets_only => brackets_only, :count_pages => count_pages, :allow_uploads => allow_uploads, :max_upload_size => max_upload_size)
  end
  
  # Use sql LOWER function to make sure Postgresql searches are case-insensitive
  def read_page_by_link(page_link)
    return nil if page_link.nil?
    pages.find(:first, :conditions => ['LOWER(link) = ?', page_link.downcase])
  end
  
  def read_page(page_name)
    return nil if page_name.nil?
    pages.find(:first, :conditions => ['LOWER(name) = ?', page_name.downcase])
  end
  
  def lookup_name_by_link(link)
    page = read_page_by_link(link)  
    if page.nil?
      link
    else
      page.name
    end
  end
  
  def write_page(name, content, content_type, parent, access, time, author, kind = nil)
    page = read_page(name) || Page.new(:name => name, :wiki_id => self.id)
    page.revise(content, content_type, parent, access, time, author, kind)
  end
  
  def rollback_page(page_name, revision_number, time, author_id = nil)
    page = read_page(page_name)
    page.rollback(revision_number, time, author_id)
  end  
  
  def remove_orphaned_pages
    remove_pages(select.orphaned_pages) #MD Debug ???
  end
  
  # This creates a list of pages for most uses. In addition to checking for permssions, check to make sure there 
  # is a revision for this page otherwise exceptions will occur
  def authorized_pages
    pages.select {|page| page.current_revision && Role.check_role(page.access_read)}
  end 
  
  def page_names
    authorized_pages.map { |p| p.name }
  end
  
  def authors
    Revision.find(:all).map {|r| r.author}.uniq.sort
  end
  
  def categories
    select.map { |page| page.categories }.flatten.uniq.sort
  end
  
  def has_page?(name)
    Page.count(:conditions => ['name = ?', name]) > 0
  end
  
  def has_page_link?(link)
    Page.count(:conditions => ['link = ?', link]) > 0
  end
  
  def has_file?(file_name)
    WikiFile.find_by_file_name(file_name) != nil
  end
  
  def markup
    read_attribute('markup').to_sym
  end
  
  def page_names_by_author
    connection.select_all(
        'SELECT DISTINCT r.author AS author, p.name AS page_name ' +
        'FROM revisions r ' +
        'JOIN pages p ON r.page_id = p.id ' +
        "WHERE p.wiki_id = #{self.id} " +
        'ORDER by p.name'
    ).inject({}) { |result, row|
      author, page_name = row['author'], row['page_name']
      result[author] = [] unless result.has_key?(author)
      result[author] << page_name
      result
    }
  end
  
  def remove_page_by_name(name)
    remove_pages [read_page(name)]
  end
  
  # Remove pages before this one (or that don't have revisions to cleanup corrupted pages)
  def remove_pages_before(name)
    before = read_page(name)
    pages_tb_removed = pages.find(:all).select do |p|
     (p.current_revision.nil? || (p.current_revision.revised_at < before.current_revision.revised_at))
    end
    remove_pages(pages_tb_removed)
  end  
  
  # Remove pages after this one and that don't have revisions (to cleanup corrupted pages)
  def remove_pages_after(name)
    after = read_page(name)
    pages_tb_removed = pages.find(:all).select do |p|
     (p.current_revision.nil? || (p.current_revision.revised_at > after.current_revision.revised_at))
    end
    remove_pages(pages_tb_removed)
  end    
  
  def remove_pages(pages_to_be_removed)
    pages_to_be_removed.each do |p| 
      unless p.nil?
        p.revisions.each do |rev|
          rev.destroy
        end
        p.destroy
      end
    end
  end
  
  def revised_at
    select.most_recent_revision
  end
  
  def select(page_filter = :main_pages, &condition)
    PageSet.new(self, select_pages(page_filter), condition)
  end
  
  def select_all(page_filter = :main_pages)
    select(page_filter)
  end
  
  def to_param
    name
  end
  
  def create_default_pages(ip)
    default_page_names = MY_CONFIG[:layout_sections] + ['HomePage','Welcome','Products', 'About Us', 'Contact Us']
    default_page_names.each do |page_name|
      next if has_page?(page_name)
      create_default_page(page_name, ip)
    end
  end
  
  def create_default_page(page_name, ip)  
    case page_name
    when 'header'
      content = <<EOF
<div class=left_block>
  <h1>MaxWiki Header</h1>
</div>
EOF
      
    when 'menu'
      content = <<EOF
<ul>
  <li><a href="/">Home</a></li>
  <li><a href="/products">Products</a></li>
  <li><a href="/about_us">About Us</a></li>
  <li><a href="/contact_us">Contact Us</a></li>
</ul>
EOF
      
    when 'footer'
      content = <<EOF
<div class="right_block"><%= login_block %> |
<div class="role_Admin" style="display: none;"><a href="/_action/reg_admin">Admin</a> |</div>
<div class="role_Editor" style="display: none;"><a href="/_action/wiki/list">Pages</a> |</div>
<b>Copyright &copy;</b><br />
Powered by <a href="http://www.maxwiki.com">MaxWiki</a></div>      
EOF
     
    when 'HomePage'
      content = <<EOF
<h1>Home Page</h1>
<p>This is a sample home page.</p>
EOF
      
    when 'Welcome'
      content = <<EOF
<h1>Welcome</h1>
<%= no_cache %>
<p>You are now logged in to <%= config_site_name %> as &lsquo;<%= session_user_name %>&rsquo; with role &lsquo;<%= session_role_name %>&rsquo;.</p>
<h2>Updating Your Information</h2>
<p>To update your password or name, go to <a href="/_action/user">account information</a> .</p>
<div class="role_Editor" style="display:none">
<h2>Editing a Page</h2>
<p><img align="bottom" alt="Edit Icon" src="/images/edit.gif" />On any page where this edit icon appears at the bottom, you can edit the page by clicking on the icon.</p>
</div>   
EOF

    else
        content = <<EOF
<h1>#{page_name}</h1>
<p>This is a sample page.</p>
EOF
    end  
    
    parent = nil
    access = {}
    page = write_page(page_name, content, 'html', parent, access, 
    Time.now, Author.new('system', ip))
    page.link =  page_name.downcase.gsub(' ','_')
    page.save!
  end
  
  # Create a link for the given page (or file) name and link text based
  # on the render mode in options and whether the page (file) exists
  # in the wiki.
  def make_link(name, text = nil, options = {})
    text = CGI.escapeHTML(text || WikiWords.separate(name))
    mode = (options[:mode] || :show).to_sym
    link_type = (options[:link_type] || :show).to_sym
    
    if (link_type == :show)
      known_page = has_page?(name)
    else
      known_page = has_file?(name)
    end
    
    case link_type
    when :show
      urlgen_page_link(mode, name, text, known_page)
    else
      raise "Unknown link type: #{link_type}"
    end
  end
  
  #----------------------
  private
  
  def select_pages(page_filter)
    if [:main_pages, :main_and_layout_pages].include?(page_filter)
      authorized_pages.select do |page|
        other_page = (page_filter != :main_and_layout_pages &&
                      MY_CONFIG[:layout_sections].include?(page.name)) ||
        page.name =~ /(_left|_right|_menu)$/
        !other_page
      end 
    else
      authorized_pages
    end
  end
  
  def urlgen_page_link(mode, name, text, known_page)
    page = read_page(name)
    if page.nil?
      link = name
      cgi_link = CGI.escape(name)
    else
      link = page.link
      cgi_link = page.link
    end
    
    case mode
    when :export
      if known_page 
        %{<a class="#{EXISTING_PAGE_CLASS}" href="/#{cgi_link}.html">#{text}</a>}
      else 
        %{<span class="#{NEW_PAGE_CLASS}">#{text}</span>} 
      end
    else 
      if known_page
        href = url_for :controller => 'wiki', :action => 'show', :link => cgi_link, :only_path => true
        %{<a class="#{EXISTING_PAGE_CLASS}" href="#{href}">#{text}</a>}
      else 
        href = url_for :controller => 'wiki', :action => 'show', :link => cgi_link, :only_path => true
        %{<span class="#{NEW_PAGE_CLASS}"><a href="#{href}">#{text}?</a></span>}
      end
    end
  end
  
  # Returns an array of all the wiki words in any current revision
  def wiki_words
    pages.inject([]) { |wiki_words, page| wiki_words << page.wiki_words }.flatten.uniq
  end
  
  #-------------------------------
  protected
  
  before_save :sanitize_markup
  before_validation :validate_name
  validates_uniqueness_of :name
  
  def sanitize_markup
    self.markup = markup.to_s
  end
  
  def validate_name
    unless name == CGI.escape(name)
      self.errors.add(:name, 'should contain only valid URI characters')
      raise Instiki::ValidationError.new("#{self.class.human_attribute_name('name')} #{errors.on(:name)}")
    end
  end
  
end
