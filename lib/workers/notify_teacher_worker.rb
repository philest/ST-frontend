require 'createsend'
require 'sidekiq'
require 'dotenv'
require_relative 'flyer_worker'
Dotenv.load if ENV['RACK_ENV'] != 'production'

class UpdateAdminWorker
  include Sidekiq::Worker

  def perform(sig, email, count, teacher_or_teachers, list_o_names, quicklink)
     # Authenticate with your API key
    auth = { :api_key => ENV['CREATESEND_API_KEY'] }
    # The unique identifier for this smart email
    smart_email_id = '60c02c03-6d38-4da3-9d32-1da835606dcd'

    # Create a new mailer and define your message
    tx_smart_mailer = CreateSend::Transactional::SmartEmail.new(auth, smart_email_id)

      message = {
        'To' => email,
        'Data' => {
          'adminfirstname' => sig,
          'teacher_count' => count,
          'teacher_or_teachers' => teacher_or_teachers,
          'list_of_teachers' => list_o_names,
          'quicklink' => quicklink
        }
      }
    # Send the message and save the response
    response = tx_smart_mailer.send(message)
  end

end



class UpdateTeacherWorker
  include Sidekiq::Worker

  def perform(sig, email, count, family, list_o_names, quicklink)
     # Authenticate with your API key
    auth = { :api_key => ENV['CREATESEND_API_KEY'] }
    # The unique identifier for this smart email
    smart_email_id = '98b9048d-a381-445e-8d21-65a3a5cb2b37'

    # Create a new mailer and define your message
    tx_smart_mailer = CreateSend::Transactional::SmartEmail.new(auth, smart_email_id)

      message = {
        'To' => email,
        'Data' => {
          'signature' => sig,
          'family_count' => count,
          'family_or_families' => family,
          'list_of_families' => list_o_names,
          'quicklink' => quicklink
        }
      }
    # Send the message and save the response
    response = tx_smart_mailer.send(message)
  end

end

class WelcomeAdminWorker
  include Sidekiq::Worker

  def perform(admin_id)
    admin = Admin.where(id: admin_id).first
    # Authenticate with your API key
    auth = { :api_key => ENV['CREATESEND_API_KEY'] }

    # The unique identifier for this smart email
    smart_email_id = '26f053df-a138-46fd-9c27-b3f336a7d274'

    # Create a new mailer and define your message
    tx_smart_mailer = CreateSend::Transactional::SmartEmail.new(auth, smart_email_id)
    message = {
      'To' => admin.email,
      'Data' => {
        'dash_invite_teachers_link' => admin.quicklink + '&invite=1',
        'quicklink' => admin.quicklink,
        'firstname' => admin.first_name
      }
    }

    puts "sending welcome email to #{admin.signature} - #{admin.email}"
    # Send the message and save the response
    response = tx_smart_mailer.send(message)

  end

end


class WelcomeTeacherWorker
  include Sidekiq::Worker

  def perform(teacher_id)
    teacher = Teacher.where(id: teacher_id).first
    # Authenticate with your API key
    auth = { :api_key => ENV['CREATESEND_API_KEY'] }

    # The unique identifier for this smart email
    smart_email_id = 'a7ad322e-3631-4bf5-af7e-c85ffddbf4fd'

    # Create a new mailer and define your message
    tx_smart_mailer = CreateSend::Transactional::SmartEmail.new(auth, smart_email_id)
    message = {
      'To' => teacher.email,
      'Data' => {
        'flyers_link' => teacher.quicklink + '&flyers=1',
        'quicklink' => teacher.quicklink,
        'signature' => teacher.signature
      }
    }

    puts "sending welcome email to #{teacher.signature} - #{teacher.email}"
    # Send the message and save the response
    response = tx_smart_mailer.send(message)

  end

end

class NotifyTeacherWorker
  include Sidekiq::Worker
  # include CreateSend

  def send_invite(signature, email, school_id, admin_id)
      # Authenticate with your API key
      auth = { :api_key => ENV['CREATESEND_API_KEY'] }

      # The unique identifier for this smart email
      smart_email_id = '83aff537-dabc-4c73-af29-7dbee8dc84a7'

      # Create a new mailer and define your message
      tx_smart_mailer = CreateSend::Transactional::SmartEmail.new(auth, smart_email_id)
      puts "created #{tx_smart_mailer}"

      school = School.where(id: school_id).first
      admin  = Admin.where(id: admin_id).first

      if school and admin
        teacher = Teacher.where(email: email).first
        if teacher.nil?
          teacher = Teacher.create(email: email)
        end
        teacher.update(signature: signature)
        school.signup_teacher(teacher)
        teacher.reload
        FlyerWorker.perform_async(teacher.id, school.id)

        # get the url....
        teacher_dir = signature + "-" + teacher.t_number.to_s
        aws_url = "https://s3.amazonaws.com/teacher-materials/#{school.signature}/#{teacher_dir}/flyers"

        url_english = "#{aws_url}/StoryTime-Invite-Flyer-#{signature}.pdf"
        url_spanish = "#{aws_url}/StoryTime-Invite-Flyer-#{signature}-Spanish.pdf"

        puts "final_url = #{url_english}"

        message = {
          'To' => email,
          'Data' => {
            'adminName' => admin.signature,
            'flyerLink' => url_english,
            'flyerLinkES' => url_spanish,
            'schoolName' => school.signature
          }
        }

        puts "sending notification email to #{signature} - #{email}"

        # Send the message and save the response
        response = tx_smart_mailer.send(message)

      end

  end

  def perform(params)

      25.times do |i|
        signature = params["name_#{i}"]
        email     = params["email_#{i}"]
        if !signature.empty? and !email.empty?
          send_invite(signature, email, params['school_id'], params['admin_id'])
        end
      end

  end # perform


end #class NotifyTeacherWorker