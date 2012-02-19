require 'cgi'
require 'chunks/engines'
require 'chunks/category'
require 'chunks/include'
require 'chunks/include_to_erb'
require 'chunks/wiki'
require 'chunks/literal'
require 'chunks/uri'
require 'chunks/nowiki'

# Wiki content is just a string that can process itself with a chain of
# actions. The actions can modify wiki content so that certain parts of
# it are protected from being rendered by later actions.
#
# When wiki content is rendered, it can be interrogated to find out 
# which chunks were rendered. This means things like categories, wiki 
# links, can be determined.
#
# Exactly how wiki content is rendered is determined by a number of 
# settings that are optionally passed in to a constructor. The current
# options are:
#  * :engine 
#    => The structural markup engine to use (Textile, Markdown, RDoc)
#  * :engine_opts
#    => A list of options to pass to the markup engines (safe modes, etc)
#  * :pre_engine_actions
#    => A list of render actions or chunks to be processed before the
#       markup engine is applied. By default this is:    
#       Category, Include, URIChunk, WikiChunk::Link, WikiChunk::Word        
#  * :post_engine_actions
#    => A list of render actions or chunks to apply after the markup 
#       engine. By default these are:    
#       Literal::Pre, Literal::Tags
#  * :mode
#    => How should the content be rendered? For normal display (show), 
#       publishing (:publish) or export (:export)?

module ChunkManager
  attr_reader :chunks_by_type, :chunks_by_id, :chunks, :chunk_id
  
  # MD June 2006 - Took out URIChunk and LocalURIChunk because it was messing
  # up images with parameters like !<http://uri.com/image.jpg! or
  # !(img-class)http://uri.com/image.jpg(Image Title)!
  # Textile will create the URI links anyways
  ACTIVE_CHUNKS = [ NoWiki, Category, Include, WikiChunk::Link, 
  WikiChunk::Word ] unless const_defined? "ACTIVE_CHUNKS" 
  
  # Here are the chunks we want to process when permanently converting from Textile to HTML
  CONVERT_CHUNKS = [ NoWiki, IncludeToErb, WikiChunk::Link, 
  WikiChunk::Word ] unless const_defined? "CONVERT_CHUNKS" 
  
  HIDE_CHUNKS = [ Literal::Pre, Literal::Tags, 
  Literal::Erb] unless const_defined? "HIDE_CHUNKS" 
  
  MASK_RE = { 
    :active_chunks => Chunk::Abstract.mask_re(ACTIVE_CHUNKS),
    :hide_chunks => Chunk::Abstract.mask_re(HIDE_CHUNKS),
    :all_chunks => Chunk::Abstract.mask_re((ACTIVE_CHUNKS + HIDE_CHUNKS + CONVERT_CHUNKS).uniq)
  }.freeze  unless const_defined? "MASK_RE" 
  
  def init_chunk_manager
    @chunks_by_type = Hash.new
    Chunk::Abstract::derivatives.each{|chunk_type| 
      @chunks_by_type[chunk_type] = Array.new 
    }
    @chunks_by_id = Hash.new
    @chunks = []
    @chunk_id = 0
  end
  
  def add_chunk(c)
    @chunks_by_type[c.class] << c
    @chunks_by_id[c.object_id] = c
    @chunks << c
    @chunk_id += 1
  end
  
  def delete_chunk(c)
    @chunks_by_type[c.class].delete(c)
    @chunks_by_id.delete(c.object_id)
    @chunks.delete(c)
  end
  
  def merge_chunks(other)
    other.chunks.each{|c| add_chunk(c)}
  end
  
  def scan_chunkid(text)
    text.scan(MASK_RE[:active_chunks]){|a| yield a[0] }
  end
  
  def find_chunks(chunk_type)
    @chunks.select { |chunk| chunk.kind_of?(chunk_type) and chunk.rendered? }
  end
  
end

# A simplified version of WikiContent. Useful to avoid recursion problems in 
# WikiContent.new
class WikiContentStub < String
  
  attr_reader :options
  include ChunkManager
  
  def initialize(content, options)
    super(content)
    @options = options
    init_chunk_manager
  end
  
  # Detects the mask strings contained in the text of chunks of type chunk_types
  # and yields the corresponding chunk ids
  # example: content = "chunk123categorychunk <pre>chunk456categorychunk</pre>" 
  # inside_chunks(Literal::Pre) ==> yield 456
  def inside_chunks(chunk_types)
    chunk_types.each{|chunk_type|  chunk_type.apply_to(self) }
    
    chunk_types.each{|chunk_type| @chunks_by_type[chunk_type].each{|hide_chunk|
        scan_chunkid(hide_chunk.text){|id| yield id }
      }
    } 
  end
end

class WikiContent < String
  
  include ChunkManager
  
  DEFAULT_OPTS = {
    :active_chunks       => ACTIVE_CHUNKS,
    :engine_opts         => [],
    :mode                => :show
  }.freeze unless const_defined? "DEFAULT_OPTS" 
  
  attr_reader :wiki, :options, :revision, :not_rendered, :pre_rendered
  
  # Create a new wiki content string from the given one.
  # The options are explained at the top of this file.
  def initialize(revision, options = {})
    @revision = revision
    @wiki = @revision.page.wiki
    
    # Merge most options, but override "active_chunks" if included
    @options = DEFAULT_OPTS.dup.merge(options)
    @options[:active_chunks] = options[:active_chunks] unless options[:active_chunks].blank?
    if @revision.content_type == :textile
      @options[:engine] = Engines::MAP[:textile] 
    end
    @options[:engine_opts] = [:filter_html, :filter_styles] if @wiki.safe_mode?
    @options[:active_chunks] -= [WikiChunk::Word] if @wiki.brackets_only?
    
    @not_rendered = @pre_rendered = nil
    
    super(@revision.content)
    init_chunk_manager
    build_chunks
    @not_rendered = String.new(self)
  end
  
  def make_page_link(name, text, link_type)
    @options[:link_type] = (link_type || :show)
    @wiki.make_link(name, text, @options)
  end
  
  def build_chunks
    # create and mask Includes and "active_chunks" chunks
    if @options[:active_chunks].include?(Include)
      Include.apply_to(self)
    end
    @options[:active_chunks].each{|chunk_type| chunk_type.apply_to(self)}
    
    # Handle hiding contexts like "pre" and "code" etc..
    # The markup (textile, rdoc etc) can produce such contexts with its own syntax.
    # To reveal them, we work on a copy of the content.
    # The copy is rendered and used to detect the chunks that are inside protecting context  
    # These chunks are reverted on the original content string.
    
    copy = WikiContentStub.new(self, @options)
    @options[:engine].apply_to(copy) if @options[:engine]
    
    copy.inside_chunks(HIDE_CHUNKS) do |id|
      @chunks_by_id[id.to_i].revert
    end
  end
  
  def pre_render!
    unless @pre_rendered 
      @chunks_by_type[Include].each{|chunk| chunk.unmask }
      @pre_rendered = String.new(self)
    end
    @pre_rendered 
  end
  
  def render!
    pre_render!
    @options[:engine].apply_to(self) if @options[:engine]
    # unmask in one go. $~[1] is the chunk id
    gsub!(MASK_RE[:all_chunks]) do 
      chunk = @chunks_by_id[$~[1].to_i]
      if chunk.nil? 
        # if we match a chunkmask that existed in the original content string
        # just keep it as it is
        $~[0]
      else 
        chunk.unmask_text 
      end
    end
    self
  end
  
  def page_name
    @revision.page.name
  end
  
end
