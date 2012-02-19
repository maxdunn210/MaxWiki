require 'maxwiki_webdav_auth'
AUTH_PROVIDERS << MaxWiki::WebdavAuth
WIKI_CONFIG_ITEMS << {:title => 'Xythos Authorization', :template => 'webdav_auth_config'}
ACTIVE_PLUGINS << 'maxwiki_webdav_auth'

