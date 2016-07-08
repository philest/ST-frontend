class AddDefaultToChildAgeAndTimeInUsers < ActiveRecord::Migration
  def change
    	change_column_default :users, :child_age, 4
  	  	change_column_default :users, :time, "5:00pm"

  end
end
