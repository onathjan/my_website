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
  posts = {}

  Dir.glob("content/posts/*md").each do |file|
    title = read_front_matter(file).first.values.first
    url = "posts/#{File.basename(file, '.md')}.html"
    posts[url] = title
  end

  File.open("content/blog.md", 'w') do |file|
    file.puts "---"
    file.puts "title: Posts"
    file.puts "---"
  end

  posts.sort.reverse.each do |url, title|
    File.open('content/blog.md', 'a') do |file|
      file.puts "- [#{title}](#{url})"
    end
  end

  File.open('content/blog.md', 'a') do |file|
    file.puts "{:.posts}"
  end
end

def build_main_pages
  FileUtils.mkdir_p('site')
  
  content_dir = 'content'
  output_dir = 'site'
  template_file = 'templates/layout.liquid'
  
  Dir.glob("#{content_dir}/*.md").each do |file|
    front_matter, body = read_front_matter(file)
    html_content = process_markdown(body)
    
    assigns = {
      'title' => front_matter['title'],
      'date' => front_matter['date'],
      'content' => html_content
    }
    
    rendered_content = render_template(template_file, assigns)
    
    output_file = File.join(output_dir, File.basename(file, '.md') + '.html')
    File.write(output_file, rendered_content)
  end
end

def build_blog_posts
  FileUtils.mkdir_p('site/posts')
  
  content_dir = 'content/posts'
  output_dir = 'site/posts'
  template_file = 'templates/layout.liquid'
  
  Dir.glob("#{content_dir}/*.md").each do |file|
    front_matter, body = read_front_matter(file)
    html_content = process_markdown(body)
    
    assigns = {
      'title' => front_matter['title'],
      'date' => front_matter['date'],
      'content' => html_content,
      'blog_post' => true
    }
    
    rendered_content = render_template(template_file, assigns)
    
    output_file = File.join(output_dir, File.basename(file, '.md') + '.html')
    File.write(output_file, rendered_content)
  end
end

def build_site
  start_time = Time.now
  puts "Starting build"
  sleep(0.1)
  copy_assets
  puts "Copying assets to site directory"
  sleep(0.1)
  build_blog_index_page
  puts "Building blog index"
  sleep(0.1)
  build_main_pages
  puts "Building main pages"
  sleep(0.1)
  build_blog_posts
  puts "Building blog posts"
  sleep(0.1)
  end_time = Time.now 
  puts "Build complete | #{((end_time-start_time).to_f * 1000 - 400).round(2)} ms."
end

build_site
