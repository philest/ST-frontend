class AddLastFeedbackToUsers < ActiveRecord::Migration
  def change
  	add_column :users, :last_feedback, :integer, default: -1
  end
end
