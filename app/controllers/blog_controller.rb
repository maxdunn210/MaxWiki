class BlogController < ApplicationController 
  
  def show
    @post_parent = params[:parent]
    page = (params[:page] ||= 1).to_i
    
    items_per_page = MY_CONFIG[:blog_posts_per_page]
    offset = (page - 1) * items_per_page
    
    @posts = WillPaginate::Collection.create(page, items_per_page) do |pager|
      pages = @wiki.read_page_by_link(@post_parent).children.sort_by {|p| p.created_at}.reverse rescue []
      authorized_pages!(pages)

      pager.replace(pages[offset..(offset + items_per_page - 1)])
      pager.total_entries = pages.size
    end
    
    render :action => 'blog', :layout => !params[:no_layout]
  end
  
end     