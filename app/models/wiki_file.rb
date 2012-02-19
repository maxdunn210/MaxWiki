# Schema as of Wed Apr 05 20:13:53 Pacific Daylight Time 2006 (schema version 7)
#
#  id                  :integer(11)   not null
#  created_at          :datetime      not null
#  updated_at          :datetime      not null
#  web_id              :integer(11)   default(0), not null
#  file_name           :string(255)   default(), not null
#  description         :string(255)   default(), not null
#

class WikiFile < MaxWikiActiveRecord

  belongs_to :wiki
  
  SANE_FILE_NAME = /^[a-zA-Z0-9\-_\. ]*$/
  def do_not_validate
    if file_name 
      if file_name !~ SANE_FILE_NAME
        errors.add("file_name", "is invalid. Only latin characters, digits, dots, underscores, " +
           "dashes and spaces are accepted")
      elsif file_name == '.' or file_name == '..'
        errors.add("file_name", "cannot be '.' or '..'")
      end
    end
    
    if @wiki and @content
      if (@content.size > @wiki.max_upload_size.kilobytes)
        errors.add("content", "size (#{(@content.size / 1024.0).round} kilobytes) exceeds " +
            "the maximum (#{wiki.max_upload_size} kilobytes) set for this wiki")
      end
    end
    
    errors.add("content", "is empty") if @content.nil? or @content.empty?
  end
  
end
