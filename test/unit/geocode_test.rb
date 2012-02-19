require File.dirname(__FILE__) + '/../test_helper'

class GeocodeTest < Test::Unit::TestCase
  
  # These tests can take a long time, so in test mode, Geocode just fakes the lookup.
  # To really do a lookup, set @force_test to true
  def setup
    super
    @force_test = false
  end
  
  def test_inside1
    check_addr(:inside, "18671 Pring Court, 95014")
  end
  
  def test_inside2
    check_addr(:inside, "5855 Bollinger Road, 95014")
  end
  
  def test_inside3
    check_addr(:inside, "19400 Sorenson Ave, 95014")
  end
  
  def test_inside4
    check_addr(:inside, "10281 N. Blaney Ave., 95014")
  end
  
  def test_inside5
    #check_addr(:inside, "10524 S. Tantau Ave., 95014")  # This one is a problem (returns two addresses)
  end
  
  def test_inside6
    check_addr(:inside, "10590 Whitney Wy, 95014")
  end
  
  def test_inside7
    check_addr(:inside, "10270 N. Portal Ave, 95014")
  end
  
  def test_inside8
    check_addr(:inside, "10894 Blaney, 95014")
  end
  
  def test_inside9
    check_addr(:inside, "10876 E Estates Dr, 95014")
  end
  
  def test_inside10
    check_addr(:inside, "6457 Bollinger, 95014")
  end
  
  def test_inside11
    check_addr(:inside, "6437 Bollinger, 95014")
  end
  
  def test_inside12
    check_addr(:inside, "6309 Bollinger, 95014")
  end  
  
  def test_outside1
    check_addr(:outside, "5920 Royal Ann Drive, 95129")
  end  
  
  def test_outside2
    check_addr(:outside, "1617 Lewiston Drive, 94087")
  end  
  
  def test_outside3
    check_addr(:outside, "21401 Prospect Road, 95070")
  end  
  
  def test_outside4
    check_addr(:outside, "5147 Forest View Drive, 95129")
  end  
  
  def test_outside5
    check_addr(:outside, "1084 Oaktree Drive, 95129")
  end  
  
  def test_outside6
    check_addr(:outside, "359 Howard Drive, 95051")
  end  
  
  def test_outside7
    check_addr(:outside, "908 Forest Ridge Dr, 95129")  # Rowe
  end  
  
  def test_outside8
    check_addr(:outside, "1367 S. Blaney Ave., 95129") #Alay
  end  
  
  def test_outside9
    check_addr(:outside, "702 Londonderry Dr., 94087")
  end  
  
  def test_outside10
    check_addr(:outside, "20073 Northcrest Sq., 95014")
  end  
  
  def test_outside11
    check_addr(:outside, "20202 Northcove SQ, 95014")
  end  
  
  def test_outside12
    check_addr(:outside, "6836 Bollinger, 95129")
  end  
  
  def test_outside13
    check_addr(:outside, "6774 Bollinger, 95129")
  end  
  
  def test_outside14
    check_addr(:outside, "6734 Bollinger, 95129")
  end  
  
  def test_outside15
    check_addr(:outside, "6698 Bollinger, 95129")
  end  
  
  def test_outside16
    check_addr(:outside, "6760 Bollinger, 95129")
  end  
  
  def test_outside17
    check_addr(:outside, "6660 Bollinger, 95129")
  end  
  
  def test_outside18
    check_addr(:outside, "6620 Bollinger, 95129")
  end  
  
  def test_outside19
    check_addr(:outside, "6568 Bollinger, 95129")
  end  
  
  def test_not_found
    check_addr(:not_found, "123 Mickey Mouse, 95014")
  end  
  
  #-------------
  private
  
  def check_addr(correct_status, addr)
    house = Geocode.new(addr, @force_test)
    if house.found
      address = house.address
      if house.waiver_required
        status = :outside
      else
        status = :inside
      end
    else
      address = "NOT FOUND"
      status = :not_found
    end
    
    assert_equal(correct_status, status, address)
  end
  
end
