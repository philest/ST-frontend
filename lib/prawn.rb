require "prawn"

# 612 x 792

Prawn::Document.generate("hello.pdf", page_size: 'LETTER') do
  bounding_box([12, 720], :width => 512, :height => 720) do
    # stroke_bounds
    image "white-bird.png", position: :left, width: 50

    font_families.update(
      "Karla" => {
        :normal => "fonts/Karla-Regular.ttf",
        :bold => "fonts/Karla-Bold.ttf",
        :italic => "fonts/Karla-Italic.ttf"
      },

      "Avenir" => {
        :normal => "fonts/avenir-lt-65-medium.ttf",
        :bold => "fonts/avenir-lt-95-black.ttf",
        :light => "fonts/AvenirLTStd-Light.ttf"
      }
    )
    # move_up 30
    font("Avenir", style: :bold) do
      font_size 18
      text_box "STORYTIME", at: [60, 705]

      move_down 20
      font_size 36
      text "Get free books from"
      move_down 5
      text "Mrs. Perricone."
    end

    font("Avenir", style: :light) do
      move_down 20
      font_size 12
      text "Get free books for <b>Rocky Mountain Prep</b> sent right to your phone-- no running around.", inline_format: true

      font_size 16
      text_box "On your phone, go to the web link:", width: 180, height: 50, at: [40, 450]
    end

    bounding_box([25, 400], width: 200, height: 50) do
      stroke_bounds
      font("Avenir", style: :bold) do


      end

    end

  


  end

end



