class AddSeriesNumberAndSeriesChoiceAndNextIndexInSeriesAndAwaitingChoiceToUsers < ActiveRecord::Migration
  def change
  	add_column :users, :series_number, :integer, default: 0
  	add_column :users, :series_choice, :string, default: nil
  	add_column :users, :next_index_in_series, :integer, default: nil
  	add_column :users, :awaiting_choice, :boolean, default: false
  end
end
