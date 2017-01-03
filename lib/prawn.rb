require "prawn"

# 612 x 792

Prawn::Document.generate("hello.pdf", page_size: 'LETTER') do
  bounding_box([12, 720], :width => 512, :height => 720) do
    # stroke_bounds
    dir = File.expand_path(File.dirname(__FILE__))
    puts "dir = #{dir}"
    image dir + "/white-bird.png", position: :left, width: 50
    image dir + "/intro-storytime.png", at: [55, 705], width: 125

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
      text "Mrs. Perricone."
    end

    font("Avenir", style: :light) do
      move_down 20
      font_size 12
      text "Consigue libros de parte de <b>Rocky Mountain Prep</b> directamente en su celular.", inline_format: true

      font_size 18
      text_box "En su celular, abre el navegador y usa este enlace:", width: 180, height: 50, at: [40, 450]
    end

    bounding_box([25, 400], width: 200, height: 50) do
      # stroke_bounds
      font("Avenir", style: :bold) do
        fill_color(0,255,0,0)
        font_size 18
        text_box "stbooks.org/HHRC1", valign: :center, align: :center, overflow: :shrink_to_fit, single_line: :true
      end
    end

    stroke do
      stroke_color '#E8E8E8'
      rounded_rectangle [25,400], 200, 50, 5
    end

    # phone image
    image dir + "/phone-no-icon.png", at: [250, 500], width: 285

    bounding_box([288, 455], width: 84, height: 12) do
      # stroke_bounds
      fill_color '#000000'
      font_size 10
      font("Karla", style: :normal) do
        text_box "stbooks.org/rmp-es", valign: :center, align: :center, overflow: :shrink_to_fit, single_line: :true
      end

      

    end

    bounding_box([285, 425], width: 140, height: 18) do
      # stroke_bounds
      fill_color '#000000'
      font_size 13
      font("Karla", style: :normal) do
        text_box "Anótate en la clase de Mrs. Perricone", valign: :center, align: :center, overflow: :shrink_to_fit, single_line: :true
      end

    end

    image dir + "/spanish-complete-by-monday.png", at: [40, 220], width: 150

    image dir + "/luna.png", at: [255, 310], width: 230


    move_down 380
    font_size 10
    font "Avenir", style: :normal 
    text_box "<b>¿No tienes un smartphone?</b> Consigue libros de mensaje. Mensajéa <b><color rgb='ff0000'>HHRC1-es</color></b> al numero <b><color rgb='ff0000'>(203) 202-3505</color></b>.", at:[25, 30], inline_format: true


  end

end

# Prawn::Document.generate("hello.pdf", page_size: 'LETTER') do
#   bounding_box([12, 720], :width => 512, :height => 720) do
#     # stroke_bounds
#     dir = File.expand_path(File.dirname(__FILE__))
#     puts "dir = #{dir}"
#     image dir + "/white-bird.png", position: :left, width: 50
#     image dir + "/intro-storytime.png", at: [55, 705], width: 125

#     font_families.update(
#       "Karla" => {
#         :normal => dir + "/../public/fonts/Karla-Regular.ttf",
#         :bold => dir + "/../public/fonts/Karla-Bold.ttf",
#         :italic => dir + "/../public/fonts/Karla-Italic.ttf"
#       },

#       "Avenir" => {
#         :normal => dir + "/../public/fonts/avenir-lt-65-medium.ttf",
#         :bold => dir + "/../public/fonts/avenir-lt-95-black.ttf",
#         :light => dir + "/../public/fonts/AvenirLTStd-Light.ttf"
#       }
#     )
#     # move_up 30
#     font("Avenir", style: :bold) do
#       font_size 18
#       # text_box "STORYTIME", at: [60, 705]
#       move_down 20
#       font_size 36
#       text "Get free books from"
#       move_down 5
#       text "Mrs. Perricone."
#     end

#     font("Avenir", style: :light) do
#       move_down 20
#       font_size 12
#       text "Get free books for <b>Rocky Mountain Prep</b> sent right to your phone-- no running around.", inline_format: true

#       font_size 18
#       text_box "On your phone, go to the web link:", width: 180, height: 50, at: [40, 450]
#     end

#     bounding_box([25, 400], width: 200, height: 50) do
#       # stroke_bounds
#       font("Avenir", style: :bold) do
#         fill_color(0,255,0,0)
#         font_size 18
#         text_box "stbooks.org/HHRC1", valign: :center, align: :center, overflow: :shrink_to_fit, single_line: :true
#       end
#     end

#     stroke do
#       stroke_color '#E8E8E8'
#       rounded_rectangle [25,400], 200, 50, 5
#     end

#     # phone image
#     image dir + "/phone-no-icon.png", at: [250, 500], width: 285

#     bounding_box([288, 455], width: 84, height: 12) do
#       # stroke_bounds
#       fill_color '#000000'
#       font_size 10
#       font("Karla", style: :normal) do
#         text_box "stbooks.org/rmp-es", valign: :center, align: :center, overflow: :shrink_to_fit, single_line: :true
#       end

      

#     end

#     bounding_box([285, 425], width: 140, height: 18) do
#       # stroke_bounds
#       fill_color '#000000'
#       font_size 13
#       font("Karla", style: :normal) do
#         text_box "Join Mrs. Perricone's class", valign: :center, align: :center, overflow: :shrink_to_fit, single_line: :true
#       end

#     end

#     image dir + "/complete-by-monday.png", at: [40, 220], width: 150

#     image dir + "/hero-child.png", at: [250, 310], width: 260


#     move_down 380
#     font_size 10
#     font "Avenir", style: :normal 
#     text_box "<b>No smartphone?</b> Get stories by text. Text <b><color rgb='ff0000'>HHRC1</color></b> to the phone number <b><color rgb='ff0000'>(203) 202-3505</color></b>.", at:[25, 40], inline_format: true


#   end

# end



