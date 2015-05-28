class AddStoryNumberToUsers < ActiveRecord::Migration
  def change
  		add_column :users, :story_number, :integer, default: 0

  end
end
