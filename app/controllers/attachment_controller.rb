class AttachmentController < ApplicationController
  
  before_filter :authorize_editor
  # Don't use a layout since all methods will be rendered in a Ajax section
  # layout 'simple' # Debug
  
  def file_upload
    @page_name = params[:page_name] 
    @full_directory_name = full_directory_name( @page_name, @wiki.name )  
    
    stored_file = params[:stored_file]    
    filename = stored_file[:stored_file].original_filename rescue nil 
  
    # attachment filename will be the same as originally uploaded filename
    @full_filename = safe_file_join(@full_directory_name, filename)
    
    if filename.blank?
      @error_msg = "Please select a file to upload"
    else
      begin
        # create backup copy of the file
        if File.exist?(@full_filename) 
          File.rename(@full_filename, 
                      @full_filename + Time.now.strftime(".backup.%m-%d-%Y-%H-%M-%S")  )
        end
        
        File.open( @full_filename, 'wb', 0664) do |f|
          f.write( stored_file[:stored_file].read )
        end
      rescue => e
        @error_msg = "Error #{e}"
      end
    end
    
    display_selector
    render_iframe_update('file_list') do
      render :partial => 'file_list'
    end
    
    # Oct-2007 Leaving this block for now in case Safari 3 starts to work with responds_to_parent
    #    responds_to_parent do
    #      render :update do |page|
    #        page.replace_html 'file_list', :partial => 'file_list'
    #      end
    #    end
  end
  
  def delete
    @page_name = params[:page_name] 
    @full_directory_name = full_directory_name( @page_name, @wiki.name )  
    @full_filename = safe_file_join(@full_directory_name, params[:filename])
    begin
      File.delete(@full_filename)
    rescue => e
      @error_msg = "Error #{e}"
    end   
    update
  end
  
  def show
    display_selector
  end
  
  def update
    show
    render :partial => 'file_list'
  end
  
  #-------
  private
  
  def display_selector
    @page_name = params[:page_name] 
    @full_directory_name = full_directory_name( @page_name, @wiki.name )    
    @attachment_directory = attachment_directory_name( @page_name, @wiki.name ) 
    @attachments = []            
    if File.exist?( @full_directory_name )             
      Dir.foreach( @full_directory_name ) do |filename|  
        if filename[0] != 46 # no '.', e.g. '.', '..', '.svn'
          fs = File.stat(@full_directory_name+'/'+filename)
          @attachments << {:pagename => @page_name,
            :filename => filename,
            :filesize => fs.size,
            :filedate => fs.mtime.strftime("%m/%d/%Y %H:%M:%S"),
            :time => fs.mtime }
        end
      end
    end
    @attachments.sort! { |x,y| -(x[:time] <=> y[:time]) }
  end
  
  # This is based on responds_to_parent which doesn't work with Safari 3.0.3 
  # So here, we just make the calls directly
  def render_iframe_update(id_name, &block)
    yield
    
    # We're returning HTML instead of JS or XML now
    response.headers['Content-Type'] = 'text/html; charset=UTF-8'  
    # Escape quotes, linebreaks and slashes, maintaining previously escaped slashes
    # Suggestions for improvement?
    html = (response.body || '').
    gsub('\\', '\\\\\\').
    gsub(/\r\n|\r|\n/, '\\n').
    gsub(/['"]/, '\\\\\&').
    gsub('</script>','</scr"+"ipt>')
    
    # Clear out the previous render to prevent double render
    erase_results
    
    render :text => "<html><body><script type='text/javascript' charset='utf-8'>
      setTimeout(function() {
        parent.document.getElementById('#{id_name}').innerHTML = '#{html}';
        parent.document.getElementById('upload_indicator').style.display = 'none';
        document.location.replace('about:blank');
      }, 10);  
      </script></body></html>" 
  end
  
  # This fails on Safari 3.0.3 because its call:
  # 
  #   with(window.parent) { Element.update(...
  # 
  # silently fails, apparently due to security changes
  # 
  # Oct-2007 Leaving this in here for now because it is a better way of doing it and this includes
  # the testing results in the comments and if Safari changes, we might use it again.
  def responds_to_parent(&block)
    yield
    
    if performed?
      # We're returning HTML instead of JS or XML now
      response.headers['Content-Type'] = 'text/html; charset=UTF-8'
      
      # Either pull out a redirect or the request body
      script =  if location = erase_redirect_results
                  "document.location.href = #{location.to_s.inspect}"
      else
        response.body
      end
      
      # Escape quotes, linebreaks and slashes, maintaining previously escaped slashes
      # Suggestions for improvement?
      script = (script || '').
      gsub('\\', '\\\\\\').
      gsub(/\r\n|\r|\n/, '\\n').
      gsub(/['"]/, '\\\\\&').
      gsub('</script>','</scr"+"ipt>')
      
      # Clear out the previous render to prevent double render
      erase_results
      
      # Eval in parent scope and replace document location of this frame 
      # so back button doesn't replay action on targeted forms
      # loc = document.location to be set after parent is updated for IE
      # with(window.parent) - pull in variables from parent window
      # setTimeout - scope the execution in the windows parent for safari
      # window.eval - legal eval for Opera
      render :text => %Q[<html><body><script type='text/javascript' charset='utf-8'>
          with(window.parent) { Element.update(document.getElementById("file_list"), "max11"); } // FF, not Saf3
//            parent.document.getElementById('file_list').innerHTML = 'Max10' //Ok FF, Saf3
//          Element.update(parent.document.getElementById("file_list"), "max9");  // Not FF, not Saf3 (No Prototype in iFrame)
//          alert(parent.document.getElementById('file_list').innerHTML) //Ok FF, Saf3
//          with(window.parent) { window.eval('Element.update(parent.document.getElementById("file_list"), "max8");'); } // FF, not Saf3
//          with(window.parent) { setTimeout(function() { window.eval('Element.update("file_list", "max7");'); }, 1000) } // FF, not Saf3
//          with(window.parent) { window.eval('Element.update("file_list", "max7");'); } // FF, Saf2 not Saf3
//          with(window.parent) { window.eval('Element.update(document.getElementById("file_list"), "max6");'); } // Works on FF, and Safari 2.0.4 but silently ignored in Safari 3.0.3
//          with(window.parent) { window.eval(\"alert($('file_list'))\"); } // Works on both
//          alert($('test_id')); // Neither can find since Prototype not defined in iFrame
//          with(window.parent) { alert($('file_list')); } // Works on both FF and Safari
//          with(window.parent) { alert(document.getElementById('file_list').id); }  // Works on both
//          alert(parent.document.body.innerHTML)
//          with(window.parent) { alert(document.body.innerHTML); }
//        with(window.parent) { window.eval('#{script}'); } 

//        var loc = document.location;
//        with(window.parent) { setTimeout(function() { window.eval('#{script}'); }, 1) } 
//        loc.replace('about:blank');
      </script>
      <div id='test_id'>
      Hello from iFrame div 'test_id'
      </div>
      </body></html>]
    end
    #      render :text => "<html><body><script type='text/javascript' charset='utf-8'>
    #        var loc = document.location;
    #        with(window.parent) { setTimeout(function() { window.eval('#{script}'); loc.replace('about:blank'); }, 1) } 
    #      </script></body></html>"
  end
  
end
