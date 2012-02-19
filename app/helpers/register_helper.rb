module RegisterHelper
  
  def early_date
    '12/31/2010'
  end
  
  def late_date
    '2/2/2011'
  end
  
  def reg_birthday_start_year
    Time.now.years_ago(18).year
  end
  
  def reg_birthday_end_year
    Time.now.years_ago(4).year
  end
  
  def tag_discount(early, sibling, late)
    
    if early == 0 and sibling == 0 and late == 0
      return ''
    end
    
    prelim_str = 'The fees reflect '
    
    early_str = nil
    if early > 0
      early_str = "an early bird discount of $#{early} (good through #{early_date})"
    end
    
    sibling_str = nil  
    if sibling > 0
      sibling_str = "a sibling discount of $#{sibling}"
    end
    
    late_str = nil
    if late > 0
      late_str = "a late fee of $#{late} (due after #{late_date})"
    end
    
    s = prelim_str + [early_str, sibling_str, late_str].compact.to_sentence + '.'
    
    return s
  end
  
  def last_level_list
    list = Lookup::name_list(Lookup::LEVEL)
    list.delete('')
    list.unshift('Never played')
    list.push('Other')
  end
  
end
