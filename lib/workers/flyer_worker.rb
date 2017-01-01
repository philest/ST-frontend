require_relative '../generate_phone_image'

class FlyerWorker
  include Sidekiq::Worker
  def perform(teacher_id, school_id)
    teacher = Teacher.where(id: teacher_id).first
    school  = School.where(id: school_id).first

    PhoneImage.new.create_image(teacher, school)
    FlyerImage.new.create_image(teacher, school)
  end
end