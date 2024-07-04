require 'date'

def mla_title_case(title)
  bad_words = %w[a an the and but for nor or so yet by for from in into of off on out over through to under with]

  words = title.split(' ')

  words.map! do |word|
    if bad_words.include?(word.downcase)
      word.downcase
    else
      word.capitalize
    end
  end

  words.first.capitalize!
  words.last.capitalize!

  words.join(' ')
end

def ordinal_suffix(day)
  case day
  when 1, 21, 31 then "#{day}st"
  when 2, 22 then "#{day}nd"
  when 3, 23 then "#{day}rd"
  else "#{day}th"
  end
end

puts "What's the title of your new post?"
title = mla_title_case(gets.chomp)
cleaned_title = title.downcase.gsub(/[^a-zA-Z ]/, '').split.join("-")
date = DateTime.now

file = "content/posts/#{date.strftime "%Y-%m-%d"}-#{cleaned_title}.md"

File.open(file, 'a') do |file|
  file.puts <<~TEXT
    ---
    title: #{title}
    date: #{date.strftime("%B #{ordinal_suffix(date.day)}, %Y")}
    slug: replace-me
    ---

  TEXT
end

system("code #{file}")