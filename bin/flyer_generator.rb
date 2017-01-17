require_relative 'production'
require_relative '../lib/generate_flyers'
require 'csv'
require 'combine_pdf'

# def generate_all_flyers(filename)

def generate_all_flyers(teacher_csv, school_id, english_copies=16, spanish_copies=6)
  puts teacher_csv, school_id

  school = School.where(id: school_id).first
  flyerMaker = FlyerImage.new
  pdf = CombinePDF.new

  CSV.foreach(teacher_csv, :headers => true) do |row|
    puts row['name'],row['email']
    # create teacher

    signature = "Ms. " + row['name'].split.first
    teacher = Teacher.create(signature: signature, name: row['name'], email: row['email'])
    school.signup_teacher(teacher)

    # create flyer
    flyerMaker.create_image(teacher, school, delete_local=false)

    english = File.expand_path(File.dirname(__FILE__)) + "/../lib/StoryTime Invite Flyers for #{teacher.signature}'s Class.pdf"
    if File.exists?(english)
      puts "file exists english!"
      english_copies.times do |i|
        puts "#{i}th pdf"
        pdf << CombinePDF.load(english) # one way to combine, very fast.
      end 
    end

    spanish = File.expand_path(File.dirname(__FILE__)) + "/../lib/StoryTime Invite Flyers for #{teacher.signature}'s Class (Spanish).pdf"
    if File.exists?(spanish)
      puts "file exists spanish!"
      spanish_copies.times do |i|
        puts "#{i}th pdf"
        pdf << CombinePDF.load(spanish) # one way to combine, very fast.
      end
    end

    FileUtils.rm(english)
    FileUtils.rm(spanish)

  end # CSV
  pdf.save "combined_flyers.pdf"

end


school = School.where(signature: "Martha's Table").first

csv_file = File.expand_path(File.dirname(__FILE__)) + '/test.csv'

generate_all_flyers(csv_file, school.id)

# Teacher.where(email: "jdmcpeek@gmail.com").first.destroy
# Teacher.where(email: "pesterman@gmail.com").first.destroy
# Teacher.where(email: "aawahl@hotmail.gov").first.destroy


