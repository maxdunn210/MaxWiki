module NameHelper

  def full_name
    "#{firstname} #{lastname}"
  end
  
  def name_and_initial
    "#{firstname} #{lastname[0,1]}."
  end
end
