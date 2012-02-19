# Schema as of Wed Apr 05 20:13:53 Pacific Daylight Time 2006 (schema version 7)
#
#  id                  :integer(10)   not null
#  email               :string(60)    default(), not null
#  firstname           :string(50)    
#  lastname            :string(50)    
#  household_id        :integer(11)   default(0), not null
#  home_phone          :string(20)    
#  work_phone          :string(20)    
#  cell_phone          :string(20)    
#  relationship        :string(50)    
#  adultnum            :integer(11)   default(0), not null
#  login               :string(80)    default(), not null
#  salted_password     :string(40)    default(), not null
#  salt                :string(40)    default(), not null
#  verified            :integer(11)   default(0)
#  role                :string(40)    
#  security_token      :string(40)    
#  token_expiry        :datetime      
#  deleted             :integer(11)   default(0)
#  delete_after        :datetime      
#

require 'digest/sha1'

class User < MaxWikiActiveRecord
  
  include NameHelper
  belongs_to :wiki
  attr_accessor :new_password
  set_table_name 'adults'
  serialize :auth_extra
  
  #--- Class methods ---
  def self.authenticate_all(login, pass)
    
    # First look for internal users. If found and it is not a cached user for another auth provider, then return it
    internal_auth = authenticate(login, pass)    
    if internal_auth.user && internal_auth.user.auth_provider == 'User'
      return internal_auth
    end

    # If we found a user record, then just check its authentication_provider. Else check them all
    if internal_auth.user && internal_auth.user.auth_provider != 'User'
      auth_providers = [internal_auth.user.auth_provider.constantize]
    else
      auth_providers = AUTH_PROVIDERS
    end
    
    auth = nil
    unless auth_providers.blank?
      found_provider =  auth_providers.find do |provider| 
        auth = provider.authenticate(login, pass, internal_auth.user)
        (auth.nil? || (auth.error? && auth.error_type != Authorization::UNKNOWN)) ? nil : auth
      end
    end
    
    if found_provider.nil?
      auth = Authorization.new
      auth.set_error(Authorization::NOT_AUTHORIZED)
      return auth
    end
    return auth if auth.error?
    
    # Cache the results in the internal user record
    auth.attributes.merge!(:auth_provider => found_provider.to_s)
    if internal_auth.user.nil?
      auth.attributes.merge!(:verified => 1, :deleted => 0)
      auth.user = User.create(auth.attributes)
    else
      auth.user = internal_auth.user
      auth.attributes.delete(:role) # Don't update the role, it is only used as the original default
      auth.user.update_attributes!(auth.attributes)
    end
    
    return auth
  end 
  
  def self.authenticate(login, pass)
    auth = Authorization.new
    auth.user = find(:first, :conditions => ["login = ? AND verified = 1 AND deleted = 0", login])   
    if auth.user.nil?
      auth.set_error(Authorization::NOT_FOUND)
      return auth
    end
    
    ok = (auth.user.salted_password == salted_password(auth.user.salt, hashed(pass)))
    if !ok
      auth.set_error(Authorization::NOT_AUTHORIZED)
      # MD Debug
      # logger.error "Login Error: Login=#{login}, Password=#{pass}, Hash=#{salted_password(auth.user.salt, hashed(pass))}, Salt=#{auth.user.salt}"
      # puts "Login=#{login}, Password=#{pass}, Hash=#{salted_password(auth.user.salt, hashed(pass))}, Salt=#{auth.user.salt}"
    end  
    
    return auth
  end
  
  def self.authenticate_token(id, token)
    error = :ok
    usr = nil
    if id.nil? or id.empty? or token.nil? or token.empty?
      error = :damaged
    elsif token.size != hashed('').size
      error = :token_too_short
    else
      usr = find(:first, :conditions => ["id = ? AND security_token = ?", id, token])
      
      if usr.nil?
        error = :token_not_found
      elsif usr.token_expired?
        usr = nil
        error = :expired
      end  
    end  
    return usr, error
  end
  
  def self.find_by_email(email)
    find(:first, :conditions => "email = '#{email}'")
  end
  
  def self.max_signups
    if MY_CONFIG[:max_signups].nil?
      0
    else
      MY_CONFIG[:max_signups]
    end
  end
  
  def self.signups_left
    left = max_signups - self.count
    left = 0 if left < 0
    left
  end
  
  def self.next_wait_list_pos
    pos = self.count - max_signups + 1
    pos = 0 if pos < 0
    pos
  end
  
  def self.signup_closed?
    if max_signups == 0
      false
    else
      signups_left <= 0
    end
  end
  
  #--- Instance Methods ---
  def initialize(attributes = nil)
    super(attributes)
    @new_password = false
  end
  
  def token_expired?
    self.security_token and self.token_expiry and (Time.now > self.token_expiry)
  end
  
  def generate_security_token(hours = nil)
    if not hours.nil? or self.security_token.nil? or self.token_expiry.nil? or 
     (Time.now.to_i + token_lifetime / 2) >= self.token_expiry.to_i
      token = new_security_token(hours)
    else
      token = self.security_token
    end
    token
  end
  
  def set_delete_after
    hours = UserSystem::CONFIG[:delayed_delete_days] * 24
    write_attribute('deleted', 1)
    write_attribute('delete_after', Time.at(Time.now.to_i + hours * 60 * 60))
    
    # Generate and return a token here, so that it expires at
    # the same time that the account deletion takes effect.
    return generate_security_token(hours)
  end
  
  def change_password(pass, confirm = nil)
    self.password = pass
    self.password_confirmation = confirm.nil? ? pass : confirm
    @new_password = true
  end
  
  def wait_list?
    wait_list_pos > 0 && !paid
  end  
  
  # The old databases have lower case roles, so fix it here  
  def role
    r = read_attribute(:role)
    r.capitalize unless r.nil?
  end
  
  def auth_provider 
    provider = read_attribute(:auth_provider)
    if provider.blank?
      'User'
    else
      provider
    end
  end
  
  #-------------------------
  protected
  
  attr_accessor :password, :password_confirmation
  
  def validate_password?
    @new_password
  end
  
  def self.hashed(str)
    return Digest::SHA1.hexdigest("maxwiki--#{str}--")[0..39]
  end
  
  after_save '@new_password = false'
  after_validation :crypt_password
  def crypt_password
    if @new_password
      write_attribute("salt", self.class.hashed("salt-#{Time.now}"))
      write_attribute("salted_password", self.class.salted_password(salt, self.class.hashed(@password)))
    end
  end
  
  def new_security_token(hours = nil)
    write_attribute('security_token', self.class.hashed(self.salted_password + Time.now.to_i.to_s + rand.to_s))
    write_attribute('token_expiry', Time.at(Time.now.to_i + token_lifetime(hours)))
    update_without_callbacks
    return self.security_token
  end
  
  def token_lifetime(hours = nil)
    if hours.nil?
      UserSystem::CONFIG[:security_token_life_hours] * 60 * 60
    else
      hours * 60 * 60
    end
  end
  
  def self.salted_password(salt, hashed_password)
    hashed(salt + hashed_password)
  end
  
  validates_presence_of :email, :on => :create
  validates_length_of :email, :within => 3..40, :on => :create
  validates_format_of :email, :with => /^$|^#{EMAIL_VALID_RE_STR}$/i
  validates_uniqueness_of :email, :on => :create, :scope => :wiki_id
  
  # Currently (Aug 2007) we are not asking the user for login, but using the email for the login instead
  # So comment these out so the error messages will make sense
  #
  # validates_presence_of :login, :on => :create
  # validates_length_of :login, :within => 3..40, :on => :create
  # validates_uniqueness_of :login, :on => :create, :scope => :wiki_id
  
  validates_presence_of :password, :if => :validate_password?
  validates_confirmation_of :password, :if => :validate_password?
  validates_length_of :password, { :minimum => 5, :if => :validate_password? }
  validates_length_of :password, { :maximum => 40, :if => :validate_password? }
end

