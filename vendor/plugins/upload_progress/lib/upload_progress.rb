module UploadProgress
  def self.append_features(base) #:nodoc:
    super
    base.extend(ClassMethods)
    base.helper_method :upload_progress, :next_upload_id, :last_upload_id, :current_upload_id
  end

  # == Action Pack Upload Progress for multipart uploads
  #
  # The UploadProgress module aids in the process of viewing an Ajax driven
  # upload status when working with multipart forms.  It offers a macro that
  # will prepare an action for handling the cleanup of the Ajax updating including
  # passing the redirect URL and custom parameters to the Javascript finish handler.
  #
  # UploadProgress is available for all multipart uploads when the +upload_status_for+
  # macro is called in one of your controllers.
  #
  # The progress is stored as an UploadProgress::Progress object in the session and
  # is accessible in the controller and view with the +upload_progress+ method.
  #
  # For help rendering the UploadProgress enabled form and supported elements, see
  # ActionView::Helpers::UploadProgressHelper.
  # 
  # === Automatic updating on upload actions
  #
  #   class DocumentController < ApplicationController   
  #     upload_status_for  :create
  #     
  #     def create
  #       # ... Your document creation action
  #     end
  #   end
  #
  # The +upload_status_for+ macro will override the rendering of the action passed
  # if +upload_id+ is found in the query string.  This allows for default
  # behavior if Javascript is disabled.  If you are tracking the upload progress
  # then +create+ will now return the cleanup scripts that will terminate the polling
  # of the upload status.
  #
  # === Customized status rendering
  #
  #   class DocumentController < ApplicationController   
  #     upload_status_for  :create, :status => :custom_status
  #     
  #     def create
  #       # ... Your document creation action
  #     end
  #
  #     def custom_status
  #       # ... Override this action to return content to be replaced in
  #       # the status container
  #       render :inline => "<%= upload_progress.completed_percent rescue 0 %> % complete", :layout => false
  #   end
  #
  # The default status action is +upload_status+.  The results of this action
  # are added used to replace the contents of the HTML elements defined in
  # +upload_status_tag+.  Within +upload_status+, you can load the Progress
  # object from the session with the +upload_progress+ method and display your own
  # results.  
  #
  # Completion of the upload status updating occurs automatically with an +after_filter+ call to
  # +finish_upload_status+.  Because the upload must be posted into a hidden IFRAME to enable
  # Ajax updates during the upload, +finish_upload_status+ overwrites the results of any previous
  # +render+ or +redirect_to+ so it can render the necessary Javascript that will properly terminate 
  # the status updating loop, trigger the completion callback or redirect to the appropriate URL.
  #
  # ==== Basic Example (View):
  #
  #  <%= form_tag_with_upload_progress({:action => 'create'}, {:finish => 'alert("Document Uploaded")'}) %>
  #  <%= upload_status_tag %>
  #  <%= file_field 'document', 'file' %>
  #  <%= end_form_tag %>
  #
  # ==== Basic Example (Controller):
  #
  #  class DocumentController < ApplicationController
  #    upload_status_for :create
  #
  #    def create
  #      @document = Document.create(params[:document])
  #    end
  #  end
  #
  # ==== Extended Example (View):
  #
  #  <%= form_tag_with_upload_progress({:action => 'create'}, {}, {:action => :custom_status}) %>
  #  <%= upload_status_tag %>
  #  <%= file_field 'document', 'file' %>
  #  <%= submit_tag "Upload" %>
  #  <%= end_form_tag %>
  #
  #  <%= form_tag_with_upload_progress({:action => 'add_preview'}, {:finish => 'alert(arguments[0])'}, {:action => :custom_status})  %>
  #  <%= upload_status_tag %>
  #  <%= submit_tag "Upload" %>
  #  <%= file_field 'preview', 'file' %>
  #  <%= end_form_tag %>
  #
  # ==== Extended Example (Controller):
  #
  #  class DocumentController < ApplicationController
  #    upload_status_for :add_preview, :create, {:status => :custom_status}
  #
  #    def add_preview
  #     @document = Document.find(params[:id])
  #     @document.preview = Preview.create(params[:preview])
  #     if @document.save
  #       finish_upload_status "'Preview added'"
  #     else
  #       finish_upload_status "'Preview not added'"
  #     end
  #    end
  #
  #   def create
  #     @document = Document.new(params[:document])
  #
  #     upload_progress.message = "Processing document..."
  #     session.update
  #
  #     @document.save
  #     redirect_to :action => 'show', :id => @document.id
  #   end
  #
  #   def custom_status
  #     render :inline => '<%= upload_progress_status %> <div>Updated at <%= Time.now %></div>', :layout => false
  #   end
  #
  # ==== Environment checklist
  #
  # This is an experimental feature that requires a specific webserver environment.  Use the following checklist 
  # to confirm that you have an environment that supports upload progress.
  #
  # ===== Ruby:
  # 
  # * Running the command `ruby -v` should print "ruby 1.8.2 (2004-12-25)" or older
  # 
  # ===== Web server:
  # 
  # * Apache 1.3, Apache 2.0 or Lighttpd *1.4* (need to build lighttpd from CVS)
  # 
  # ===== FastCGI bindings:
  # 
  # * > 0.8.6 and must be the compiled C version of the bindings
  # * The command `ruby -e "p require('fcgi.so')"` should print "true"
  # 
  # ===== Apache/Lighttpd FastCGI directives:
  # 
  # * You must allow more than one FCGI server process to allow concurrent requests.
  # * If there is only a single FCGI process you will not get the upload status updates.
  # * You can check this by taking a look for running FCGI servers in your process list during a progress upload.
  # * Apache directive: FastCGIConfig -minProcesses 2
  # * Lighttpd directives taken from config/lighttpd.conf (min-procs):
  # 
  #     fastcgi.server = (
  #      ".fcgi" => (
  #       "APP_NAME" => (
  #        "socket" => "/tmp/APP_NAME1.socket",
  #        "bin-path" => "RAILS_ROOT/public/dispatch.fcgi",
  #        "min-procs" => 2
  #       )
  #      )
  #     )
  # 
  # ===== config/environment.rb:
  # 
  # * Add the following line to your config/environment.rb and restart your web server.
  # * <tt>ActionController::Base.enable_upload_progress</tt>
  # 
  # ===== Development log:
  # 
  # * When the upload progress is enabled by you will find something the following lines:
  # * "Multipart upload with progress (id: 1, size: 85464)"
  # * "Finished processing multipart upload in 0.363729s"
  # * If you are properly running multiple FCGI processes, then you will see multiple entries for rendering the "upload_status" action before the "Finish processing..." log entry.  This is a *good thing* :)
  #
  module ClassMethods
    # Creates an +after_filter+ which will call +finish_upload_status+
    # creating the document that will be loaded into the hidden IFRAME, terminating
    # the status polling forms created with +form_with_upload_progress+.
    #
    # Also defines an action +upload_status+ or a action name passed as
    # the <tt>:status</tt> option.  This status action must match the one expected
    # in the +form_tag_with_upload_progress+ helper.
    #
    def upload_status_for(*actions)
      after_filter :finish_upload_status, :only => actions
      
      define_method(actions.last.is_a?(Hash) && actions.last[:status] || :upload_status) do
        render(:inline => '<%= upload_progress_status %>', :layout => false)
      end
    end
  end

  # Overwrites the body rendered if the upload comes from a form that tracks
  # the progress of the upload.  After clearing the body and any redirects, this
  # method then renders the helper +finish_upload_status+
  #
  # This method only needs to be called if you wish to pass a
  # javascript parameter to your finish event handler that you optionally
  # define in +form_with_upload_progress+
  #
  # === Parameter:
  #
  # client_js_argument:: a string containing a Javascript expression that will
  #                      be evaluated and passed to your +finish+ handler of
  #                      +form_tag_with_upload_progress+.
  #
  # You can pass a String, Number or Boolean.
  #
  # === Strings
  #
  # Strings contain Javascript code that will be evaluated on the client. If you 
  # wish to pass a string to the client finish callback, you will need to include 
  # quotes in the +client_js_argument+ you pass to this method.
  #
  # ==== Example
  #
  #   finish_upload_status("\"Finished\"")
  #   finish_upload_status("'Finished #{@document.title}'")
  #   finish_upload_status("{success: true, message: 'Done!'}")
  #   finish_upload_status("function() { alert('Uploaded!'); }")
  #
  # === Numbers / Booleans
  #
  # Numbers and Booleans can either be passed as Number objects or string versions 
  # of number objects as they are evaluated by Javascript the same way as in Ruby.
  #
  # ==== Example
  #
  #   finish_upload_status(0)
  #   finish_upload_status(@document.file.size)
  #   finish_upload_status("10")
  #
  # === Nil
  #
  # To pass +nil+ to the finish callback, use a string "undefined"
  #
  # ==== Example
  #
  #   finish_upload_status(@message || "undefined")
  #
  # == Redirection
  #
  # If you action performs a redirection then +finish_upload_status+ will recognize
  # the redirection and properly create the Javascript to perform the redirection in
  # the proper location.
  #
  # It is possible to redirect and pass a parameter to the finish callback.
  #
  # ==== Example
  #
  #   redirect_to :action => 'show', :id => @document.id
  #   finish_upload_status("'Redirecting you to your new file'")
  #
  #
  def finish_upload_status(client_js_argument='')
    if not @rendered_finish_upload_status and params[:upload_id]
      @rendered_finish_upload_status = true

      erase_render_results
      location = erase_redirect_results || ''

      ## TODO determine if #inspect is the appropriate way to marshall values
      ## in inline templates

      template = "<%= finish_upload_status({"
      template << ":client_js_argument => #{client_js_argument.inspect}, "
      template << ":redirect_to => #{location.to_s.inspect}, "
      template << "}) %>"
      render({ :inline => template, :layout => false })
    end
  end

  # Returns and saves the next unique +upload_id+ in the instance variable
  # <tt>@upload_id</tt>
  def next_upload_id
    @upload_id = last_upload_id.succ
  end

  # Either returns the last saved +upload_id+ or looks in the session
  # for the last used +upload_id+ and saves it as the intance variable
  # <tt>@upload_id</tt>
  def last_upload_id
    @upload_id ||= ((session[:uploads] || {}).keys.map{|k| k.to_i}.sort.last || 0).to_s
  end

  # Returns the +upload_id+ from the query parameters or if it cannot be found
  # in the query parameters, then return the +last_upload_id+
  def current_upload_id
    params[:upload_id] or last_upload_id
  end
  
  # Get the UploadProgress::Progress object for the supplied +upload_id+ from the
  # session. If no +upload_id+ is given, then use the +current_upload_id+
  #
  # If an UploadProgress::Progress object cannot be found, a new instance will be
  # returned with <code>total_bytes == 0</code>, <code>started? == false</code>, 
  # and <code>finished? == true</code>.
  def upload_progress(upload_id = nil)
    upload_id ||= current_upload_id
    session[:uploads] && session[:uploads][upload_id] || UploadProgress::Progress.new(0)
  end
end
