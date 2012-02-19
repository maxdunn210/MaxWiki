require './test/test_helper'
  
class Test::Unit::TestCase
  
  FIXTURE_DIR = File.dirname(__FILE__) + '/fixtures/'
  TEMP_DIR = File.dirname(__FILE__) + '/tmp/'
  
  def compare(converted_path)
    converted = File.open(converted_path).read
    baseline_path = FIXTURE_DIR + File.basename(converted_path)
    baseline = File.open(baseline_path) {|f| f.read}
    if baseline != converted
      assert_equal(baseline_path, converted_path, "Converted file different from baseline")
    end
  end
  
end