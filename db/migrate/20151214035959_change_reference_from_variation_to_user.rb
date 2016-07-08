class ChangeReferenceFromVariationToUser < ActiveRecord::Migration
  def change
  	add_reference :users, :variation, index: true
  end
end
