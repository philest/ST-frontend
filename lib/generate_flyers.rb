require 'prawn'
require 'gruff'
require 'fileutils'
require_relative '../config/initializers/aws'


class FlyerImage

  def create_image(teacher_obj, school_obj, delete_local=true)

    code = teacher_obj.code
    teacher = teacher_obj.signature
    school = school_obj.signature

    code_en, code_es = code.split('|')

    puts "code_en = #{code_en}"
    puts "code_es = #{code_es}"
    
    # 612 x 792
    english = {
      lang: 'english',
      code: code_en,
      tmpfile: "#{File.dirname(__FILE__)}/StoryTime Invite Flyers for #{teacher}'s Class.pdf",
      banner: "Get free books from ",
      banner_subtitle: "Get free books for <b>#{school}</b> sent right to your phone. No running around.",
      step1: "On your phone,\ngo to the web link:",
      step1_subtitle: "Sign up, then you will get the app with books.",
      phone_img_1: "phone-1.jpg",
      phone_banner: "Join #{teacher}'s class",
      complete_by_monday: "complete-by-monday.jpg",
      phone_img_2: "phone-2.jpg",
      bottom_txt: "<b>No smartphone?</b> Get books by text message. Text <b><color rgb='ff0000'>#{code_en}</color></b> to <b><color rgb='ff0000'>(203) 202-3505</color></b>.",
      aws_filename: "#{school}/#{teacher}-#{teacher_obj.t_number}/flyers/StoryTime-Invite-Flyer-#{teacher}.pdf"
    }

    spanish = {
      lang: 'spanish',
      code: code_es,
      tmpfile: "#{File.dirname(__FILE__)}/StoryTime Invite Flyers for #{teacher}'s Class (Spanish).pdf",
      banner: "Consiga libros gratis de ",
      banner_subtitle: "Consiga libros de parte de <b>#{school}</b> directamente en tu celular.",
      step1: "En tu celular, abre el navegador y usa el enlace:",
      step1_subtitle: "Inscríbete, y recibe la aplicación con libros.",
      phone_img_1: "phone-1-ES.jpg",
      phone_banner: "Inscríbete en la clase\nde #{teacher}",
      complete_by_monday: "spanish-complete-by-monday.jpg",
      phone_img_2: "phone-2-ES.jpg",
      bottom_txt: "<b>¿No tiene un smartphone?</b> Recibe libros por mensaje. Mensajéa <b><color rgb='ff0000'>#{code_es}</color></b> a <b><color rgb='ff0000'>(203) 202-3505</color></b>.",
      aws_filename: "#{school}/#{teacher}-#{teacher_obj.t_number}/flyers/StoryTime-Invite-Flyer-#{teacher}-Spanish.pdf"
    }

    [english, spanish].each do |args|

      page_width = 500

      tmpfile = File.expand_path(args[:tmpfile])
      Prawn::Document.generate(tmpfile, page_size: 'LETTER') do
        bounding_box([24, 700], :width => page_width, :height => 700) do
          # stroke_bounds
          dir = File.expand_path(File.dirname(__FILE__))
          puts "dir = #{dir}"
          image dir + '/assets' + "/logo.jpg", position: :left, width: 50
          # image dir + '/assets' + "/intro-storytime.jpg", at: [55, 705], width: 125


          font_families.update(
            "Karla" => {
              :normal => dir + "/../public/fonts/Karla-Regular.ttf",
              :bold => dir + "/../public/fonts/Karla-Bold.ttf",
              :italic => dir + "/../public/fonts/Karla-Italic.ttf"
            },

            "Avenir" => {
              :normal => dir + "/../public/fonts/avenir-lt-65-medium.ttf",
              :bold => dir + "/../public/fonts/avenir-lt-95-black.ttf",
              :light => dir + "/../public/fonts/AvenirLTStd-Light.ttf",
              :eighty_five => dir + "/../public/fonts/avenir_85_heavy.ttf",
              :roman => dir + "/../public/fonts/Avenir-Roman.ttf"
            },
            "Cool Crayon" => {
              :normal => dir + "/../public/fonts/dk_cool_crayon-webfont.ttf"
            }
          )

          font("Cool Crayon", style: :normal) do
            font_size 18
            text_box "StoryTime", width: 100, height: 30, at: [50, 690]
          end

          down_shift = 0

          # move_up 30
          font("Avenir", style: :bold) do
            font_size 18
            # text_box "STORYTIME", at: [60, 705]
            move_down 40

            font_size 26

            puts "banner = #{args[:banner]}"
            puts "teacher = #{teacher}"

            args[:banner] = args[:banner]

            banner_width = width_of (args[:banner] + "#{teacher}.")
            puts "banner width = #{banner_width}"
            banner_height = height_of(args[:banner])
            puts "banner height = #{banner_height}"

            if banner_width > page_width
              if banner_width - page_width < 50 # stay on 1 line
                puts "shrinking"
                banner = args[:banner] + "#{teacher}."
                text_box banner, width: page_width,height:40, at:[0, 620], overflow: :shrink_to_fit
                # text banner
                down_shift = 0
              else # 2nd line
                puts "2nd line"
                text_box args[:banner], width: page_width, height: banner_height, at: [0, 620]
                # text args[:banner]
                # move_down 10
                text_box "#{teacher}.", width: page_width, height: banner_height, at: [0, 580]
                # text "#{teacher}."
                down_shift = banner_height.ceil + 10
              end

            else # it's fine, single line~
              puts "single line"
              banner = args[:banner] + "#{teacher}."
              # text banner
              text_box banner, width: page_width,height:40, at:[0, 620], overflow: :shrink_to_fit
              down_shift = 0
            end

            # text_box args[:banner],width: 512,height:40, at:[0, 620], overflow: :shrink_to_fit
            # move_down 5
            # text "#{teacher}."
          end

          font("Avenir", style: :light) do
            # move_down 15
            font_size 12
            text_box args[:banner_subtitle], inline_format: true, at: [0, 575 - down_shift]
          end

          font("Avenir", style: :bold) do
            font_size 20
            text_box '1.', width: 20, height: 20, at: [10, 490 - down_shift]
          end

          font("Avenir", style: :eighty_five) do
            font_size 17

            text_box args[:step1], width: 180, height: 80, at: [35, 495 - down_shift], overflow: :shrink_to_fit, leading: 5
          end

          step1_shift = args[:lang] == 'english' ? 0 : 30

          bounding_box([25, 440 - down_shift - step1_shift], width: 200, height: 50) do
            # stroke_bounds
            font("Avenir", style: :bold) do
              fill_color 'C0391B'
              font_size 18
              text_box "stbooks.org/#{args[:code]}", valign: :center, align: :center, overflow: :shrink_to_fit, single_line: :true
            end
          end

          font("Avenir", style: :normal) do
            fill_color '847f6a'
            font_size 9
            text_box args[:step1_subtitle], at: [35, 385 - down_shift - step1_shift]
          end

          stroke do
            stroke_color 'A9A9A9'
            rounded_rectangle [25,440 - down_shift - step1_shift], 200, 50, 5
          end

          # phone image
          image dir + '/assets/' + args[:phone_img_1], at: [250, 535 - down_shift], width: 250

          bounding_box([276, 492 - down_shift], width: 93, height: 12) do
            # stroke_bounds
            fill_color '000000'
            font_size 10
            font("Karla", style: :normal) do
              text_box "stbooks.org/#{args[:code]}", valign: :center, align: :center, overflow: :shrink_to_fit, single_line: :true
            end
          end

          if args[:lang] == 'english'
            bounding_box([265, 463 - down_shift], width: 152, height: 18) do
              # stroke_bounds
              fill_color '8284BA'
              font_size 12
              font("Karla", style: :bold) do              
                text_box args[:phone_banner], valign: :center, align: :center, overflow: :shrink_to_fit
              end
            end
          else
            bounding_box([265, 473 - down_shift], width: 152, height: 36) do
              # stroke_bounds
              fill_color '8284BA'
              font_size 11

              font("Karla", style: :bold) do              
                text_box args[:phone_banner], valign: :center, align: :center
              end
            end

          end

          fill_color '000000'

          image dir + '/assets/' + args[:complete_by_monday], at: [40, 220 + 20 - down_shift], width: 150
          image dir + '/assets/' + args[:phone_img_2], at: [250, 355 - down_shift], width: 210

          move_down 380 
          font_size 12
          font "Avenir", style: :normal

          text_box args[:bottom_txt], at:[0, 37], inline_format: true, width:page_width,height:15,overflow: :shrink_to_fit 
        end 
      end # prawn doc

      flyers = S3.bucket('teacher-materials')
      if flyers.exists?
        name = args[:aws_filename]
        if flyers.object(name).exists?
            puts "#{name} already exists in the bucket"
        else
          obj = flyers.object(name)
          # obj.put(body: pdf.to_blob, acl: "public-read")
          obj.upload_file(args[:tmpfile], acl: "public-read")
          puts "Uploaded '%s' to S3!" % name
        end
        FileUtils.rm(args[:tmpfile]) if delete_local
      end

    end # spanish, english 


  end # def create_image

end # class FlyerImage
