class RemoveChildBirthdateChildNameLastFeedbackSetTimeAndSetBirthdateFromUser < ActiveRecord::Migration
  def change
  	remove_column :users, :child_birthdate, :string
  	remove_column :users, :child_name, :string
  	remove_column :users, :last_feedback, :integer
  	remove_column :users, :set_time, :boolean, default: false
  	remove_column :users, :set_birthdate, :boolean, default: false
  end
end
