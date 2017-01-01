# require 'set'

def test
	"hi" + 5 

	begin
		"hi" + 5
	rescue TypeError => e
		puts e.message
	end
end

	



describe "test" do
	it "raises errors" do
		expect{test}.to raise_error(TypeError)
	end 
end