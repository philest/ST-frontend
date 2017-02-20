class FreemiumSchool < Sequel::Model(:freemium_schools)
  plugin :timestamps, :create=>:created_at, :update=>:updated_at, :update_on_create=>true
  plugin :json_serializer
end