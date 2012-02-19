require 'zip/zip'

class MaxwikiConvert
  
  attr_reader :converted_path
  attr_reader :error_msg
  
  def self.mime_types
    [
    # General
      'text/rtf',
      'application/vnd.wordperfect',
      'application/zip',
    
    # MS
      'application/msword',
      'application/vnd.ms-excel',
      'application/vnd.ms-powerpoint',
    
    # Open Office 2.x / Open Document
      'application/vnd.oasis.opendocument.text',
      'application/vnd.oasis.opendocument.text-template',
      'application/vnd.oasis.opendocument.text-web',
      'application/vnd.oasis.opendocument.text-master',
      'application/vnd.oasis.opendocument.graphics',
      'application/vnd.oasis.opendocument.graphics-template',
      'application/vnd.oasis.opendocument.presentation',
      'application/vnd.oasis.opendocument.presentation-template',
      'application/vnd.oasis.opendocument.spreadsheet',
      'application/vnd.oasis.opendocument.spreadsheet-template',
      'application/vnd.oasis.opendocument.chart',
      'application/vnd.oasis.opendocument.formula',
      'application/vnd.oasis.opendocument.database',
      'application/vnd.oasis.opendocument.image',
    
    # OpenOffice 1.0 / StarOffice 6.0
       'application/vnd.sun.xml.calc',
       'application/vnd.sun.xml.draw',
       'application/vnd.sun.xml.impress',
       'application/vnd.sun.xml.writer',
    ]
  end
  
  def initialize(jooconverter)
    @jooconverter = jooconverter
  end
  
  def convert_to_html(file_path, options = {})  
    unless File.exists?(file_path)
      @error_msg = "File '#{file_path}' not found"
      return
    end
    
    # If a zip file, unzip and convert the first entry
    last_ext = File.suffix(file_path).downcase
    ext = last_ext
    file_path_to_convert = file_path
    if last_ext == 'zip'
      next_to_last_ext = File.suffix(File.basename(file_path, '.*')).downcase
      ext = next_to_last_ext unless next_to_last_ext.blank?
      
      unzip(file_path, File.dirname(file_path))
      
      first_filename = ''
      Zip::ZipInputStream::open(file_path) {|io| first_filename = io.get_next_entry.name}
      file_path_to_convert = File.join(File.dirname(file_path), first_filename)
    end
    
    if ext == 'key'
      keynote_convert(file_path_to_convert, options[:convert_type])    
    else  
      joo_convert(file_path_to_convert)
    end
  end
  
  def keynote_convert(file_path, type = :quicktime)  
    case type 
    when nil, :quicktime
      script = 'key_convert_qt.scpt'
      converted_ext = '.mov'
    when :html
      script = 'key_convert_html.scpt'
      converted_ext = '.html'
    else
      @error_msg = "Unrecognized Keynote conversion type '#{type.to_s}'"
      return  
    end
    
    cmd = %Q{osascript #{RAILS_ROOT}/vendor/plugins/maxwiki_convert/#{script} "#{file_path}"}
    error = exec(cmd, "Can't find Keynote application")
    return if error
    
    filename = File.basename(file_path, '.*')
    src_dir = File.join(ENV['HOME'], 'Desktop')
    src_path = File.join(src_dir, filename)
    dest_dir = File.dirname(file_path)
    @converted_path = File.join(dest_dir, filename) + converted_ext
    
    begin    
      FileUtils.mv(src_path + converted_ext, dest_dir)
      if type == :html
        FileUtils.mv(src_path + '_files/', dest_dir, :force => true)
      end
    rescue => e
      @error_msg = e
    end
  end
  
  def joo_convert(file_path)  
    # Check to make sure that jooconverter can support the conversion.
    # We advertise in self.mime_types that we can support zip files. However, if a zip file gets here it means that
    # we didn't recognize the type of the file inside the zip
    mime_type = MIME::Types.type_for(file_path)[0]
    unless MaxwikiConvert.mime_types.include?(mime_type) || mime_type == 'application/zip'
      @error_msg = "Can't convert '#{File.basename(file_path)}'"
      return
    end
    
    if @jooconverter.blank?
      @error_msg = "Conversions not setup (Please set 'jooconverter')"
      return
    end
    
    @converted_path = converted_file_path(file_path)
    cmd = %Q{java -jar #{@jooconverter} "#{file_path}" "#{@converted_path}"}
    error = exec(cmd, "OpenOffice process 'soffice' not running")
    return if error
    
    html = read_file(@converted_path) 
    cleaned_html = cleanup_html(html)
    write_file(@converted_path, cleaned_html)
  end
  
  #------------------
  private
  
  def unzip(pathfilename, dst_path)
    Zip::ZipFile::open(pathfilename) {
      |zf| zf.each { |e|
        fpath = File.join(dst_path, e.name)
        FileUtils.mkdir_p(File.dirname(fpath))
        zf.extract(e, fpath) {|f| true} } }
  end
  
  def exec(cmd, msg)
    error = !system(cmd)
    if error
      if $?.exitstatus == 1
        @error_msg = msg || "Process not running. Command=#{cmd}"
      else
        @error_msg = "Error #{$?.exitstatus} running #{cmd}"
      end
    end
    return error
  end
  
  def converted_file_path(file_path)
    file_path + '.html'
  end 
  
  def cleanup_html(html)
    html.gsub(/margin-right: -(\d+\.?\d*)/m, 'margin-right: 0')
  end
  
  #MD Not used Feb 2007
  def extract_styles_and_body(html)  
    html =~ /(<style.*?>.*?<\/style>)/mi
    styles = $1
    
    html =~ /<body.*?>(.*?)<\/body>/mi
    body = $1
    
    if styles.blank?
      body
    else
      styles + "\n\n" + body
    end  
  end
  
  def read_file(file_path)
    File.open(file_path, 'r') {|f| f.read }
  end  
  
  def write_file(file_path, html)
    File.open(file_path, 'w+') {|f| f.print(html) }
  end  
end