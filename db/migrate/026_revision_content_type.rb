class RevisionContentType < ActiveRecord::Migration
  def self.up
    add_column :revisions, "content_type", :string
  end
  
  def self.down
    remove_column :revisions, "content_type"
  end
end
