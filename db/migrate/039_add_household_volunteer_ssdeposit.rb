class AddHouseholdVolunteerSsdeposit < ActiveRecord::Migration
  def self.up
    add_column :households, "volunteer_feepaid", :float, :default => 0.0
    add_column :households, "volunteer_feepaid_on", :date
    add_column :households, "volunteer_feepaid_by", :string, :limit => 20, :default => ""
    add_column :households, "snackshack_deposit", :float, :default => 0.0
    add_column :households, "snackshack_depositpaid_on", :date
    add_column :households, "snackshack_depositpaid_by", :string, :limit => 20, :default => ""
    add_column :households, "snackshack_refund", :float, :default => 0.0
    add_column :households, "snackshack_refunded_on", :date
    add_column :households, "snackshack_refunded_by", :string, :limit => 20, :default => ""
  end

  def self.down
    remove_column :households, "volunteer_feepaid"
    remove_column :households, "volunteer_feepaid_on"
    remove_column :households, "volunteer_feepaid_by"
    remove_column :households, "snackshack_deposit"
    remove_column :households, "snackshack_depositpaid_on"
    remove_column :households, "snackshack_depositpaid_by"
    remove_column :households, "snackshack_refund"
    remove_column :households, "snackshack_refunded_on"
    remove_column :households, "snackshack_refunded_by"
  end
end
