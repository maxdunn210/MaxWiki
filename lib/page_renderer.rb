require 'diff'
require 'wiki_content'

# Temporary class containing all rendering stuff from a Revision 
# I want to shift all rendering loguc to the controller eventually

class PageRenderer

  attr_reader :revision

  def initialize(revision = nil, convert_for_edit = nil)
    self.revision = revision
    @convert_for_edit = convert_for_edit
  end

  def revision=(r)
    @revision = r
    @display_content = @display_published = @wiki_words_cache = @wiki_includes_cache = 
        @wiki_references_cache = nil
  end

  def display_content(update_references = false)
    if @revision.is_a?(String)
      @display_content = @revision
    else 
      @display_content ||= render(:update_references => update_references)
    end  
  end

  def display_content_for_export
    render :mode => :export
  end

  def display_published
    @display_published ||= render(:mode => :publish)
  end

  def display_diff
    previous_revision = @revision.page.previous_revision(@revision)
    if previous_revision
      rendered_previous_revision = WikiContent.new(previous_revision).render!
      HTMLDiff.diff(rendered_previous_revision, display_content) 
    else
      display_content
    end
  end

  # Returns an array of all the WikiIncludes present in the content of this revision.
  def wiki_includes
    unless @wiki_includes_cache 
      chunks = display_content.find_chunks(Include)
      @wiki_includes_cache = chunks.map { |c| ( c.escaped? ? nil : c.page_name ) }.compact.uniq
    end
    @wiki_includes_cache
  end

  # Returns an array of all the WikiReferences present in the content of this revision.
  def wiki_references
    unless @wiki_references_cache 
      chunks = display_content.find_chunks(WikiChunk::WikiReference)
      @wiki_references_cache = chunks.map { |c| ( c.escaped? ? nil : c.page_name ) }.compact.uniq
    end
    @wiki_references_cache
  end

  # Returns an array of all the WikiWords present in the content of this revision.
  def wiki_words
    @wiki_words_cache ||= find_wiki_words(display_content) 
  end

  def find_wiki_words(rendering_result)
    wiki_links = rendering_result.find_chunks(WikiChunk::WikiLink)
    # Exclude backslash-escaped wiki words, such as \WikiWord, as well as links to files 
    # and pictures, such as [[foo.txt:file]] or [[foo.jpg:pic]]
    wiki_links.delete_if { |link| link.escaped? or [:pic, :file].include?(link.link_type) }
    # convert to the list of unique page names
    wiki_links.map { |link| ( link.page_name ) }.uniq
  end

  # Returns an array of all the WikiWords present in the content of this revision.
  # that already exists as a page in the wiki.
  def existing_pages
    wiki_words.select { |wiki_word| @revision.page.wiki.page(wiki_word) }
  end

  # Returns an array of all the WikiWords present in the content of this revision
  # that *doesn't* already exists as a page in the wiki.
  def unexisting_pages
    wiki_words - existing_pages
  end  

  private
  
  def render(options = {})
    options[:active_chunks] = ChunkManager::CONVERT_CHUNKS if @convert_for_edit
    wiki_page = WikiContent.new(@revision, options)
    rendering_result = wiki_page.render!
    update_references(rendering_result) if options[:update_references]
 
    # If result has paragraph marks around the whole string, and none int
    # the middle, strip them off because they can mess up the spacing
    # of the footer or header
    # MD DEBUG This is messing up other pages, take out for now.
#    if rendering_result =~ /^<p>(.*)<\/p>$/
#      stripped = $1
#      unless stripped =~ /<p>|<\/p>/
#        rendering_result = stripped
#      end
#    end  
#    
    rendering_result
  end
  
  def update_references(rendering_result)
    WikiReference.delete_all ['page_id = ?', @revision.page_id]

    references = @revision.page.wiki_references

    wiki_words = find_wiki_words(rendering_result)
    # TODO it may be desirable to save links to files and pictures as WikiReference objects
    # present version doesn't do it
    
    wiki_words.each do |referenced_name|
      # Links to self are always considered linked
      if referenced_name == @revision.page.name
        link_type = WikiReference::LINKED_PAGE
      else
        link_type = WikiReference.link_type(referenced_name)
      end
      references.create :referenced_name => referenced_name, :link_type => link_type
    end
    
    include_chunks = rendering_result.find_chunks(Include)
    includes = include_chunks.map { |c| ( c.escaped? ? nil : c.page_name ) }.compact.uniq
    includes.each do |included_page_name|
      references.create :referenced_name => included_page_name, 
          :link_type => WikiReference::INCLUDED_PAGE
    end
    
    categories = rendering_result.find_chunks(Category).map { |cat| cat.list }.flatten
    categories.each do |category|
      references.create :referenced_name => category, :link_type => WikiReference::CATEGORY
    end
  end
end
