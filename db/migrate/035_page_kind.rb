class PageKind < ActiveRecord::Migration
  def self.up
    rename_column :pages, "add_title", "kind"
    Page.reset_column_information
    
    puts "Updating page kinds"
    pages = Page.find(:all)
    Page.transaction do
      pages.each do |page|
        kind = case page.kind 
          when 'Normal', 'normal', 'titled': 'Titled'
          when 'Blog', 'blog', 'post': 'Post'
          else nil
        end  
        unless kind.nil?  
          page.kind = kind
          page.save!
        end  
      end    
    end
  end
  
  def self.down
    puts "Reverting page kinds"
    pages = Page.find(:all)
    Page.transaction do
      pages.each do |page|
        kind = case page.kind 
          when 'Titled', 'titled': 'Normal'
          when 'Post', 'post': 'Blog'
          else nil
        end  
        unless kind.nil?  
          page.kind = kind
          page.save!
        end  
      end    
    end

    rename_column :pages, "kind", "add_title"
  end
end
