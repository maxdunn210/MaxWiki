# Schema as of Wed Apr 05 20:13:53 Pacific Daylight Time 2006 (schema version 7)
#
#  id                  :integer(11)   not null
#  created_at          :datetime      not null
#  updated_at          :datetime      not null
#  page_id             :integer(11)   default(0), not null
#  referenced_name     :string(60)    default(), not null
#  link_type           :string(1)     default(), not null
#

class WikiReference < MaxWikiActiveRecord

  LINKED_PAGE = 'L'
  WANTED_PAGE = 'W'
  INCLUDED_PAGE = 'I'
  AUTHOR = 'A'
  FILE = 'F'
  WANTED_FILE = 'E'

  belongs_to :wiki
  belongs_to :page
  validates_inclusion_of :link_type, :in => [LINKED_PAGE, WANTED_PAGE, INCLUDED_PAGE, 
    AUTHOR, FILE, WANTED_FILE]

  def self.link_type(page_name)
    current_wiki.has_page?(page_name) ? LINKED_PAGE : WANTED_PAGE
  end

  def self.pages_that_reference(page_name)
    query = 'SELECT name FROM pages JOIN wiki_references ON pages.id = wiki_references.page_id ' +
        'WHERE wiki_references.wiki_id = ? ' +
        'AND wiki_references.referenced_name = ? ' +
        "AND wiki_references.link_type in ('#{LINKED_PAGE}', '#{WANTED_PAGE}', '#{INCLUDED_PAGE}')"
    names = connection.select_all(sanitize_sql([query, current_wiki.id, page_name])).map { |row| row['name'] }
    
    # If this is a left or right page, then add the main page name if not already there
    main_page_name = page_name.gsub(/_left$/,'').gsub(/_right$/,'') 
    if main_page_name != page_name
      names << main_page_name unless names.include?(main_page_name)
    end
    names    
  end

  def self.pages_that_link_to(page_name)
    query = 'SELECT name FROM pages JOIN wiki_references ON pages.id = wiki_references.page_id ' +
        'WHERE wiki_references.wiki_id = ? ' +
        'AND wiki_references.referenced_name = ? ' +
        "AND wiki_references.link_type in ('#{LINKED_PAGE}', '#{WANTED_PAGE}')"
    names = connection.select_all(sanitize_sql([query, current_wiki.id, page_name])).map { |row| row['name'] }
  end

  def self.pages_that_include(page_name)
    query = 'SELECT name FROM pages JOIN wiki_references ON pages.id = wiki_references.page_id ' +
        'WHERE wiki_references.wiki_id = ? ' +
        'AND wiki_references.referenced_name = ? ' +
        "AND wiki_references.link_type = '#{INCLUDED_PAGE}'"
    names = connection.select_all(sanitize_sql([query, current_wiki.id, page_name])).map { |row| row['name'] }
  end

  def self.rename_page(old_name, new_name)
    update_all("referenced_name = '#{new_name}'", ['referenced_name = ?', old_name])
  end

  def wiki_word?
    linked_page? or wanted_page?
  end

  def wiki_link?
    linked_page? or wanted_page? or file? or wanted_file?
  end

  def linked_page?
    link_type == LINKED_PAGE
  end

  def wanted_page?
    link_type == WANTED_PAGE
  end

  def included_page?
    link_type == INCLUDED_PAGE
  end
  
  def file?
    link_type == FILE
  end
  
  def wanted_file?
    link_type == WANTED_FILE
  end

end
