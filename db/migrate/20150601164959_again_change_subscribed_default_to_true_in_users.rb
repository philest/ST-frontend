class AgainChangeSubscribedDefaultToTrueInUsers < ActiveRecord::Migration
  def change
  	  	change_column_default :users, :subscribed, true
  end
end
