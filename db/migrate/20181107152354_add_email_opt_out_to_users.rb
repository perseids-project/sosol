class AddEmailOptOutToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :email_opt_out, :boolean, :default => false
  end

  def self.down
    remove_column :users, :email_opt_out
  end
end
