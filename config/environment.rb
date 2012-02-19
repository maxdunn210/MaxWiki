# Be sure to restart your web server when you modify this file.

# Create a file called 'production" in this directory to force Rails into production mode when 
# you don't control web/app server and can't set it the proper way
if File.exist?(File.join(File.dirname(__FILE__), 'production'))
  ENV['RAILS_ENV'] ||= 'production'
end

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.1.2' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')
require File.join(File.dirname(__FILE__), '../vendor/plugins/engines/boot')

# These plugin configuration items need to be above the Initializer because that will trigger 
# Engines to load all the plugins

# Plugin authorization providers. Contains the authorization provider class
AUTH_PROVIDERS = []

# Items that need to store configuration information
WIKI_CONFIG_ITEMS = [
  {:title => 'Main', :template => 'main'},
  {:title => 'Signup', :template => 'signup'},
]

# A list of the active plugins. We can't just look at the Rails.plugins list because a plugin could
# be present but not active
ACTIVE_PLUGINS = []

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence those specified here
  
  # Skip frameworks you're not going to use (only works if using vendor/rails)
  # config.frameworks -= [ :action_web_service, :action_mailer ]
  config.frameworks -= [ :action_web_service]
  
  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )
  
  # Force all environments to use the same logger level 
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug
  
  # Use the database for sessions instead of the file system
  # (create the session table with 'rake db:sessions:create')
  config.action_controller.session_store = :active_record_store
  
  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper, 
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql
  
  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector
  config.active_record.observers = :page_observer
  
  # Make Active Record use UTC-base instead of local time
  # config.active_record.default_timezone = :utc
  
  # See Rails::Configuration for more options
  
  #SaltedLoginGenerator configuration
  config.action_mailer.template_root ||= "#{RAILS_ROOT}/app/views"
end

# Add new inflection rules using the following format 
# (all these examples are active by default):
# Inflector.inflections do |inflect|
#   inflect.plural /^(ox)$/i, '\1en'
#   inflect.singular /^(ox)en/i, '\1'
#   inflect.irregular 'person', 'people'
#   inflect.uncountable %w( fish sheep )
# end

# Include your application configuration below

# Logging and session
ActiveRecord::Base.colorize_logging = false

# Control whether deprecation warnings are displayed
ActiveSupport::Deprecation.silenced = false #MD DEBUG Nov 6, 2008

# Localization
module Localization
  CONFIG = {
    # Default language
    :default_language => 'en',
    :web_charset => 'utf-8'
  }
  
  if CONFIG[:web_charset] == 'utf-8'
    $KCODE = 'u'
    require 'jcode'
  end
end

# Instiki-specific configuration below
require_dependency 'instiki_errors'

# Init MY_CONFIG hash once here
# Each time MaxWiki loads, it will load theme_defaults.rb and the theme_environment.rb to setup the 
# information for that theme so that different themese will work correctly using multi-host.
MY_CONFIG = {}

# Flickr configuration
MY_CONFIG[:flickr_cache_file] = "#{RAILS_ROOT}/config/flickr.cache"
MY_CONFIG[:rflickr_lib] = true

# Special pages  
MY_CONFIG[:layout_sections] = ['header', 'menu', 'footer']
MY_CONFIG[:welcome_page] = 'Welcome'

# Roles
ROLE_PUBLIC = 'Public'
ROLE_USER = 'User'
ROLE_EDITOR = 'Editor'
ROLE_ADMIN = 'Admin'
MY_CONFIG[:roles] = {ROLE_PUBLIC => [], 
  ROLE_USER => [ROLE_PUBLIC],
  ROLE_EDITOR => [ROLE_USER],
  ROLE_ADMIN => [ROLE_EDITOR]}
MY_CONFIG[:default_role] = ROLE_USER

# Email Status
EMAIL_QUEUED = 'Queued'
EMAIL_SENT = 'Sent'
EMAIL_ERROR = 'Error'
EMAIL_FATAL_ERROR = 'Fatal Error'

# String to use in Regular Expressions to detect emails
EMAIL_VALID_RE_STR = '[A-Z0-9._%-]+@[A-Z0-9.-]+\.[A-Z]{2,4}'

# Define Okaapi content type (uncomment if okaapi_plugin not present...)
Okaapi.content  = :maxwiki if defined? Okaapi

# Upload file configuration
# :file_upload_root is the where the web server will start looking. No need to ever change this
# :file_upload_top is the topmost directory that file attachments should go in. This is separated out for security checks
# :file_upload_directory is the variable part and can include '%w' for wiki name and '%p' for page name
MY_CONFIG[:file_upload_root] = File.expand_path(File.join(RAILS_ROOT, 'public'))
MY_CONFIG[:file_upload_top] = '/files/attachments'
MY_CONFIG[:file_upload_directory] = '/%w/%p'

# Number of blog posts per page
MY_CONFIG[:blog_posts_per_page] = 10

# Finally, allow all of this to be overridden by a local environment
# specific to this installation. App name, email server settings, and 
# any API access keys should go here.
# The local_environment.rb file is specific to each install, so it should be added to the SVN ignore list and
# recreated from local_environment.rb.template
require 'local_environment'

# Other requires
require 'rails_patches'
gem 'will_paginate', '~>2'
require 'will_paginate'


