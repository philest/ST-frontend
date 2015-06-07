class AddDaysPerWeekToUsers < ActiveRecord::Migration
  def change
 	  	add_column :users, :days_per_week, :integer
  end
end
