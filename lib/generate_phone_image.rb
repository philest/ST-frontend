require 'rmagick'
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



  @@TEACHER_SIG_FONTSIZE = 52
  @@SUBTITLE_BANNER_X = 84


  def create_image(teacher_obj, school_obj)
    code = teacher_obj.code
    teacher = teacher_obj.signature
    school = school_obj.signature

    code_en, code_es = code.split('|')

    puts "code_en = #{code_en}"
    puts "code_es = #{code_es}"

    path = File.expand_path("#{File.dirname(__FILE__)}/English-Flyer-New.jpg")

    canvas = Magick::Image.from_blob(IO.read(path))[0]

    text = Magick::Draw.new
    text.font = File.expand_path("#{File.dirname(__FILE__)}/../public/fonts/AvenirLTStd-Medium.otf")

    text.pointsize = 29
    x_start  = 198
    x_mid = 225
    y_start = 493

    # on the phone
    img_txt_d = text.get_type_metrics("#{code_en}")


    phone_code_x = 413
    phone_code_y = 571
    text.annotate(canvas, 0, 0, phone_code_x, phone_code_y, code_en)


    text.font = File.expand_path("#{File.dirname(__FILE__)}/../public/fonts/AvenirLTStd-Black.otf")
    # 406, 511
    text.annotate(canvas, 0, 0, x_mid - (img_txt_d.width/2), y_start, "#{code_en}")
    # text.annote


    # 597 x 553
    # text.font = File.expand_path("#{File.dirname(__FILE__)}/../public/fonts/AvenirLTStd-Black.otf")



    # then the upper title...
    # 200, 737
    # text.font = File.expand_path("#{File.dirname(__FILE__)}/../public/fonts/AvenirLTStd-Black.otf")
    text.pointsize = @@TEACHER_SIG_FONTSIZE
    text.annotate(canvas, 0, 0, @@SUBTITLE_BANNER_X, 263, "#{teacher}.")

    # 200, 875
    text.pointsize = 17
    text.font = File.expand_path("#{File.dirname(__FILE__)}/../public/fonts/AvenirLTStd-Medium.otf")
    dimensions = text.get_type_metrics("Get free books from ")
    text.annotate(canvas, 0, 0, @@SUBTITLE_BANNER_X, 303, "Get free books from ")
    text.font = File.expand_path("#{File.dirname(__FILE__)}/../public/fonts/AvenirLTStd-Black.otf")
    text.annotate(canvas, 0, 0, @@SUBTITLE_BANNER_X + dimensions.width, 303, "#{school} ")

    text.font = File.expand_path("#{File.dirname(__FILE__)}/../public/fonts/AvenirLTStd-Medium.otf")
    x_width = text.get_type_metrics("Get free books from #{school} ").width
    if "#{school}".length >= 7
        add_space = 8
    else
        add_space = 0
    end
    text.annotate(canvas, 0, 0, @@SUBTITLE_BANNER_X + x_width + add_space, 303, "sent right to your phone- no running around.")

    img_path = File.expand_path("#{File.dirname(__FILE__)}/../../public/enroll-flyer/#{code_en}-flyer.png")

    # canvas.write(img_path)

    # write .png to aws
    # 
    # 
    # 
    # 
    # end write to aws

    # spanish now   

    path = File.expand_path("#{File.dirname(__FILE__)}/Spanish-Flyer-New.jpg")

    canvas_es = Magick::Image.from_blob(IO.read(path))[0]

    text = Magick::Draw.new
    text.font = File.expand_path("#{File.dirname(__FILE__)}/../public/fonts/AvenirLTStd-Medium.otf")
    text.pointsize = 29
    # x_start, x_end = 198
    # y_start, y_end = 473

    # on the phone
    puts "code spanish = #{code_es}"
    text.annotate(canvas_es, 0, 0, phone_code_x, phone_code_y - 10, code_es)


    text.font = File.expand_path("#{File.dirname(__FILE__)}/../public/fonts/AvenirLTStd-Black.otf")
    img_txt_d = text.get_type_metrics("#{code_es}")
    # 406, 511
    text.annotate(canvas_es, 0, 0, x_mid - (img_txt_d.width/2) - 6, y_start + 5, "#{code_es}")

    # then the upper title...
    # text.font = File.expand_path("#{File.dirname(__FILE__)}/../public/fonts/AvenirLTStd-Black.otf")

    text.pointsize = @@TEACHER_SIG_FONTSIZE
    puts "teacher name = #{teacher}"
    text.annotate(canvas_es, 0, 0, 84, 260, "#{teacher}.")
    # text.annotate(canvas_es, 0, 0, 70, 235, "de parte de #{teacher}.")

    text.pointsize = 17
    text.font = File.expand_path("#{File.dirname(__FILE__)}/../public/fonts/AvenirLTStd-Medium.otf")
    dimensions = text.get_type_metrics("Obtén libros de parte de ")
    text.annotate(canvas_es, 0, 0, 84, 300, "Obtén libros de parte de ")
    text.font = File.expand_path("#{File.dirname(__FILE__)}/../public/fonts/AvenirLTStd-Black.otf")
    text.annotate(canvas_es, 0, 0, 84 + dimensions.width, 300, "#{school} ")

    text.font = File.expand_path("#{File.dirname(__FILE__)}/../public/fonts/AvenirLTStd-Medium.otf")
    x_width = dimensions.width + text.get_type_metrics("#{school} ").width

    if "#{school}".length >= 7
        add_space = 8
    else
        add_space = 0
    end

    text.annotate(canvas_es, 0, 0, 84 + x_width + add_space, 300, "directamente en tu celular.")

    flyers = S3.bucket('teacher-materials')

    if flyers.exists?
        # teacher_dir = "#{teacher}-#{teacher_obj.t_number}" 
        # name = "#{school}/#{teacher_dir}/flyers/#{code_en}-flyer.png"
        # if flyers.object(name).exists?
        #     puts "#{name} already exists in the bucket"
        # else
        #   obj = flyers.object(name)
        #   obj.put(body: canvas.to_blob, acl: "public-read")
        #   puts "Uploaded '%s' to S3!" % name
        # end

        # name_es = "#{school}/#{teacher_dir}/flyers/#{code_en}-flyer-es.png"
        # if flyers.object(name_es).exists?
        #     puts "#{name_es} already exists in the bucket"
        # else
        #     obj = flyers.object(name_es)
        #     obj.put(body: canvas_es.to_blob, acl: "public-read")
        #     puts "Uploaded '%s' to S3!" % name_es
        # end

        pdf = Magick::ImageList.new
        pdf.from_blob(canvas.to_blob)

        tmpfile = File.expand_path("#{File.dirname(__FILE__)}/StoryTime Invite Flyers for #{teacher}'s Class.pdf")
        pdf.write(tmpfile)


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

        pdf_es = Magick::ImageList.new
        pdf_es.from_blob(canvas_es.to_blob)

        tmpfile = File.expand_path("#{File.dirname(__FILE__)}/StoryTime Invite Flyers for #{teacher}'s Class (Spanish).pdf")
        pdf_es.write(tmpfile)
        name = "#{school}/#{teacher_dir}/flyers/StoryTime-Invite-Flyer-#{teacher}-Spanish.pdf"
        if flyers.object(name).exists?
            puts "#{name} already exists in the bucket"
        else
          obj = flyers.object(name)
          # obj.put(body: pdf.to_blob, acl: "public-read")
          obj.upload_file(tmpfile, acl: "public-read")
          puts "Uploaded '%s' to S3!" % name
        end

        FileUtils.rm(tmpfile)
    end

  end

end
