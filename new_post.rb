require 'date'

def ordinal_suffix(day)
  case day
  when 1, 21, 31 then "#{day}st"
  when 2, 22 then "#{day}nd"
  when 3, 23 then "#{day}rd"
  else "#{day}th"
  end
end

puts "What's the title of your new post?"
title = gets.chomp.capitalize
cleaned_title = title.downcase.gsub(/[^a-zA-Z ]/, '').split.join("-")
date = DateTime.now

file = "content/posts/#{date.strftime "%Y-%m-%d"}-#{cleaned_title}.md"

File.open(file, 'a') do |file|
  file.puts "---"
  file.puts "title: #{title}"
  file.puts "date: #{date.strftime("%B #{ordinal_suffix(date.day)}, %Y")}"
  file.puts "---"
  file.puts "\n"
end
system("code #{file}")