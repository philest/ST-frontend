class ChangeDefaultOfSubscribedInUsers < ActiveRecord::Migration
  def change
  	change_column_default :users, :subscribed, false
  end
end
