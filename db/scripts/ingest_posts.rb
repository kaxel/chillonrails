#!/usr/bin/env ruby
require 'csv'
require 'pathname'

# Load Rails environment
require_relative '../../config/environment'

class PostsIngester
  def initialize(csv_file_path)
    @csv_file_path = csv_file_path
    @storage_dir = Rails.root.join('storage')
    @public_art_dir = Rails.root.join('public', 'art')
    @stats = {
      processed: 0,
      created: 0,
      updated: 0,
      errors: 0
    }
  end

  def run
    puts "Starting CSV ingestion from #{@csv_file_path}"
    
    CSV.foreach(@csv_file_path, headers: true) do |row|
      @stats[:processed] += 1
      
      begin
        process_row(row)
        @stats[:created] += 1
      rescue => e
        @stats[:errors] += 1
        puts "Error processing row #{@stats[:processed]}: #{e.message}"
        puts "Row data: #{row.to_h}"
      end
    end
    
    print_stats
  end

  private

  def process_row(row)
    # Find or create location
    location = find_or_create_location(row['location'])
    
    # Process tags (can be multiple separated by semicolon)
    tags = process_tags(row['tags'])
    primary_tag = tags.first
    
    # Download and process image
    image_path = process_image(row['top-image'], row['Slug'])
    
    # Create or update post
    post = Post.find_or_initialize_by(slug: row['Slug'])
    
    post.assign_attributes(
      title: row['Name'],
      slug: row['Slug'],
      content: row['content'],
      image: image_path,
      video_link: row['video'],
      audio_link: row['audio'],
      preview: row['preview'],
      topic: row['topic'],
      published_on: parse_date(row['published_on']),
      location: location,
      tag: primary_tag
    )
    
    post.save!
    
    puts "#{post.persisted? ? 'Created' : 'Updated'} post: #{post.title}"
  end

  def find_or_create_location(location_name)
    return nil if location_name.blank?
    
    # Normalize location name
    normalized_name = normalize_location_name(location_name)
    
    location = Location.find_or_initialize_by(name: normalized_name)
    if location.new_record?
      location.save!
      puts "Created location: #{normalized_name}"
    end
    
    location
  end

  def normalize_location_name(location_name)
    # Map common location variations to normalized names
    location_mapping = {
      'usa' => 'United States',
      'uk' => 'United Kingdom',
      'canada' => 'Canada',
      'australia' => 'Australia',
      'france' => 'France',
      'germany' => 'Germany',
      'japan' => 'Japan',
      'brazil' => 'Brazil',
      'netherlands' => 'Netherlands',
      'switzerland' => 'Switzerland',
      'ireland' => 'Ireland',
      'india' => 'India'
    }
    
    location_mapping[location_name.downcase] || location_name.titleize
  end

  def process_tags(tags_string)
    return [] if tags_string.blank?
    
    tag_names = tags_string.split(/[;,]/).map(&:strip).reject(&:blank?)
    
    tag_names.map do |tag_name|
      tag = Tag.find_or_initialize_by(name: tag_name)
      if tag.new_record?
        tag.save!
        puts "Created tag: #{tag_name}"
      end
      tag
    end
  end

  def process_image(image_url, slug)
    return nil if image_url.blank?
    
    # Extract filename from URL
    filename = extract_filename_from_url(image_url, slug)
    
    # Check if file already exists in public/art
    local_path = @public_art_dir.join(filename)
    
    if local_path.exist?
      puts "Image already exists: #{filename}"
      return "/art/#{filename}"
    end
    
    # Download image
    begin
      download_image(image_url, local_path)
      puts "Downloaded image: #{filename}"
      return "/art/#{filename}"
    rescue => e
      puts "Failed to download image #{image_url}: #{e.message}"
      return nil
    end
  end

  def extract_filename_from_url(url, slug)
    # Extract extension from URL
    extension = File.extname(URI.parse(url).path)
    extension = '.jpg' if extension.empty?
    
    # Create filename from slug
    filename = "#{slug}#{extension}"
    
    # Clean filename
    filename.gsub(/[^a-zA-Z0-9\-_.]/, '')
  end

  def download_image(url, local_path)
    require 'net/http'
    require 'uri'
    
    uri = URI.parse(url)
    
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
      request = Net::HTTP::Get.new(uri)
      response = http.request(request)
      
      if response.code == '200'
        File.open(local_path, 'wb') do |file|
          file.write(response.body)
        end
      else
        raise "HTTP #{response.code}: #{response.message}"
      end
    end
  end

  def parse_date(date_string)
    return nil if date_string.blank?
    
    begin
      Date.parse(date_string)
    rescue ArgumentError
      puts "Warning: Invalid date format '#{date_string}', skipping published_on"
      nil
    end
  end

  def print_stats
    puts "\n" + "="*50
    puts "CSV Ingestion Complete"
    puts "="*50
    puts "Processed: #{@stats[:processed]} rows"
    puts "Created: #{@stats[:created]} posts"
    puts "Updated: #{@stats[:updated]} posts"
    puts "Errors: #{@stats[:errors]} rows"
    puts "="*50
  end
end

# Run the ingester
if __FILE__ == $0
  csv_file = Rails.root.join('storage', 'CHILLFLOW - Articles - sample.csv')
  
  unless File.exist?(csv_file)
    puts "CSV file not found: #{csv_file}"
    exit 1
  end
  
  # Ensure public/art directory exists
  FileUtils.mkdir_p(Rails.root.join('public', 'art'))
  
  ingester = PostsIngester.new(csv_file)
  ingester.run
end