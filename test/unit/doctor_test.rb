require File.dirname(__FILE__) + '/../test_helper'

class DoctorTest < Test::Unit::TestCase
  fixtures :doctors, :wikis
  
  def test_new
    doctor = Doctor.new
    assert_equal 1, doctor.wiki_id, "Wrong wiki_id"    
  end

  def test_create
    @doctor = Doctor.find(1)
    assert_kind_of Doctor, @doctor
    assert_equal doctors(:Babcock).id, @doctor.id
    assert_equal doctors(:Babcock).physician_name, @doctor.physician_name
    assert_equal doctors(:Babcock).physician_addr, @doctor.physician_addr
    assert_equal doctors(:Babcock).policy_num, @doctor.policy_num
    assert_equal doctors(:Babcock).household_id, @doctor.household_id
    assert_equal doctors(:Babcock).healthplan, @doctor.healthplan
    assert_equal doctors(:Babcock).physician_tel, @doctor.physician_tel
    assert_equal 1, @doctor.wiki_id, "Wrong wiki_id"
  end  
end
