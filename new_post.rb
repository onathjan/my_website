require 'date'

module Titleize
  SMALL_WORDS = %w{a an and as at but by en for if in of on or the to v v. via vs vs.}

  extend self

  def titleize(title)
    title = title.dup
    title.downcase! unless title[/[[:lower:]]/]

    phrases(title).map do |phrase|
      words = phrase.split
      words.map.with_index do |word, index|
        def word.capitalize
          self.sub(/[[:alpha:]].*/) {|subword| subword.capitalize}
        end

        case word
        when /[[:alpha:]]\.[[:alpha:]]/ 
          word
        when /[-‑]/
          word.split(/([-‑])/).map do |part|
            SMALL_WORDS.include?(part) ? part : part.capitalize
          end.join
        when /^[[:alpha:]].*[[:upper:]]/
          word
        when /^[[:digit:]]/
          word
        when *(SMALL_WORDS + SMALL_WORDS.map {|small| small.capitalize })
          if index == 0 || index == words.size - 1
            word.capitalize
          else
            word.downcase
          end
        else
          word.capitalize
        end
      end.join(" ")
    end.join(" ")
  end

  def phrases(title)
    phrases = [[]]
    title.split.each do |word|
      phrases.last << word
      phrases << [] if ends_with_punctuation?(word) && !small_word?(word)
    end
    phrases.reject(&:empty?).map { |phrase| phrase.join " " }
  end

  private

  def small_word?(word)
    SMALL_WORDS.include? word.downcase
  end

  def ends_with_punctuation?(word)
    word =~ /[:.;?!]$/
  end
end

class String

  def titleize(opts={})
    if defined? ActiveSupport::Inflector
      ActiveSupport::Inflector.titleize(self, opts)
    else
      Titleize.titleize(self)
    end
  end
  alias_method :titlecase, :titleize

  def titleize!
    replace(titleize)
  end
  alias_method :titlecase!, :titleize!
end

if defined? ActiveSupport::Inflector
  module ActiveSupport::Inflector
    extend self

    def titleize(title, opts={})
      opts = {:humanize => true, :underscore => true}.merge(opts)
      title = ActiveSupport::Inflector.underscore(title) if opts[:underscore]
      title = ActiveSupport::Inflector.humanize(title) if opts[:humanize]

      Titleize.titleize(title)
    end
    alias_method :titlecase, :titleize
  end
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
title = gets.chomp.titleize
cleaned_title = title.downcase.gsub(/[^a-zA-Z ]/, '').split.join("-")
date = DateTime.now

file = "content/posts/#{date.strftime "%Y-%m-%d"}-#{cleaned_title}.md"

File.open(file, 'a') do |file|
  file.puts <<~TEXT
    ---
    title: "#{title}"
    date: #{date.strftime("%B #{ordinal_suffix(date.day)}, %Y")}
    slug: replace-me
    ---

  TEXT
end

system("code #{file}")