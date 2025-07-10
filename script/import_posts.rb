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
        #process_post(row)
        this_row = PostIngest.new("row").feed_line(row)
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

  def process_post(row)

    
    # Download and set images
    if row['top-image'].present?
      image_filename = download_image(row['top-image'], row['Slug'])
      post.image = image_filename if image_filename
    end
    
    # Download images from content
    post.content = download_content_images(post.content, row['Slug'])
    
    post.save!
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

  def download_image(image_url, slug)
    return nil if image_url.blank?
    
    # Create directory for this post's images
    image_dir = Rails.root.join('public', 'images', 'posts', slug)
    FileUtils.mkdir_p(image_dir)
    
    # Extract filename from URL
    uri = URI.parse(image_url)
    filename = File.basename(uri.path)
    filename = "#{slug}-main.jpg" if filename.blank? || filename == '/' # fallback filename
    
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
  csv_file = ARGV[0] || Rails.root.join('storage', 'CHILLFLOW - Articles - sample 100.csv')
  
  unless File.exist?(csv_file)
    puts "CSV file not found: #{csv_file}"
    exit 1
  end
  
  importer = PostImporter.new(csv_file)
  importer.import
end