class AddPageLink < ActiveRecord::Migration
  
  def self.up
    add_column :pages, "link", :string
    Page.reset_column_information
    create_links
  end
  
  def self.down
    remove_column :pages, "link"
  end
  
  def self.create_links
    puts "Creating links"
    pages = Page.find(:all)
    Page.transaction do
      pages.each do |page|
        if page.name == 'HomePage'
          page.link = 'homepage'
        elsif page.name.blank?
          page.link = ''
        else  
          page.link = CGI.escape(page.name)
        end  
        page.save!
      end
    end
  end
  
end