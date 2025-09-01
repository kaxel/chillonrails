require 'csv'

namespace :import do
  desc "Import authors from CSV file"
  task authors: :environment do
    csv_file_path = Rails.root.join('storage', 'CHILLFLOW - Authors.csv')
    
    unless File.exist?(csv_file_path)
      puts "CSV file not found at: #{csv_file_path}"
      exit 1
    end

    puts "Starting author import from #{csv_file_path}"
    
    imported_count = 0
    skipped_count = 0
    error_count = 0

    CSV.foreach(csv_file_path, headers: true) do |row|
      begin
        # Skip empty rows
        next if row['Name'].blank?

        # Parse datetime strings
        created_on = parse_webflow_date(row['Created On'])
        updated_on = parse_webflow_date(row['Updated On'])
        published_on = parse_webflow_date(row['Published On'])

        # Convert string booleans to actual booleans
        archived = row['Archived'] == 'true'
        draft = row['Draft'] == 'true'
        editorial_chief = row['Editorial chief'] == 'true'

        author_data = {
          name: row['Name'],
          slug: row['Slug'],
          collection_id: row['Collection ID'],
          locale_id: row['Locale ID'],
          item_id: row['Item ID'],
          archived: archived,
          draft: draft,
          created_on: created_on,
          updated_on: updated_on,
          published_on: published_on,
          author_photo: row['Author photo'],
          author_email: row["Author's email"],
          author_position: row["Author's position"],
          about_author: row['About author'],
          social_profile_link_1: row['Social profile link 1'],
          social_profile_link_2: row['Social profile link 2'],
          social_profile_link_3: row['Social profile link 3'],
          editorial_chief: editorial_chief,
          location: row['location']
        }

        # Check if author already exists by slug or item_id
        existing_author = Author.find_by(slug: author_data[:slug]) || 
                         Author.find_by(item_id: author_data[:item_id])

        if existing_author
          puts "Skipping duplicate author: #{author_data[:name]} (#{author_data[:slug]})"
          skipped_count += 1
        else
          Author.create!(author_data)
          puts "Imported: #{author_data[:name]}"
          imported_count += 1
        end

      rescue => e
        puts "Error importing author #{row['Name']}: #{e.message}"
        error_count += 1
      end
    end

    puts "\nImport completed:"
    puts "  Imported: #{imported_count}"
    puts "  Skipped (duplicates): #{skipped_count}"
    puts "  Errors: #{error_count}"
    puts "  Total processed: #{imported_count + skipped_count + error_count}"
  end

  private

  def parse_webflow_date(date_string)
    return nil if date_string.blank?
    
    # Parse the Webflow date format: "Mon Jun 24 2024 01:01:52 GMT+0000 (Coordinated Universal Time)"
    DateTime.parse(date_string)
  rescue ArgumentError => e
    puts "Warning: Could not parse date '#{date_string}': #{e.message}"
    nil
  end
end