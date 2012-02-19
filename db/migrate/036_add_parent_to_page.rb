class AddParentToPage < ActiveRecord::Migration
  
  def self.up
    add_column :pages, "parent_id", :integer
    Page.reset_column_information
    
    #Move over the parent page references from WikiReference to Page
    puts "Moving parent references"
    parent_references = WikiReference.find(:all,:conditions => {:link_type => 'P'})
    Page.transaction do
      parent_references.each do |ref|
        page = Page.find(ref.page_id) rescue nil
        if page
          parent_page = Page.find(:first, :conditions => {:name => ref.referenced_name, :wiki_id => page.wiki_id})
          if parent_page
            page.parent_id = parent_page.id
            page.save!
          end
        end
      end
    end
  end
  
  def self.down
    remove_column :pages, "parent_id"
  end
end