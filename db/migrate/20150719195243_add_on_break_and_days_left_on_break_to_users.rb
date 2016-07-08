class AddOnBreakAndDaysLeftOnBreakToUsers < ActiveRecord::Migration
  def change
  	add_column :users, :on_break, :boolean, default: false
  	add_column :users, :days_left_on_break, :integer
  end
end
