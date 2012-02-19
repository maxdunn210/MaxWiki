class TestController < ApplicationController

  def index
  end

  def fckeditor
    session[:fcktext] ||= 'This is some <strong>sample TEXT<\/strong>'
    @text = session[:fcktext]
  end

  def done
    @text = params[:content]        
    session[:fcktext] = @text if params[:content]
    puts session[:fcktext]
    redirect_to :action => 'index'
  end

  def drag_and_drop_media
  end
    
end