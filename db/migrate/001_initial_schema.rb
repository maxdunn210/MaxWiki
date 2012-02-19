class InitialSchema < ActiveRecord::Migration
  def self.up
    
    create_table "adults" do |t|
      t.column "email", :string, :limit => 60, :default => ""
      t.column "firstname", :string, :limit => 50
      t.column "lastname", :string, :limit => 50
      t.column "household_id", :integer, :default => 0
      t.column "home_phone", :string, :limit => 20
      t.column "work_phone", :string, :limit => 20
      t.column "cell_phone", :string, :limit => 20
      t.column "relationship", :string, :limit => 50
      t.column "adultnum", :integer, :default => 0
      t.column "login", :string, :limit => 80, :default => "", :null => false
      t.column "salted_password", :string, :limit => 40, :default => "", :null => false
      t.column "salt", :string, :limit => 40, :default => "", :null => false
      t.column "verified", :integer, :default => 0
      t.column "role", :string, :limit => 40
      t.column "security_token", :string, :limit => 40
      t.column "token_expiry", :datetime
      t.column "deleted", :integer, :default => 0
      t.column "delete_after", :datetime
    end
    
    create_table "doctors" do |t|
      t.column "household_id", :integer, :default => 0
      t.column "healthplan", :string, :limit => 100, :default => "", :null => false
      t.column "policy_num", :string, :limit => 40, :default => "", :null => false
      t.column "physician_name", :string, :limit => 50, :default => "", :null => false
      t.column "physician_tel", :string, :limit => 50, :default => "", :null => false
      t.column "physician_addr", :string, :limit => 100, :default => "", :null => false
    end
    
    create_table "households" do |t|
      t.column "address", :string, :limit => 100
      t.column "city", :string, :limit => 100
      t.column "zip", :string, :limit => 20
      t.column "session_id", :string, :limit => 80
    end
    
    create_table "pages" do |t|
      t.column "created_at", :datetime, :null => false
      t.column "updated_at", :datetime, :null => false
      t.column "web_id", :integer, :null => false
      t.column "locked_by", :string, :limit => 60
      t.column "name", :string, :limit => 60
      t.column "locked_at", :datetime
    end
    
    create_table "players" do |t|
      t.column "household_id", :integer, :default => 0
      t.column "firstname", :string, :limit => 50, :default => "", :null => false
      t.column "lastname", :string, :limit => 50, :default => "", :null => false
      t.column "birthday", :date, :null => false
      t.column "years_exp", :integer
      t.column "lastlevel", :string, :limit => 20
      t.column "grade", :string, :limit => 20
      t.column "school", :string, :limit => 40
      t.column "teacher", :string, :limit => 40
      t.column "note", :string
      t.column "shirtsize", :string, :limit => 20
      t.column "pantsize", :string, :limit => 20
      t.column "limitation", :string, :limit => 100
      t.column "allergies", :string, :limit => 100, :default => "", :null => false
      t.column "age_checked", :boolean
      t.column "waiver_required", :boolean
      t.column "fee_paid", :float, :default => 0.0
      t.column "fee_paid_on", :date
      t.column "fee_paid_by", :string
      t.column "created_at", :datetime
      t.column "updated_at", :datetime
      t.column "referred_by", :string
    end
    
    create_table "revisions" do |t|
      t.column "created_at", :datetime, :null => false
      t.column "updated_at", :datetime, :null => false
      t.column "revised_at", :datetime, :null => false
      t.column "page_id", :integer, :null => false
      t.column "content", :text, :limit => 10000000, :null => false
      t.column "author", :string, :limit => 60
      t.column "ip", :string, :limit => 60
    end
    
    add_index "revisions", ["page_id"], :name => "revisions_page_id_index"
    add_index "revisions", ["created_at"], :name => "revisions_created_at_index"
    add_index "revisions", ["author"], :name => "revisions_author_index"
    
    create_table "sessions" do |t|
      t.column "session_id", :string
      if ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
        t.column "data", :binary
      else
        t.column "data", :binary, :limit => 10.megabyte
      end
      t.column "updated_at", :datetime
    end
    
    add_index "sessions", ["session_id"], :name => "sessions_session_id_index"
    
    create_table "system" do |t|
      t.column "password", :string, :limit => 60
    end
    
    create_table "users" do |t|
      t.column "adult_id", :integer, :default => 0, :null => false
      t.column "login", :string, :limit => 80, :default => "", :null => false
      t.column "email", :string, :limit => 80, :default => "", :null => false
      t.column "salted_password", :string, :limit => 40, :default => "", :null => false
      t.column "salt", :string, :limit => 40, :default => "", :null => false
      t.column "verified", :integer, :default => 0
      t.column "role", :string, :limit => 40
      t.column "security_token", :string, :limit => 40
      t.column "token_expiry", :datetime
      t.column "deleted", :integer, :default => 0
      t.column "delete_after", :datetime
    end
    
    create_table "webs" do |t|
      t.column "created_at", :datetime, :null => false
      t.column "updated_at", :datetime, :null => false
      t.column "name", :string, :limit => 60, :null => false
      t.column "address", :string, :limit => 60, :null => false
      t.column "password", :string, :limit => 60
      t.column "additional_style", :string
      t.column "allow_uploads", :integer, :default => 1
      t.column "published", :integer, :default => 0
      t.column "count_pages", :integer, :default => 0
      t.column "markup", :string, :limit => 50, :default => "textile"
      t.column "color", :string, :limit => 6, :default => "008B26"
      t.column "max_upload_size", :integer, :default => 100
      t.column "safe_mode", :integer, :default => 0
      t.column "brackets_only", :integer, :default => 0
    end
    
    create_table "wiki_files" do |t|
      t.column "created_at", :datetime, :null => false
      t.column "updated_at", :datetime, :null => false
      t.column "web_id", :integer
      t.column "file_name", :string
      t.column "description", :string
    end
    
    create_table "wiki_references" do |t|
      t.column "created_at", :datetime, :null => false
      t.column "updated_at", :datetime, :null => false
      t.column "page_id", :integer, :null => false
      t.column "referenced_name", :string, :limit => 60, :null => false
      t.column "link_type", :string, :limit => 1, :null => false
    end
    
    add_index "wiki_references", ["page_id"], :name => "wiki_references_page_id_index"
    add_index "wiki_references", ["referenced_name"], :name => "wiki_references_referenced_name_index"
    
  end
  
  def self.down
  end
end
