#!/usr/bin/env ruby

require 'csv'
require 'fileutils'
require 'net/http'
require 'uri'
require 'open-uri'
require 'openssl'

# Add Rails environment
require_relative '../config/environment'

class PostImporter
  def initialize(csv_file_path)
    @csv_file_path = csv_file_path
    @processed_count = 0
    @error_count = 0
  end

  def import
    puts "Starting import from #{@csv_file_path}..."
    
    CSV.foreach(@csv_file_path, headers: true) do |row|
      begin
        
        #this_row = PostIngest.new("row").feed_line(row)
        
        this_row = PostIngest.new(row['name'])
        this_row.feed_line(row)
        process_post(this_row)
        
        @processed_count += 1
        puts "Processed: #{row['Name']}"
      rescue => e
        @error_count += 1
        puts "Error processing #{row['Name']}: #{e.message}"
        puts e.backtrace.first(5)
      end
    end
    
    puts "\nImport completed!"
    puts "Successfully processed: #{@processed_count} posts"
    puts "Errors: #{@error_count} posts"
  end

  private

  def process_post(this_row)
    # puts "show this_row"
    # puts this_row.preview
    
    newpost = Post.new

    # Download and set images
    if this_row.image
      puts "image found: #{this_row.image}"
      # download w/ file_ext = 'main' (default)
      image_filename = download_image(this_row.image, this_row.slug)
      newpost.image = image_filename if image_filename
    end
    
    newpost.title = this_row.title
    newpost.author = this_row.author
    
    newpost.slug = this_row.slug
    puts "saving #{this_row.slug} as #{newpost.slug}"
    newpost.video_link = this_row.video
    newpost.audio_link = this_row.audio
    newpost.preview = this_row.preview
    newpost.topic = this_row.topic
    newpost.published_on = this_row.published_on
    newpost.created_on = this_row.created_on
    newpost.content = this_row.content
    newpost.location = this_row.location
    newpost.tags = this_row.tags
    
    # find content img links
    links = this_row.content_link
    new_content = this_row.content
    if links && links.any?
      links.each_with_index do |link, index|
        # download w/ file_ext = 'content' + index for multiple images
        file_ext = index == 0 ? "content" : "content#{index + 1}"
        new_img_loc = download_image(link, this_row.slug, file_ext)
        # replace each link with its downloaded location
        new_content = new_content.gsub(link, new_img_loc) if new_img_loc
      end
      newpost.content = new_content
    end
    
    newpost.save!
    puts ""
  end

  def find_or_create_location(location_name)
    return nil if location_name.blank?
    
    Location.find_or_create_by(name: location_name.downcase) do |location|
      location.slug = location_name.downcase.parameterize
      location.description = "Auto-created from import"
    end
  end

  def find_or_create_tag(tags_string)
    return nil if tags_string.blank?
    
    # Take first tag if multiple
    tag_name = tags_string.split(';').first.strip
    
    Tag.find_or_create_by(name: tag_name) do |tag|
      tag.slug = tag_name.parameterize
    end
  end

  def clean_content(content)
    return '' if content.blank?
    
    # Remove empty id attributes
    content.gsub(/id=""[^"]*"/, '')
  end

  def parse_date(date_string)
    return nil if date_string.blank?
    
    begin
      Date.parse(date_string)
    rescue
      nil
    end
  end

  def download_image(image_url, slug, filename_ext = nil)
    return nil if image_url.blank?
    
    # Create directory for this post's images
    image_dir = Rails.root.join('public', 'images', 'posts', slug)
    FileUtils.mkdir_p(image_dir)
    
    # Extract filename from URL
    uri = URI.parse(image_url)
    filename = "#{slug}-#{filename_ext ? filename_ext : 'main'}-image.jpg"
    
    # Download the file
    local_path = image_dir.join(filename)
    
    begin
      URI.open(image_url, 'rb', ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE) do |file|
        File.open(local_path, 'wb') do |local_file|
          local_file.write(file.read)
        end
      end
      
      puts "Downloaded image: #{image_url} -> #{local_path}"
      # Return the relative path for storing in database
      "/images/posts/#{slug}/#{filename}"
    rescue => e
      puts "Failed to download image #{image_url}: #{e.message}"
      nil
    end
  end

  def download_content_images(content, slug)
    return content if content.blank?
    
    # Find all img tags with src attributes
    content.gsub(/<img[^>]+src="([^"]+)"[^>]*>/i) do |img_tag|
      original_url = $1
      
      # Skip if it's already a local path
      next img_tag if original_url.start_with?('/')
      
      # Download the image
      local_path = download_image(original_url, slug)
      
      if local_path
        # Replace the src with local path
        img_tag.gsub(original_url, local_path)
      else
        img_tag
      end
    end
  end
end

# Run the importer
if __FILE__ == $0
  csv_file = ARGV[0] || Rails.root.join('storage', 'CHILLFLOW - Articles - full.csv')
  
  unless File.exist?(csv_file)
    puts "CSV file not found: #{csv_file}"
    exit 1
  end
  
  importer = PostImporter.new(csv_file)
  importer.import
end