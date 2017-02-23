require_relative 'helpers/auth.rb'
require_relative 'helpers/phone-email.rb'

class Admin < Sequel::Model(:admins)
  include AuthenticateModel
  extend SearchByUsername

  
  plugin :timestamps, :create=>:enrolled_on, :update=>:updated_at, :update_on_create=>true
  plugin :validation_helpers
  plugin :association_dependencies
  plugin :json_serializer

  many_to_one :school

  def quicklink(prod=false)

    st_url = prod ? "https://www.joinstorytime.com" : ENV['STORYTIME_URL']

    st_url = st_url.sub(/^https?\:\/\//, '').sub(/^www./,'')

    username = email
    if email.nil? or email.empty?
      username = phone
    end

    if username and signature and self.school and password_digest
      "#{st_url}/signin?username=#{username}&digest=#{self.password_digest}&role=admin"
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