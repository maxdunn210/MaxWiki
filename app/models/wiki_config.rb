class WikiConfig

  def self.roles
    MY_CONFIG[:roles].keys.map {|role| Role.role_name(role)}
  end
  
  def self.themes
    Dir.entries("#{RAILS_ROOT}/public/themes", :directories, :nodots)
  end
  
  def self.config_items
    items = []
    items << config_item('Site Name', :site_name)
    items << config_item('Theme', :theme, themes)
    items << config_item('Editor', :editor, ['WYSIWYG', 'Textile'])
    items << config_item('Default Role', :default_role, roles)
    items << config_item('Emails From', :email_from)
    items << config_item('Signups CC', :signup_cc_to)
    items << config_item('Google Key', :google_key)
    items << config_item('Google Sitemap Verification', :google_sitemap_verification)
    items << config_item('Google Ad Client', :google_ad_client)
    items << config_item('Google Analytics Account', :google_analytics)
    items << config_item('Flickr Key', :flickr_key)
    items << config_item('YouTube Key', :youtube_key)
    items << config_item('Amazon Key', :amazon_key)
    items
  end
  
  #------------------
  private
  
  def self.config_item(label, var, choices=nil)
    {:label => label, :var => var, :id => "config_#{var.to_s}", :choices => choices, :size => 50}
  end
  
end
