# Container for a set of pages with methods for manipulation.

class PageSet < Array
  attr_reader :wiki
  
  def initialize(wiki, pages = nil, condition = nil)
    @wiki = wiki
    # if pages is not specified, make a list of all pages in the wiki
    if pages.nil?
      super(wiki.pages)
      # otherwise use specified pages and condition to produce a set of pages
    elsif condition.nil?
      super(pages)
    else
      super(pages.select { |page| condition[page] })
    end
  end
  
  def most_recent_revision
    self.map { |page| page.revised_at }.max || Time.at(0)
  end
  
  def by_name
    PageSet.new(@wiki, sort_by { |page| page.name })
  end
  
  alias :sort :by_name
  
  def by_revision
    PageSet.new(@wiki, sort_by { |page| page.revised_at }).reverse 
  end
  
  # Get all names of refering pages, then go through each page in our set and filter out the ones not referenced
  # This returns an array of Page objects
  def pages_that_reference(page_name)
    all_referring_pages = WikiReference.pages_that_reference(page_name) 
    self.select { |page| all_referring_pages.include?(page.name) }
  end
  
  def pages_that_link_to(page_name)
    all_linking_pages = WikiReference.pages_that_link_to(page_name)
    self.select { |page| all_linking_pages.include?(page.name) }
  end
  
  def pages_that_include(page_name)
    all_including_pages = WikiReference.pages_that_include(page_name)
    self.select { |page| all_including_pages.include?(page.name) }
  end
  
  def pages_authored_by(author)
    all_pages_authored_by_the_author = 
    Page.connection.select_all(sanitize_sql([
            "SELECT page_id FROM revision WHERE author = '?'", author]))
    self.select { |page| page.authors.include?(author) }
  end
  
  def characters
    self.inject(0) { |chars,page| chars += page.content.size }
  end
  
  # Returns all the orphaned pages in this page set
  def orphaned_pages
    self - linked_pages
  end
  
  # Returns all pages that can be reached through links starting from the main pages or special
  # pages like authors and layout_sections
  # Works by starting with the known pages and seeing what pages they reference
  # Note: This doesn't filter the current page_set but creates a new one
  def linked_pages
    linked = []
    not_found = []
    to_search = ['HomePage'] + MY_CONFIG[:layout_sections] + [MY_CONFIG[:welcome_page]] + @wiki.authors
    while to_search.size > 0
      page_name = to_search.shift
      page = Page.find_by_name(page_name)
      if page 
        page.wiki_references_all.map  do |r| 
          name = r.referenced_name
          unless linked.find {|p| p.name == (name)} || to_search.include?(name) || not_found.include?(name)
            to_search << name 
          end
        end
        linked << page
      else
        not_found << page_name
      end
    end
    linked
  end
   
  # Returns all the wiki words in this page set for which
  # there are no pages in this page set's web
  def wanted_pages
    wiki_words - @wiki.select(:all_pages).names
  end
  
  def names
    self.map { |page| page.name }
  end
  
  def wiki_words
    self.inject([]) { |wiki_words, page|
      wiki_words + page.wiki_words
    }.flatten.uniq.sort
  end
  
end
