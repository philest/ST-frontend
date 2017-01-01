class District < Sequel::Model(:districts)
	plugin :timestamps, :create=>:created_at, :update=>:updated_at, :update_on_create=>true
	one_to_many :schools
end