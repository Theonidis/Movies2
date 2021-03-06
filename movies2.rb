class MovieTest

def initialize(array)
	@ary = array
end

def array
	@ary
end

#Calculate the mean by adding all of the differences
#of the prediction and ratings, then divide by the
#total number of predictions to get the average
#prediction error
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

#Find the difference of the average prediction error
#and each rating, square them, then divide by the 
#total number of ratings, then take the square root
#to find the standard deviation
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
	
#sets up the 2d array, where each element
#is an array structured as [u,m,r,p]
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
	test_ary = Array.new
	usermovieratings = Hash.new
	dir = Dir.pwd.to_s
	#If b is nil, open the file and parse it out to the
	#usermovieratings has which is structured in a way
	#such that the keys are user_ids and the values are
	#arrays of strings, each string containing a movie_id
	#and the rating separated by a space
	if b.nil?
		file_name = File.open("#{dir}/#{name}/u.data")	
		usermovieratings = parse_to_hash(file_name)
	#If b is not nil, we must construct a test_set with
	#whatever test file we are given.  test_set has the
	#same structure as  usermovieratings above
	else
		startname = b.to_s
		file_name = File.open("#{dir}/#{name}/#{startname}.base")
		usermovieratings = parse_to_hash(file_name)
		#construct the optional test set
		file_test = File.open("#{dir}/#{name}/#{startname}.test")
		test_ary = parse_to_array(file_test)
		test_set = parse_to_hash(file_test)
		@test_set = test_set
	end	
	@test_ary = test_ary
	@usermovieratings = usermovieratings
end

def array
	@test_ary
end

attr_reader :usermovieratings
attr_reader :test_set

#Copies the array already in the hashes value,
#pushes the new string onto it, then puts the
#new array back onto the hash
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

#Copies everything in the file to a big array
def parse_to_array(file_name)
	ary = Array.new
	CSV.foreach(file_name) do |row|
		ary.push(row)
	end
	ary
end


def parse_array_to_hash(ary)
	test_usermovieratings = Hash.new
	ary.each do |row|
		line = row[0].split("\t")
		if test_usermovieratings.has_key?("#{line[0]}")
			test_usermovieratings["#{line[0]}"].push("#{line[1]} #{line[2]}")
		else
			backup = Array.new
			backup.push("#{line[1]} #{line[2]}")
			test_usermovieratings["#{line[0]}"] = backup
		end
	end
	@test_usermovieratings = test_usermovieratings
end




#Select the rating that the user gave it.
#Since values in the hash are arrays, we can select
#	from those arrays using a regular expression which
#	checks to see if the movie_id matches the one we are
#	given.  This would cause problems if one user rated
#	the same movie multiple times.
#If they did not rate it, return 0
def rating(user, movie, usermovieratings)
	pair = "#{usermovieratings["#{user}"].select {|x| x =~ /^#{movie} \d/}.last}"
	if pair.nil?
		0
	else
		pair.split(" ").last.to_i
	end
end


#Grabs all of the user_ids in the hash whose
#value array has an element that contains the 
#given movie_id
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


#Grabs the value array, splits it on the space
#and returns the first thing, which is the movie_id
#and pushes it onto an array that will contain all
#of the movie_ids that the given user has wathced
def movies(user, usermovieratings)
	returnarray = Array.new
	usermovieratings["#{user}"].each { |x| returnarray.push(x.split(" ").first)}
	returnarray
end


#Our predictions are generated by going through
#the users value array and finding the average
#rating that they give.  Turns out to be decently accurate.
#We round our answer to 2 decimal places
#If they have not rated any movies, return 2.5, or half.
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


#If there is no test set, we can't do this method.
#We create an array variation that will be used to generate
#	our MovieData.
#If k is nil, the we run through the entire test_set and 
#	try to predict what the each movie should be rated.
#variation in the end will contain rows structured in the form
#	[user movie rating prediction] (Notice this is one element of the array)
#If k is not nil, we use an array that contains each line in the
#	.test file and generates a new test_hash using only up to the
#	line denoted by k, i.e. the first k ratings.
#We then preform the same operation we did before, but with our
#	newer, smaller limited_set.
def run_test(usermovieratings, test_set = nil, k = nil)
	if test_set.nil?
		puts "ERROR: NON EXISTENT test_set"
	end
	variation = Array.new
	if k.nil?
		test_set.each do |key, val|
			test_set["#{key}"].each do |x|
				splitted = x.split(" ")
				variation.push("#{key} #{splitted[0]} #{splitted[1]} #{predict("#{key}", "#{splitted[0]}", test_set)}")
			end
		end
	else
		limited_test = Array.new
		array[0..(k - 1)].each {|i| limited_test.push(i)}
		limited_set = parse_array_to_hash(limited_test)
		limited_set.keys.sort_by! {|k, v| k.to_i}
		limited_set.keys[0..k].each do |key|
			limited_set["#{key}"].each do |x|
				splitted = x.split(" ")
				variation.push("#{key} #{splitted[0]} #{splitted[1]} #{predict("#{key}", "#{splitted[0]}", limited_set)}")
			end
		end
		
	end
	mt = MovieTest.new(variation)
end
end



# md = MovieData.new("ml-100k")
# puts md.rating(196, 242, md.usermovieratings)
# puts md.viewers(242, md.usermovieratings).sort_by{ |x| x[/\d+/].to_i }
# puts sorted
# puts md.movies(196, md.usermovieratings)
# puts md.predict(196, 242, md.usermovieratings)
# md.run_test(md.usermovieratings, md.test_set, 20)

