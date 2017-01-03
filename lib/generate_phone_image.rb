require 'prawn'
require 'gruff'
require 'fileutils'
require_relative '../config/initializers/aws'

# should phoneImages be stored in the teacher folders? seems a bit excessive for our purposes. 
class PhoneImage

  def create_image(teacher_obj, school_obj)
    img_txt = teacher_obj.code.split('|').first
    teacher = teacher_obj.signature
    school = school_obj.signature

    path = File.expand_path("#{File.dirname(__FILE__)}/phone-text-blank.png")

    canvas = Magick::Image.from_blob(IO.read(path))[0]
    text = Magick::Draw.new
    text.font = File.expand_path("#{File.dirname(__FILE__)}/../public/fonts/AvenirLTStd-Black.otf")
    text.pointsize = 45

    dimensions = text.get_type_metrics(img_txt)

    x_start, x_end = 106, 324
    y_start, y_end = 290, 369

    center = {
      x: (x_start + x_end) / 2.0,
      y: (y_start + y_end) / 2.0
    }

    x = center[:x] - (dimensions.width  / 2.0)
    y = center[:y] + ((dimensions.ascent - dimensions.descent) / 2.0) - 10

    text.annotate(canvas, 106,290,x,y, img_txt) {
      self.fill = 'white'
    }

    # we do the amazon stuff here
    flyers = S3.bucket('teacher-materials')

    if flyers.exists?
        # in case a teacher has multiple classrooms (same signature), use their code to differentiate
        teacher_dir = "#{teacher}-#{teacher_obj.t_number}" 
        name = "#{school}/#{teacher_dir}/phone-imgs/#{img_txt}-phone.png"
        if flyers.object(name).exists?
            puts "#{name} already exists in the bucket"
        else
          obj = flyers.object(name)
          obj.put(body: canvas.to_blob, acl: "public-read")
          puts "Uploaded '%s' to S3!" % name
        end
    end
  end
end 

