class AddTotalMessagesToUsers < ActiveRecord::Migration
  def change
  	  	add_column :users, :total_messages, :integer, default: 0
  end
end
