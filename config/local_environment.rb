MY_CONFIG[:host_map] = [
  {:host => 'local.maxwiki.com:3000', :name => 'maxwiki'},
  {:host => 'local.maxwiki.com', :name => 'maxwiki'},
  {:host => '192.168.1.101:3000', :name => 'maxwiki'},
  {:host => '192.168.1.100:3000', :name => 'noho'},
  {:host => 'localhost:3000', :name => 'new_wiki1'},
  {:host => 'local.tricitiesbaseball.org:3000', :name => 'tric'},
  {:host => 'local.tricitiesbaseball.org', :name => 'tric'},
  {:host => 'local.maxdunn.com:3000', :name => 'maxdunn'},
  {:host => 'local.rubyonrailscamp.com:3000', :name => 'rorcamp'},
  {:host => 'local.lawsonpta.org:3000', :name => 'lawsonpta'},
  {:host => 'local.lawsonsportsboosters.org:3000', :name => 'lawsonboosters'},
  {:host => 'local.pbcckids.org:3000', :name => 'pbcckids'},
  {:host => 'local.divcamp.org:3000', :name => 'divcamp'},
  {:host => 'local.apple.com:3000', :name => 'apple'},
  {:host => 'local.vineanddine.org:3000', :name => 'vineanddine'},
  {:host => 'local.vjhsal.org:3000', :name => 'vjhsal'},
  {:host => 'local.anchorbay.com:3000', :name => 'abt'},   
  {:host => 'local.bichonfurkids.com:3000', :name => 'bichon'},   
  {:host => 'local.shesgeeky.org:3000', :name => 'shesgeeky'},   
  {:host => 'local.echotx.com:3000', :name => 'echotx'},   
  {:host => 'local.willowgarage.com:3000', :name => 'willowgarage'},   
  {:host => 'local.audiclubgoldengate.org:3000', :name => 'audiclubgoldengate'},  
  {:host => 'local.noho.com:3000', :name => 'noho'},  
  {:host => 'local.pbccjh.org:3000', :name => 'pbccjh'},  
  {:host => 'local.lmfinance.com:3000', :name => 'lmfinance'},  
  {:host => 'local.elderconnect.com:3000', :name => 'elderconnect'},  
  {:host => 'local.adalta.com:3000', :name => 'adalta'},  
  {:host => 'local.50percentclub.org:3000', :name => 'fiftyclub'},  
  {:host => 'local.vistagen.com:3000', :name => 'vistagen'},    
  {:host => 'local.inpower.com:3000', :name => 'inpower'}, 
  {:host => 'local.sparkchangegroup.com:3000', :name => 'sparkchange'}, 
  {:host => 'local.eclub.com:3000', :name => 'eclub'}, 
  {:host => 'local.gridrev.com:3000', :name => 'gridrev'}, 
]

# DEBUG - Override Number of blog posts per page
MY_CONFIG[:blog_posts_per_page] = 5

# Put upload files in main site directory (%w is the wiki name)
# MY_CONFIG[:file_upload_top] = '/files'
# MY_CONFIG[:file_upload_directory] = '/%w'

#MY_CONFIG[:jooconverter] = "/usr/lib/jooconverter-2.1.0/jooconverter-2.1.0.jar"
MY_CONFIG[:jooconverter] = "/Applications/jooconverter-2.1.0/lib/jooconverter-2.1.0.jar"

ActionMailer::Base.smtp_settings = {
  :address => "mail.maxdunn.com",
  :port => 2525,
  :domain => "maxwiki.net",
  :user_name => "mdunn@maxdunn.com",
  :password => "222MQjTN",
  :authentication => :login
} 

module UserSystem
  CONFIG = {
    # Email charset
    :mail_charset => 'utf-8',

    # Security token lifetime in hours
    :security_token_life_hours => 24,

    # Two column form input
    :two_column_input => true,

    # Set to true to allow delayed deletes (i.e., delete of record
    # doesn't happen immediately after user selects delete account,
    # but rather after some expiration of time to allow this action
    # to be reverted).
    :delayed_delete => false,

    # Default is one week
    :delayed_delete_days => 7,
  }
end

# Logging and session
ActionController::CgiRequest::DEFAULT_SESSION_OPTIONS.update(:session_expires => Time.now.next_year)
ActionController::CgiRequest::DEFAULT_SESSION_OPTIONS[:session_key] = 'maxwiki'



