require_relative 'auth.rb'

class Teacher < Sequel::Model(:teachers)
  include AuthenticateModel

  plugin :timestamps, :create=>:enrolled_on, :update=>:updated_at, :update_on_create=>true
  plugin :validation_helpers
  plugin :association_dependencies
  plugin :json_serializer

  many_to_one :school
  one_to_many :classrooms
  one_to_many :users

  add_association_dependencies users: :nullify

  def quicklink
    if email and signature and self.school
      "#{ENV['STORYTIME_URL']}/signin?email=#{email}&digest=#{self.password_digest}&role=teacher"
    else
      ''
    end
  rescue => e
    p e + " -> possibly missing a teacher field."
  end


  def signup_user(user)
    # write this method
    self.add_user(user)
    
    if self.school != nil
      self.school.add_user(user)
    end
  end

  def validate
    super
    validates_unique :phone, :allow_nil=>true, :message => "phone #{phone} is already taken (teachers)"
    validates_unique :email, :allow_nil=>true, :message => "email #{email} is already taken (teachers)"
    validates_unique :fb_id, :allow_nil=>true, :message => "fb_id #{fb_id} is already taken (teachers)"
  end

end