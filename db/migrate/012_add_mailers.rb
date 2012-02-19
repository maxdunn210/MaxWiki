class AddMailers < ActiveRecord::Migration
  def self.up
    create_table "mailers", :force => false do |t|
      t.column "name", :string
      t.column "subject", :string
      t.column "page", :string
      t.column "additional_filter", :string
      t.column "mailer_group_id", :integer
    end

    create_table "mailer_groups", :force => false do |t|
      t.column "name", :string, :length => 40
      t.column "description", :string
      t.column "user_filter", :string
      t.column "auto_subscribe", :boolean
    end
    
    create_table "mailer_subscriptions", :force => false do |t|
      t.column "user_id", :integer
      t.column "mailer_group_id", :integer
      t.column "subscribed", :boolean
      t.column "updated_at", :datetime
      t.column "updated_by", :string
    end

    create_table "emails", :force => false do |t|
      t.column "mailer_id", :integer
      t.column "user_id", :integer
      t.column "status", :string
      t.column "created_at", :datetime
      t.column "updated_at", :datetime
      #ar_mailer columns
      t.column :from, :string
      t.column :to, :string
      t.column :last_send_attempt, :integer, :default => 0
      t.column :mail, :text      
    end
  end

  def self.down
    drop_table "mailers"
    drop_table "mailer_groups"
    drop_table "mailer_subscriptions"
    drop_table "emails"
  end
end
