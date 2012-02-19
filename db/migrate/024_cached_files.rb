class CachedFiles < ActiveRecord::Migration
  def self.up
    add_column :wiki_files, "source_uri", :string      
    add_column :wiki_files, "source_type", :string    
    add_column :wiki_files, "detect_change_marker", :string    
    add_column :wiki_files, "detect_change_type", :string    
    add_column :wiki_files, "cache_path", :string      
    add_column :wiki_files, "converted_path", :string      
    add_column :wiki_files, "converted_type", :string    
    add_column :wiki_files, "refresh_method", :string      
    add_column :wiki_files, "last_check", :datetime
    add_column :wikis, "wiki_file_next_num", :integer, :default => 0
  end

  def self.down
    remove_column :wiki_files, "source_uri"
    remove_column :wiki_files, "source_type"
    remove_column :wiki_files, "detect_change_marker"
    remove_column :wiki_files, "detect_change_type"
    remove_column :wiki_files, "cache_path"
    remove_column :wiki_files, "converted_path"
    remove_column :wiki_files, "converted_type"
    remove_column :wiki_files, "refresh_method"
    remove_column :wiki_files, "last_check"
    remove_column :wikis, "wiki_file_next_num"
  end
end
