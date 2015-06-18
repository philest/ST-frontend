class AddSampleToUsers < ActiveRecord::Migration
  def change
  	add_column :users, :sample, :boolean, default: false
  end
end
