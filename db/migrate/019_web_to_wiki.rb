class WebToWiki < ActiveRecord::Migration

  TABLES = [:adults, :doctors, :emails, :events, :households, :lookups, :mailer_groups, :mailer_subscriptions,
    :mailers, :players, :revisions, :stored_files, :survey_answers, :survey_questions, :surveys,
    :teams, :wiki_references]
    
  def self.up
    rename_table :webs, :wikis
    rename_column :wiki_files, :web_id, :wiki_id
    rename_column :pages, :web_id, :wiki_id
    
    TABLES.each do |table|
      add_column table, :wiki_id, :integer
    end
    
    Wiki.reset_column_information
    wiki = Wiki.find(:first)
    unless wiki.nil?
      wiki_id = wiki.id
      sql = ActiveRecord::Base.connection()
      
      TABLES.each do |table|
        sql.update "UPDATE #{table.to_s} SET wiki_id=#{wiki_id}"
      end  
    end  
  end

  def self.down
    rename_table :wikis, :webs
    rename_column :wiki_files, :wiki_id, :web_id
    rename_column :pages, :wiki_id, :web_id

    TABLES.each do |table|
      remove_column table, :wiki_id
    end
  end
end
