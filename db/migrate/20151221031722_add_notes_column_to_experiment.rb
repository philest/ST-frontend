class AddNotesColumnToExperiment < ActiveRecord::Migration
  def change
  	add_column :experiments, :notes, :text
  end
end
