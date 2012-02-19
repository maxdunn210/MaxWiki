class Role

  def self.role_table
    MY_CONFIG[:roles]
  end
  
  def self.current=(role)
    unless role_table.keys.include?(role)
      @@current = ROLE_PUBLIC
    else
      @@current = role
    end
  end
  
  def self.current
    if @@current.nil?
      ROLE_PUBLIC
    else
      @@current
    end
  end
  
  def self.role_name(role)
    role
  end
  
  def self.roles_equal?(role1, role2)
    role1.downcase == role2.downcase
  end
  
  def self.role_included?(role_array, role)
    role_array.find { |r| roles_equal?(r, role) || role_included?(role_table[r], role) }
  end
  
  def self.check_roles(user_role, item_role)
    role_ok = item_role.nil? || 
    roles_equal?(user_role, ROLE_ADMIN) || 
    roles_equal?(user_role, item_role) ||
    role_included?(role_table[user_role], item_role) rescue false
  role_ok  
  end
  
  def self.check_role(item_role)
    check_roles(current, item_role)
  end
  
end