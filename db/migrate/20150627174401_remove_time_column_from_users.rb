class RemoveTimeColumnFromUsers < ActiveRecord::Migration
  def self.up
    remove_column :users, :time
  end

  def self.down
    add_column :users, :time, :string
  end

end
