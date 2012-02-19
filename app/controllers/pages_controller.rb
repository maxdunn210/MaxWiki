class PagesController < ApplicationController

  layout 'main'  
  before_filter :authorize_admin  
  
  def edit
    @page = Page.find(params[:id])
    @last = @page.revisions.last
    @first = @page.revisions.first
  end

  def update
    params[:first][:author] = Author.new(params[:first][:author]) if params[:first] && params[:first][:author]
    params[:last][:author] = Author.new(params[:last][:author]) if params[:last] && params[:last][:author]

    page = Page.find(params[:id])    
    if page.update_attributes(params[:page]) && 
      page.revisions.first.update_attributes(params[:first]) &&
      page.revisions.last.update_attributes(params[:last])
      flash[:notice] = "#{page.name} was successfully updated."
      redirect_to :controller => 'wiki', :action => params[:return_to] || 'list'
    else
      render :action => 'edit'
    end
  end
  
  #-------------
  private
  
  def fix_author(author)
    author = Author.new(author.to_s) unless author.blank?
  end

end