class FlyerImage

  def create_image(teacher_obj, school_obj)

    puts "DOING THE FLYER IMAGES"

    code = teacher_obj.code
    teacher = teacher_obj.signature
    school = school_obj.signature

    code_en, code_es = code.split('|')

    puts "code_en = #{code_en}"
    puts "code_es = #{code_es}"
    
    # 612 x 792

    # ENGLISH!!!!!!
    tmpfile = File.expand_path("#{File.dirname(__FILE__)}/StoryTime Invite Flyers for #{teacher}'s Class.pdf")
    Prawn::Document.generate(tmpfile, page_size: 'LETTER') do
      bounding_box([12, 720], :width => 512, :height => 720) do
        # stroke_bounds
        dir = File.expand_path(File.dirname(__FILE__))
        puts "dir = #{dir}"
        image dir + "/white-bird.jpg", position: :left, width: 50
        image dir + "/intro-storytime.jpg", at: [55, 705], width: 125

        font_families.update(
          "Karla" => {
            :normal => dir + "/../public/fonts/Karla-Regular.ttf",
            :bold => dir + "/../public/fonts/Karla-Bold.ttf",
            :italic => dir + "/../public/fonts/Karla-Italic.ttf"
          },

          "Avenir" => {
            :normal => dir + "/../public/fonts/avenir-lt-65-medium.ttf",
            :bold => dir + "/../public/fonts/avenir-lt-95-black.ttf",
            :light => dir + "/../public/fonts/AvenirLTStd-Light.ttf"
          }
        )
        # move_up 30
        font("Avenir", style: :bold) do
          font_size 18
          # text_box "STORYTIME", at: [60, 705]
          move_down 20
          font_size 36
          text "Get free books from"
          move_down 5
          text "#{teacher}."
        end

        font("Avenir", style: :light) do
          move_down 20
          font_size 12
          text "Get free books for <b>#{school}</b> sent right to your phone-- no running around.", inline_format: true

          font_size 18
          text_box "On your phone, go to the web link:", width: 180, height: 50, at: [40, 450]
        end

        bounding_box([25, 400], width: 200, height: 50) do
          # stroke_bounds
          font("Avenir", style: :bold) do
            fill_color 'ff0000'
            font_size 18
            text_box "stbooks.org/#{code_en}", valign: :center, align: :center, overflow: :shrink_to_fit, single_line: :true
          end
        end

        stroke do
          stroke_color 'A9A9A9'
          rounded_rectangle [25,400], 200, 50, 5
        end

        # phone image
        image dir + "/phone-no-icon.jpg", at: [250, 500], width: 285

        bounding_box([288, 455], width: 84, height: 12) do
          # stroke_bounds
          fill_color '000000'
          font_size 10
          font("Karla", style: :normal) do
            text_box "stbooks.org/#{code_en}", valign: :center, align: :center, overflow: :shrink_to_fit, single_line: :true
          end
        end

        bounding_box([285, 425], width: 140, height: 18) do
          # stroke_bounds
          fill_color '000000'
          font_size 13
          font("Karla", style: :normal) do
            text_box "Join #{teacher}'s class", valign: :center, align: :center, overflow: :shrink_to_fit, single_line: :true
          end

        end

        image dir + "/complete-by-monday.jpg", at: [40, 220], width: 150

        image dir + "/hero-child.jpg", at: [250, 310], width: 260


        move_down 380
        font_size 10
        font "Avenir", style: :normal 
        text_box "<b>No smartphone?</b> Get stories by text. Text <b><color rgb='ff0000'>#{code_en}</color></b> to the phone number <b><color rgb='ff0000'>(203) 202-3505</color></b>.", at:[25, 40], inline_format: true
      end 
    end # english

    # spanish

    tmpfile_es = File.expand_path("#{File.dirname(__FILE__)}/StoryTime Invite Flyers for #{teacher}'s Class (Spanish).pdf")
    Prawn::Document.generate(tmpfile_es, page_size: 'LETTER') do
      bounding_box([12, 720], :width => 512, :height => 720) do
        # stroke_bounds
        dir = File.expand_path(File.dirname(__FILE__))
        puts "dir = #{dir}"
        image dir + "/white-bird.jpg", position: :left, width: 50
        image dir + "/intro-storytime.jpg", at: [55, 705], width: 125

        font_families.update(
          "Karla" => {
            :normal => dir + "/../public/fonts/Karla-Regular.ttf",
            :bold => dir + "/../public/fonts/Karla-Bold.ttf",
            :italic => dir + "/../public/fonts/Karla-Italic.ttf"
            },


          "Avenir" => {
            :normal => dir + "/../public/fonts/avenir-lt-65-medium.ttf",
            :bold => dir + "/../public/fonts/avenir-lt-95-black.ttf",
            :light => dir + "/../public/fonts/AvenirLTStd-Light.ttf"
          }
        )
        # move_up 30
        font("Avenir", style: :bold) do
          font_size 18
          # text_box "STORYTIME", at: [60, 705]
          move_down 20
          font_size 36
          text "Consigue libros gratis de"
          move_down 5
          text "#{teacher}"
        end

        font("Avenir", style: :light) do
          move_down 20
          font_size 12
          text "Consigue libros de parte de <b>#{school}</b> directamente en su celular.", inline_format: true

          font_size 18
          text_box "En su celular, abre el navegador y usa este enlace:", width: 180, height: 50, at: [40, 450]
        end

        bounding_box([25, 400], width: 200, height: 50) do
          # stroke_bounds
          font("Avenir", style: :bold) do
            fill_color 'ff0000'

            font_size 18
            text_box "stbooks.org/#{code_es}", valign: :center, align: :center, overflow: :shrink_to_fit, single_line: :true
          end
        end

        stroke do
          stroke_color 'A9A9A9'
          rounded_rectangle [25,400], 200, 50, 5
        end

        # phone image
        image dir + "/phone-no-icon.jpg", at: [250, 500], width: 285

        bounding_box([288, 455], width: 84, height: 12) do
          # stroke_bounds
          fill_color '000000'
          font_size 10
          font("Karla", style: :normal) do
            text_box "stbooks.org/#{code_es}", valign: :center, align: :center, overflow: :shrink_to_fit, single_line: :true
          end

        end

        bounding_box([285, 425], width: 140, height: 18) do
          # stroke_bounds
          fill_color '000000'
          font_size 13
          font("Karla", style: :normal) do
            text_box "Anótate en la clase de #{teacher}", valign: :center, align: :center, overflow: :shrink_to_fit, single_line: :true
          end

        end

        image dir + "/spanish-complete-by-monday.jpg", at: [40, 220], width: 150

        image dir + "/luna.jpg", at: [255, 310], width: 230

        move_down 380
        font_size 10
        font "Avenir", style: :normal 
        text_box "<b>¿No tiene un smartphone?</b> Consigue libros de mensaje. Mensajéa <b><color rgb='ff0000'>#{code_es}</color></b> al numero <b><color rgb='ff0000'>(203) 202-3505</color></b>.", at:[25, 30], inline_format: true

      end

    end

    flyers = S3.bucket('teacher-materials')

    if flyers.exists?

        teacher_dir = "#{teacher}-#{teacher_obj.t_number}"
        name = "#{school}/#{teacher_dir}/flyers/StoryTime-Invite-Flyer-#{teacher}.pdf"
        if flyers.object(name).exists?
            puts "#{name} already exists in the bucket"
        else
          obj = flyers.object(name)
          # obj.put(body: pdf.to_blob, acl: "public-read")
          obj.upload_file(tmpfile, acl: "public-read")
          puts "Uploaded '%s' to S3!" % name
        end

        FileUtils.rm(tmpfile)
        
        tmpfile_es = File.expand_path("#{File.dirname(__FILE__)}/StoryTime Invite Flyers for #{teacher}'s Class (Spanish).pdf")
        name = "#{school}/#{teacher_dir}/flyers/StoryTime-Invite-Flyer-#{teacher}-Spanish.pdf"
        if flyers.object(name).exists?
            puts "#{name} already exists in the bucket"
        else
          obj = flyers.object(name)
          # obj.put(body: pdf.to_blob, acl: "public-read")
          obj.upload_file(tmpfile_es, acl: "public-read")
          puts "Uploaded '%s' to S3!" % name
        end

        FileUtils.rm(tmpfile_es)
    end

  end

end
