class Authorization
  
  # Error types: 
  NOT_FOUND = :not_found
  NOT_AUTHORIZED = :not_authorized
  NOT_SETUP = :not_setup
  UNKNOWN = :unknown
  
  attr_writer :error
  attr_accessor :error_type, :error_msg, :attributes, :user
  
  def error?
    @error
  end
  
  def set_error(error, msg = nil)
    @error = true
    @error_type = error
    case @error_type
    when NOT_FOUND then @error_msg = msg || 'Not found'
    when NOT_AUTHORIZED then @error_msg = msg || 'Not authorized'
    when NOT_SETUP then @error_msg = msg || 'Not setup'
    else
      @error_type = UNKNOWN
      @error_msg = msg || "Unknown"
    end
  end
end