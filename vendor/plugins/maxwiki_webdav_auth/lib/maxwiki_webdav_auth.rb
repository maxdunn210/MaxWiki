require 'webdav'

module MaxWiki
  class WebdavAuth
    
    #--- Class methods ---
    def self.authenticate(login, pass, user)
      
      # Setup
      auth = Authorization.new
      auth.error = false
      wiki = MaxWikiActiveRecord.current_wiki
      server = wiki.config[:xythos_url]
      auth_path_str = wiki.config[:xythos_authentication]
      if server.blank? || auth_path_str.blank?
        auth.set_error(Authorization::NOT_SETUP, "Xythos url or authentication path not set")
        return auth
      end
      webdav = Webdav.new(server, login, pass)

      # The string should contain #{login} someplace, so expand it here
      auth_path = eval('"' + auth_path_str + '"')
      
      # Try creating a file to see if this user has access
      test_file_name = "/MaxWiki_Access_Test_#{rand(100000)}.txt"
      webdav.put(auth_path + test_file_name, "MaxWiki Access Test for #{login}")
      if webdav.error?
        if webdav.error_msg.include?('Unauthorized')
          auth.set_error(Authorization::NOT_AUTHORIZED)
        else
          auth.set_error(Authorization::UNKNOWN, webdav.error_msg)
        end
        return auth
      end
      
      # Cleanup the file and ignore any errors
      webdav.delete(auth_path + test_file_name)
      
      # Get the full name of the user
      principal_path_str = auth_path_str = wiki.config[:xythos_principal]
      if principal_path_str.blank?
        names = []
        names[0] = ''
        names[1] = login
      else
        principal_path = eval('"' + principal_path_str + '"')
        webdav.propfind(principal_path)
        fullname = webdav.result_xml.elements["D:multistatus/D:response/D:propstat/D:prop/D:displayname"].text
        names = fullname.split
      end
      
      # Return the user info
      auth.attributes = {:firstname => names[0], :lastname => names[1], :login => login, :role => wiki.config[:xythos_default_role]}
      return auth
    end
  end
end