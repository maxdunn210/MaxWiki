require File.expand_path(File.dirname(__FILE__) + '/../test/test_helper')
require 'fileutils'
require 'maxwiki_convert'

class MaxwikiConvertTest < Test::Unit::TestCase
  
  CONVERTED_EXT = '.html'
  GOOD_DOC_NAME =  'eHealth.doc'
  GOOD_DOC_PATH = FIXTURE_DIR + GOOD_DOC_NAME
  
  def setup
    super
    FileUtils.rm_rf(Dir.glob(TEMP_DIR + '*'))
  end
  
  def test_no_jooconverter
    converter = MaxwikiConvert.new(nil)
    converter.convert_to_html(GOOD_DOC_PATH)
    assert_equal("Conversions not setup (Please set 'jooconverter')", converter.error_msg)
  end
  
  def test_bad_jooconverter
    converter = MaxwikiConvert.new('bad_convert.jar')
    converter.convert_to_html(GOOD_DOC_PATH)
    assert_equal("OpenOffice process 'soffice' not running", converter.error_msg)
  end
  
  def test_bad_file
    file_name = 'non_existent.doc'
    converter = MaxwikiConvert.new(MY_CONFIG[:jooconverter])
    converter.convert_to_html(file_name)
    assert_equal("File '#{file_name}' not found", converter.error_msg)
  end
  
  def test_unconvertible
    file_name = 'program.exe'
    converter = MaxwikiConvert.new(MY_CONFIG[:jooconverter])
    converter.convert_to_html(FIXTURE_DIR + file_name)
    assert_equal("Can't convert '#{file_name}'", converter.error_msg)
  end
  
  def test_doc
    convert_and_compare(GOOD_DOC_NAME)
  end
  
  def test_xls
    convert_and_compare('Budget.xls')
  end
  
  def test_ppt
    convert_and_compare('Opening.ppt')  
  end
   
  def test_key
    convert_and_compare('Keynote.key', :convert_type => :html)

    # Get rid of all the files because we can't overwrite the read-only files in .svn
    FileUtils.rm_rf(Dir.glob(TEMP_DIR + '*'))

    # Unfortunately, the .mov file that this produces has a timestamp in it, so we can't compare it to a baseline.
    # Instead, just convert and make sure .mov file exists
    converter = convert('Keynote.key', :convert_type => :quicktime)
    assert_equal('Keynote.mov', File.basename(converter.converted_path))
    assert(File.exists?(converter.converted_path), "Can't find #{converter.converted_path}")
  end
  
  #--------------------
  private
  
  def convert_and_compare(file_name, options = {})
    converter = convert(file_name, options)
    compare(converter.converted_path)
  end   
  
  def convert(file_name, options = {})
    FileUtils.cp_r(FIXTURE_DIR + file_name, TEMP_DIR + file_name)
   
    converter = MaxwikiConvert.new(MY_CONFIG[:jooconverter])
    converter.convert_to_html(TEMP_DIR + file_name, options)
    assert_equal(nil, converter.error_msg)
    
    return converter
  end
  
  def copy_recursive(source_name, dest_name)
  end
  
end
