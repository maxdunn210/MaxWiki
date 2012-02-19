class RemoveStoredFile < ActiveRecord::Migration
  def self.up
    drop_table "stored_files"
  end
  def self.down
    create_table "stored_files", :force => false do |t|
      t.column "comment", :string
      t.column "name", :string
      t.column "page", :string
      t.column "content_type", :string
      if ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
        t.column "data", :binary
      else
        t.column "data", :binary, :limit => 10.megabyte
      end
      t.column "datasize", :int
      t.column "created_at", :timestamp
    end
  end
end
