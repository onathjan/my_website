require 'fileutils'
require 'htmlbeautifier'
require 'kramdown'
require 'liquid'
require 'yaml'

def read_front_matter(file_path)
  content = File.read(file_path)
  if content =~ /\A---\n(.*?)\n---\n/m
    front_matter = YAML.load($1)
    body = $'
    [front_matter, body]
  else
    [nil, content]
  end
end

def process_markdown(content)
  Kramdown::Document.new(content, {auto_ids: false}).to_html
end

def render_template(template_file, assigns)
  template = File.read(template_file)
  Liquid::Template.parse(template).render(assigns)
end

def copy_assets
  FileUtils.cp_r('assets', 'site')
end

def build_blog_index_page
  posts = []

  Dir.glob("content/posts/*md").each do |file|
    front_matter, _ = read_front_matter(file)
    slug = front_matter['slug']
    title = front_matter['title']
    date = file[0..9]
    url = "#{slug}.html"
    posts << { date: date, title: title, url: url }
  end

  posts.sort_by! { |post| post[:date] }.reverse!

  blog_content = <<~BLOG
    ---
    title: Posts
    slug: blog
    ---
  BLOG

  posts.each do |post|
    blog_content << "- [#{post[:title]}](#{post[:url]})\n"
  end

  blog_content << "{:.posts}"

  File.write("content/blog.md", blog_content)
end

def build_pages(content_dir)
  Dir.glob("#{content_dir}/*.md").each do |file|
    front_matter, body = read_front_matter(file)
    html_content = process_markdown(body)
    
    assigns = {
      'title' => front_matter['title'],
      'date' => front_matter['date'],
      'content' => html_content
    }

    rendered_content = render_template("templates/layout.liquid", assigns)
    output_file = "site/#{front_matter['slug']}.html"
    File.write(output_file, rendered_content)
  end
end

def clean_html_file(file_path)
  content = File.read(file_path)
  cleaned_content = content.gsub(/^\s*$(?:\n|\r\n)?/, '') # Remove blank lines
  beautified_content = HtmlBeautifier.beautify(cleaned_content)
  File.write(file_path, beautified_content)
end

def clean_html_files_in_directory(directory)
  Dir.glob("#{directory}/**/*.html").each do |file|
    clean_html_file(file)
  end
end

def build_site
  start_time = Time.now
  copy_assets
  build_blog_index_page
  build_pages("content/")
  build_pages("content/posts")
  clean_html_files_in_directory('site')
  end_time = Time.now 
  puts "Build complete | #{((end_time-start_time).to_f * 1000).round(2)} ms."
end

build_site