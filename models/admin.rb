require_relative 'auth.rb'

class Admin < Sequel::Model(:admins)
  include AuthenticateModel
  plugin :timestamps, :create=>:enrolled_on, :update=>:updated_at, :update_on_create=>true
  plugin :validation_helpers
  plugin :association_dependencies
  plugin :json_serializer

  many_to_one :school

  def quicklink
    if email and signature and self.school
      "#{ENV['STORYTIME_URL']}/signin?email=#{email}&digest=#{self.password_digest}&role=admin"
    else
      ''
    end
  rescue => e
    p e + " -> possibly missing an admin field."
  end


  def validate
    super
    validates_unique :phone, :allow_nil=>true, :message => "#{phone} is already taken (admin)"
    validates_unique :email, :allow_nil=>true, :message => "#{email} is already taken (admin)"
  end

end