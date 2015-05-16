class AddChildBirthdateToUsers < ActiveRecord::Migration
  def change
  	add_column :users, :child_birthdate, :string
  	add_column :users, :time, :string
  end
end
