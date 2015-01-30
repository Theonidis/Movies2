class MovieTest

def initialize(array)
	@ary = array
end

def array
	@ary
end


def mean
	total_error = 0.0
	array.each do |line|
		x = line.split(" ")
		if x[2].to_i > x[3].to_i
			total_error += x[2].to_i - x[3].to_i
		else
			total_error += x[3].to_i - x[2].to_i
		end
	end
	(total_error/(array.size)).round(2)
end


def stddev
	mene = mean
	total_sum = 0.0
	array.each do |x|
		rating = x.split(" ").last.to_i
		total_sum += (rating - mene) * (rating - mene)
	end
	Math.sqrt(total_sum/array.size).round(2)
end


def rms
	mean + stddev
end
	
	
def to_array
	two_d = Array.new
	array.each do |line|
		temp = Array.new
		words = line.split(" ")
		words.each do |x|
			temp.push(x)
		end
		two_d.push(temp)
	end
	two_d
end
	
	
end

#####################################
############NEW CLASS################
#####################################

class MovieData
require 'csv'



def initialize(name, b = nil)
	ary = Array.new
	usermovieratings = Hash.new
	dir = Dir.pwd.to_s
	if b.nil?
		file_name = File.open("#{dir}/#{name}/u.data")	
		usermovieratings = parse_to_hash(file_name)
		ary = parse_to_array(file_name)
	else
		startname = b.to_s
		file_name = File.open("#{dir}/#{name}/#{startname}.base")
		usermovieratings = parse_to_hash(file_name)
		ary = parse_to_array(file_name)
		#construct the optional test set
		file_test = File.open("#{dir}/#{name}/#{startname}.test")
		test_set = parse_to_hash(file_test)
		@test_set = test_set
	end	
	@ary = ary
	@usermovieratings = usermovieratings
end


attr_reader :usermovieratings
attr_reader :test_set


def parse_to_hash (file_name)
	usermovieratings = Hash.new
	CSV.foreach(file_name) do |row|
		line = row[0].split("\t")
		backup = Array.new
		if usermovieratings.has_key?("#{line[0]}")
			#iterates over the value array and pushes it to backup
			usermovieratings["#{line[0]}"].each do |x|
			backup.push(x)
			end
		end
		#pushes the new value pair onto the array of existing value pairs
		backup.push("#{line[1]} #{line[2]}")
		usermovieratings["#{line[0]}"] = backup
	end
	usermovieratings
end


def parse_to_array(file_name)
	ary = Array.new
	CSV.foreach(file_name) do |row|
		line = row[0].split("\t")
		line.each do |word|
			ary.push(word)
		end
	end
	ary
end






def rating(user, movie, usermovieratings)
	pair = "#{usermovieratings["#{user}"].select {|x| x =~ /^#{movie} \d/}.last}"
	if pair.nil?
		puts 0
	else
		pair.split(" ").last.to_i
	end
end


def viewers(movie, usermovieratings)
	returnarray = Array.new
	usermovieratings.each do |key, val|
		user = val.each do |w|
			if w.include?("#{movie}")
				returnarray.push(key)
			end
		end
	end
	returnarray.sort_by!{ |x| x[/\d+/].to_i }
end



def movies(user, usermovieratings)
	returnarray = Array.new
	usermovieratings["#{user}"].each { |x| returnarray.push(x.split(" ").first)}
	returnarray
end



def predict(user, movie, usermovieratings)
	prediction = 0.0
	movarray = usermovieratings["#{user}"]
	if usermovieratings.has_key?("#{user}")
		movarray.each do |x|
			rating = x.split(" ").last.to_i
			prediction += rating
		end
		prediction = (prediction / movarray.size).round(2)
	else 
		return 2.5
	end
end



def run_test(usermovieratings, test_set = nil, k = nil)
	variation = Array.new
	if k.nil?
		test_set.each do |key, val|
			test_set["#{key}"].each do |x|
				splitted = x.split(" ")
				variation.push("#{key} #{splitted[0]} #{splitted[1]} #{predict("#{key.to_i}", "#{splitted[0]}", "#{usermovieratings}")}")
			end
		end
	else
		test_set.keys.sort_by! {|k, v| k.to_i}
		test_set.keys[0..k].each do |key|
			test_set["#{key}"].each do |x|
				splitted = x.split(" ")
				variation.push("#{key} #{splitted[0]} #{splitted[1]} #{predict("#{key}", "#{splitted[0]}", usermovieratings)}")
			end
		end
		
	end
	mt = MovieTest.new(variation)
end

end



# md = MovieData.new("ml-100k", :u1)
# puts md.rating(196, 242, md.usermovieratings)
# puts md.viewers(242, md.usermovieratings).sort_by{ |x| x[/\d+/].to_i }
# puts sorted
# puts md.movies(196, md.usermovieratings)
# puts md.predict(196, 242, md.usermovieratings)
# md.run_test(md.usermovieratings, md.test_set, 20000)

