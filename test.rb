require_relative 'bin/local'
require_relative 'lib/generate_phone_image'
teacher_obj = Teacher.where(email: "david.mcpeek@yale.edu").first
school_obj = teacher_obj.school
FlyerImage.new.create_image(teacher_obj, school_obj)
# exec "open lib/StoryTime\ Invite\ Flyers\ for\ Mr.\ McPeek\'s\ Class.pdf"