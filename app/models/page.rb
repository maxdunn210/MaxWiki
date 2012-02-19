# Schema as of Wed Apr 05 20:13:53 Pacific Daylight Time 2006 (schema version 7)
#
#  id                  :integer(11)   not null
#  created_at          :datetime      not null
#  updated_at          :datetime      not null
#  web_id              :integer(11)   default(0), not null
#  locked_by           :string(60)    
#  name                :string(60)    
#  locked_at           :datetime      
#

class Page < MaxWikiActiveRecord
  
  belongs_to :wiki
  has_many :revisions, :order => 'id'
  has_many :wiki_references, :order => 'referenced_name'
  has_one :current_revision, :class_name => 'Revision', :order => 'id DESC'
  belongs_to :parent, :class_name => 'Page', :foreign_key => "parent_id"
  has_many :children, :class_name => 'Page', :foreign_key => "parent_id"
  attr_accessor :page_number
  
  # Page kinds
  BLANK = 'Blank'
  TITLED = 'Titled'
  BLOG = 'Blog'
  POST = 'Post'
  
  def revise(content, content_type, parent_name, access, time, author, kind = nil)
    
    author = Author.new(author.to_s) unless author.is_a?(Author)
    revisions_size = new_record? ? 0 : revisions.size
    
    # Don't save revisions if it hasn't changed
    unless (revisions_size > 0) && content == current_revision.content && content_type == current_revision.content_type
      
      # A user may change a page, look at it and make some more changes - several times.
      # Not to record every such iteration as a new revision, if the previous revision was done 
      # by the same author, not more than 30 minutes ago, then update the last revision instead of
      # creating a new one
      revision = Revision.new(:page => self, :content => content, :content_type => content_type, :author => author, :revised_at => time)
      if (revisions_size > 0) && continous_revision?(time, author)
        current_revision.update_attributes(:content => content, :content_type => content_type, :revised_at => time)
      else
        revisions << revision
      end
    end

    # Save the page info    
    self.parent = Page.find_by_name(parent_name)
    self.kind = kind unless kind.nil?
    self.link = Page.create_link(name) if link.blank?
    update_attributes(access) unless access.nil?

    # Now update all references
    revisions.last.update_references

    self
  end
  
  def autosave(content)
    revise(content, content_type, parent, nil, Time.now, author)
  end
  
  def rename(new_name)
    update_attributes(:name => new_name)
  end
  
  def rename_link(new_link)
    update_attributes(:link => new_link)
  end
  
  def rollback(revision_number, time, author_ip)
    roll_back_revision = self.revisions[revision_number]
    if roll_back_revision.nil?
      raise Instiki::ValidationError.new("Revision #{revision_number} not found")
    end
    author = Author.new(roll_back_revision.author.name, author_ip)
    revise(roll_back_revision.content, time, author)
  end
  
  def revisions?
    revisions.size > 1
  end
  
  def previous_revision(revision)
    revision_index = revisions.each_with_index do |rev, index| 
      if rev.id == revision.id 
        break index 
      else
        nil
      end
    end
    if revision_index.nil? or revision_index == 0
      nil
    else
      revisions[revision_index - 1]
    end
  end
  
  def references
    wiki.select.pages_that_reference(name)
  end
  
  def wiki_words
    wiki_references.select { |ref| ref.wiki_word? }.map { |ref| ref.referenced_name }
  end
  
  def linked_from
    wiki.select.pages_that_link_to(name)
  end
  
  def included_from
    wiki.select.pages_that_include(name)
  end
  
  # Returns the original wiki-word name as separate words, so "MyPage" becomes "My Page".
  def plain_name
    wiki.brackets_only? ? name : WikiWords.separate(name)
  end
  
  LOCKING_PERIOD = 30.minutes 
  
  def lock(time, locked_by)
    update_attributes(:locked_at => time, :locked_by => locked_by)
  end
  
  def lock_duration(time)
   ((time - locked_at) / 60).to_i unless locked_at.nil?
  end
  
  def unlock
    update_attribute(:locked_at, nil)
  end
  
  def locked?(comparison_time)
    locked_at + LOCKING_PERIOD > comparison_time unless locked_at.nil?
  end
  
  def to_param
    name
  end
  
  def wiki_references_all
    references = wiki_references
    ["#{page.name}_left","#{page.name}_right"].each do |name|
      page = Page.find_by_name(name)
      references << WikiReference.new(:page_id => page.id, :referenced_name => page.name, :link_type => WikiReference::INCLUDED_PAGE) unless page.nil?
    end
    references.sort {|r1, r2| r1.referenced_name <=> r2.referenced_name}
  end
  
  def link_with_page_number
    Page.link_with_page_number(link, page_number)
  end
  
  #-- Object methods
  def self.create_link(name)
    return '' if name.blank?
    name.downcase.tr("\"'", '').gsub(/\W/, ' ').strip.tr_s(' ', '_').tr(' ', '_').sub(/^$/, "-")
  end
  
  # Looks for "_page_2" at end of link and returns stripped link and page number
  def self.parse_page(page_link)
    if page_link =~ /(.+)__page_(\d+)$/
      return $1, $2.to_i
    else
      return page_link, nil  
    end
  end
  
  def self.link_with_page_number(link, page_number)
    if page_number.blank? || page_number == 1
      link
    else
     "#{link}__page_#{page_number}"
    end
  end
  
  def self.strip_page(page_link)
    stripped_page_link, page_number = parse_page(page_link)
    return stripped_page_link  
  end
  
  #-------------
  private
  
  def continous_revision?(time, author)
   (current_revision.author == author) && (revised_at + 30.minutes > time)
  end
  
  # Forward method calls to the current revision, so the page responds to all revision calls
  def method_missing(method_id, *args, &block)
    method_name = method_id.to_s
    # Perform a hand-off to AR::Base#method_missing
    if @attributes.include?(method_name) or md = /(=|\?|_before_type_cast)$/.match(method_name)
      super(method_id, *args, &block)
    else
      current_revision.send(method_id, *args, &block)
    end
  end
end
