$: << File.dirname(__FILE__) + "../../lib"

require 'max_wiki_textile'

require 'rdocsupport'
require 'chunks/chunk'

# The markup engines are Chunks that call the one of MaxWikiTextile
# or RDoc to convert text. This markup occurs when the chunk is required
# to mask itself.
module Engines
  class AbstractEngine < Chunk::Abstract

    # Create a new chunk for the whole content and replace it with its mask.
    def self.apply_to(content)
      new_chunk = self.new(content)
      content.replace(new_chunk.mask)
    end

    private 

    # Never create engines by constructor - use apply_to instead
    def initialize(content) 
      @content = content
    end

  end

  class Textile < AbstractEngine
    def mask
      #MD
      # redcloth = MaxWikiTextile.new(@content, [:hard_breaks] + @content.options[:engine_opts])
      redcloth = MaxWikiTextile.new(@content, @content.options[:engine_opts])
      redcloth.filter_html = false
      redcloth.no_span_caps = false  
      #MD
      redcloth.lite_mode = false if defined?(redcloth.lite_mode)
      redcloth.hard_breaks = false if defined?(redcloth.hard_breaks)
      redcloth.to_html(:textile)
    end
  end

  class Mixed < AbstractEngine
    def mask
      redcloth = MaxWikiTextile.new(@content, @content.options[:engine_opts])
      redcloth.filter_html = false
      redcloth.no_span_caps = false
      redcloth.to_html
    end
  end

  MAP = { :textile => Textile,:mixed => Mixed}
  MAP.default = Textile
end
