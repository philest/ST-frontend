# module to match a code to a school or educator. 

module SchoolCodeMatcher

  def is_matching_code?(body_text)
     # get all available codes...
      all_codes =  School.map(:code).compact
      all_codes += Teacher.map(:code).compact
      # puts "all codes (teachers, schools) = #{all_codes}"
      all_codes = all_codes.map {|c| c.delete(' ').delete('-').downcase }
      # need to split up the codes by individual english/spanish
      all_codes = all_codes.inject([]) do |result, elt|
        # should I just be taking the English code part? no of course not bc we have spanish users
        result += elt.split('|')
      end
      return all_codes.include? body_text
  end

  def educator?(body_text)

      body_text = body_text.delete(' ')
                                 .delete('-')
                                 .downcase
      School.each do |school|
        code = school.code
        if code.nil?
          next
        end
        code = code.delete(' ').delete('-').downcase

        if code.include? body_text
          en, sp = code.split('|')
          if body_text == en
            return {locale: 'en', type: 'school', educator: school}

          elsif body_text == sp
            return {locale: 'es', type: 'school', educator: school}
          end
        end
      end

      Teacher.each do |teacher|
        code = teacher.code
        if code.nil?
          next
        end
        code = code.delete(' ').delete('-').downcase

        if code.include? body_text
          en, sp = code.split('|')
          if body_text == en
            return {locale: 'en', type: 'teacher', educator: teacher}
          elsif body_text == sp
            return {locale: 'es', type: 'teacher', educator: teacher}
          end
        end # if code.include? body_text
      end # Teacher.each do |teacher|

      return false

  end



  def language?(body_text)
    # get all available codes...
      all_codes =  School.map(:code).compact
      all_codes += Teacher.map(:code).compact
      # puts "all codes (teachers, schools) = #{all_codes}"
      all_codes = all_codes.map {|c| c.delete(' ').delete('-').downcase }
      # need to split up the codes by individual english/spanish
      all_codes = all_codes.inject({english:[],spanish:[]}) do |result, elt|
        # should I just be taking the English code part? no of course not bc we have spanish users
        en, es = elt.split('|')
        result[:english] += [en]
        result[:spanish] += [es]
        result
      end

      puts "all_codes = #{all_codes}"
      if all_codes[:english].include? body_text
        return 'en'
      elsif all_codes[:spanish].include? body_text
        return 'es'
      else
        return false
      end
  end


end