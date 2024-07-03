require 'liquid'
require 'kramdown'
require 'fileutils'
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
    url = "posts/#{slug}.html"
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

def build_pages(content_dir, output_dir)
  Dir.glob("#{content_dir}/*.md").each do |file|
    front_matter, body = read_front_matter(file)
    html_content = process_markdown(body)
    
    assigns = {
      'title' => front_matter['title'],
      'date' => front_matter['date'],
      'content' => html_content
    }

    assigns['blog_post'] = true if content_dir.include?('posts')
    
    rendered_content = render_template("templates/layout.liquid", assigns)
    output_file = "#{output_dir}/#{front_matter['slug']}.html"
    File.write(output_file, rendered_content)
  end
end

def build_site
  start_time = Time.now
  copy_assets
  build_blog_index_page
  build_pages("content/", "site/")
  build_pages("content/posts", "site/posts")
  end_time = Time.now 
  puts "Build complete | #{((end_time-start_time).to_f * 1000).round(2)} ms."
end

build_site