class UpdatePlayers < ActiveRecord::Migration
  def self.up
      add_column :players, "address_checked", :boolean, :default => false
      add_column :players, "form_printed", :boolean, :default => false
      add_column :players, "signed_form_received", :boolean, :default => false
  end

  def self.down
  end
end
