require 'chunks/wiki'

# Changes the format from "[[!include PageName]]" to
# <%= include PageName %> when updating from Textile to HTML

class IncludeToErb < WikiChunk::WikiReference

  INCLUDE_PATTERN = /\[\[!include\s+(.*?)\]\]/i
  def self.pattern() INCLUDE_PATTERN end

  def initialize(match_data, content)
    super
    page_name = match_data[1].strip
    @unmask_text = "<%= include '#{page_name}' %>"
  end

end
