require 'rails_helper'
#require 'csv'
require 'tempfile'

# Load the script
require_relative '../../db/scripts/ingest_posts'

RSpec.describe PostsIngester do
  let(:csv_content) do
    <<~CSV
      Name,Slug,content,top-image,video,audio,preview,topic,published_on,location,tags
      "Test Post","test-post","This is test content","https://example.com/test.jpg","https://example.com/video.mp4","https://example.com/audio.mp3","Test preview","Test topic","2024-01-01","usa","web design;programming"
      "Another Post","another-post","More content","","","","Another preview","Another topic","2024-01-02","canada","design"
      "Invalid Date Post","invalid-date","Content with invalid date","","","","Preview","Topic","invalid-date","france","development"
    CSV
  end

  let(:csv_file) do
    file = Tempfile.new(['test_posts', '.csv'])
    file.write(csv_content)
    file.rewind
    file
  end

  let(:ingester) { PostsIngester.new(csv_file.path) }

  before do
    # Clean up test data
    Post.destroy_all
    Location.destroy_all
    Tag.destroy_all
    
    # Create public/art directory for testing
    FileUtils.mkdir_p(Rails.root.join('public/art'))
  end

  after do
    csv_file.close
    csv_file.unlink
  end

  describe '#run' do
    it 'processes CSV file and creates posts' do
      # Mock image download to avoid actual HTTP requests
      allow_any_instance_of(PostsIngester).to receive(:download_image)
      
      expect { ingester.run }.to change { Post.count }.by(3)
      
      # Verify first post was created correctly
      post = Post.find_by(slug: 'test-post')
      expect(post).to be_present
      expect(post.title).to eq('Test Post')
      expect(post.content).to eq('This is test content')
      expect(post.video_link).to eq('https://example.com/video.mp4')
      expect(post.audio_link).to eq('https://example.com/audio.mp3')
      expect(post.preview).to eq('Test preview')
      expect(post.topic).to eq('Test topic')
      expect(post.published_on).to eq(Date.parse('2024-01-01'))
      expect(post.location.name).to eq('United States')
      expect(post.tag.name).to eq('web design')
    end

    it 'handles posts with empty image URLs' do
      expect { ingester.run }.to change { Post.count }.by(3)
      
      post = Post.find_by(slug: 'another-post')
      expect(post.image).to be_nil
    end

    it 'handles invalid dates gracefully' do
      expect { ingester.run }.to change { Post.count }.by(3)
      
      post = Post.find_by(slug: 'invalid-date')
      expect(post.published_on).to be_nil
    end

    it 'creates locations and tags' do
      expect { ingester.run }.to change { Location.count }.by(3)
                                   .and change { Tag.count }.by(3)
    end

    it 'updates existing posts instead of creating duplicates' do
      # Run ingester twice
      allow_any_instance_of(PostsIngester).to receive(:download_image)
      ingester.run
      
      expect { ingester.run }.not_to change { Post.count }
      
      # Verify post was updated, not duplicated
      expect(Post.where(slug: 'test-post').count).to eq(1)
    end
  end

  describe '#normalize_location_name' do
    it 'maps common location variations' do
      expect(ingester.send(:normalize_location_name, 'usa')).to eq('United States')
      expect(ingester.send(:normalize_location_name, 'uk')).to eq('United Kingdom')
      expect(ingester.send(:normalize_location_name, 'canada')).to eq('Canada')
    end

    it 'titleizes unknown locations' do
      expect(ingester.send(:normalize_location_name, 'new york')).to eq('New York')
      expect(ingester.send(:normalize_location_name, 'tokyo')).to eq('Tokyo')
    end
  end

  describe '#process_tags' do
    it 'creates tags from semicolon-separated string' do
      tags = ingester.send(:process_tags, 'web design;programming;ruby')
      expect(tags.map(&:name)).to contain_exactly('web design', 'programming', 'ruby')
    end

    it 'creates tags from comma-separated string' do
      tags = ingester.send(:process_tags, 'design, development, testing')
      expect(tags.map(&:name)).to contain_exactly('design', 'development', 'testing')
    end

    it 'handles empty or blank tag strings' do
      expect(ingester.send(:process_tags, '')).to eq([])
      expect(ingester.send(:process_tags, nil)).to eq([])
    end

    it 'strips whitespace and removes blank entries' do
      tags = ingester.send(:process_tags, ' web design ; ; programming ; ')
      expect(tags.map(&:name)).to contain_exactly('web design', 'programming')
    end
  end

  describe '#extract_filename_from_url' do
    it 'extracts filename with extension from URL' do
      filename = ingester.send(:extract_filename_from_url, 'https://example.com/test.jpg', 'test-post')
      expect(filename).to eq('test-post.jpg')
    end

    it 'defaults to .jpg extension when none provided' do
      filename = ingester.send(:extract_filename_from_url, 'https://example.com/test', 'test-post')
      expect(filename).to eq('test-post.jpg')
    end

    it 'cleans invalid characters from filename' do
      filename = ingester.send(:extract_filename_from_url, 'https://example.com/test.jpg', 'test post!')
      expect(filename).to eq('testpost.jpg')
    end
  end

  describe '#parse_date' do
    it 'parses valid date strings' do
      date = ingester.send(:parse_date, '2024-01-01')
      expect(date).to eq(Date.parse('2024-01-01'))
    end

    it 'handles invalid date strings' do
      date = ingester.send(:parse_date, 'invalid-date')
      expect(date).to be_nil
    end

    it 'handles empty date strings' do
      expect(ingester.send(:parse_date, '')).to be_nil
      expect(ingester.send(:parse_date, nil)).to be_nil
    end
  end

  describe '#process_image' do
    it 'returns nil for blank image URLs' do
      result = ingester.send(:process_image, '', 'test-post')
      expect(result).to be_nil
    end

    it 'returns existing image path if file exists' do
      # Create a test image file
      test_image_path = Rails.root.join('public/art/test-post.jpg')
      FileUtils.touch(test_image_path)
      
      result = ingester.send(:process_image, 'https://example.com/test.jpg', 'test-post')
      expect(result).to eq('/art/test-post.jpg')
      
      # Cleanup
      File.delete(test_image_path) if File.exist?(test_image_path)
    end

    it 'attempts to download image if it does not exist' do
      allow(ingester).to receive(:download_image).and_return(true)
      
      result = ingester.send(:process_image, 'https://example.com/test.jpg', 'test-post')
      expect(result).to eq('/art/test-post.jpg')
      expect(ingester).to have_received(:download_image)
    end

    it 'handles download failures gracefully' do
      allow(ingester).to receive(:download_image).and_raise(StandardError.new('Download failed'))
      
      result = ingester.send(:process_image, 'https://example.com/test.jpg', 'test-post')
      expect(result).to be_nil
    end
  end

  describe 'error handling' do
    let(:invalid_csv_content) do
      <<~CSV
        Name,Slug,content,top-image,video,audio,preview,topic,published_on,location,tags
        "Test Post","","This is test content","","","","Preview","Topic","2024-01-01","usa","web design"
      CSV
    end

    let(:invalid_csv_file) do
      file = Tempfile.new(['invalid_posts', '.csv'])
      file.write(invalid_csv_content)
      file.rewind
      file
    end

    it 'handles validation errors gracefully' do
      invalid_ingester = PostsIngester.new(invalid_csv_file.path)
      
      # This should not raise an exception
      expect { invalid_ingester.run }.not_to raise_error
      
      invalid_csv_file.close
      invalid_csv_file.unlink
    end
  end
end