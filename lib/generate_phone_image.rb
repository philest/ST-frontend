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

    path = File.expand_path("#{File.dirname(__FILE__)}/assets/phone-text-blank.png")

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


