namespace :db do
  desc "Optimize the database (VACUUM ANALYZE)"
  task optimize: :environment do
    puts "Starting database optimization..."
    start_time = Time.current

    ActiveRecord::Base.connection_pool.with_connection do |conn|
      # Get list of all tables
      tables = conn.tables.reject { |t| t == "ar_internal_metadata" || t == "schema_migrations" }

      puts "Optimizing #{tables.count} tables..."

      tables.each do |table|
        print "  Optimizing #{table}... "
        begin
          conn.execute("VACUUM ANALYZE #{conn.quote_table_name(table)}")
          puts "✓"
        rescue => e
          puts "✗ (#{e.message})"
        end
      end
    end

    elapsed = Time.current - start_time
    puts "\nOptimization completed in #{elapsed.round(2)} seconds"
  end

  desc "Deep optimize the database (VACUUM FULL and REINDEX) - locks tables!"
  task deep_optimize: :environment do
    puts "⚠️  WARNING: This will lock tables during optimization!"
    puts "Only run this during maintenance windows.\n\n"

    start_time = Time.current

    ActiveRecord::Base.connection_pool.with_connection do |conn|
      tables = conn.tables.reject { |t| t == "ar_internal_metadata" || t == "schema_migrations" }

      puts "Deep optimizing #{tables.count} tables..."

      tables.each do |table|
        print "  VACUUM FULL #{table}... "
        begin
          conn.execute("VACUUM FULL ANALYZE #{conn.quote_table_name(table)}")
          puts "✓"
        rescue => e
          puts "✗ (#{e.message})"
        end

        print "  REINDEX #{table}... "
        begin
          conn.execute("REINDEX TABLE #{conn.quote_table_name(table)}")
          puts "✓"
        rescue => e
          puts "✗ (#{e.message})"
        end
      end
    end

    elapsed = Time.current - start_time
    puts "\nDeep optimization completed in #{elapsed.round(2)} seconds"
  end

  desc "Show database statistics and bloat information"
  task stats: :environment do
    ActiveRecord::Base.connection_pool.with_connection do |conn|
      puts "Database Statistics\n"
      puts "=" * 80

      # Database size
      db_name = conn.current_database
      result = conn.execute("SELECT pg_size_pretty(pg_database_size('#{db_name}')) as size")
      puts "\nDatabase size: #{result.first['size']}"

      # Table sizes
      puts "\nTable Sizes:"
      puts "-" * 80
      query = <<-SQL.squish
        SELECT
          schemaname,
          tablename,
          pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size,
          pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) AS table_size,
          pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename) - pg_relation_size(schemaname||'.'||tablename)) AS index_size
        FROM pg_tables
        WHERE schemaname = 'public'
        ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
        LIMIT 20
      SQL

      results = conn.execute(query)
      results.each do |row|
        puts "  #{row['tablename'].ljust(30)} Total: #{row['size'].ljust(10)} (Table: #{row['table_size']}, Indexes: #{row['index_size']})"
      end

      # Index usage
      puts "\nIndex Usage (least used):"
      puts "-" * 80
      query = <<-SQL.squish
        SELECT
          schemaname,
          tablename,
          indexname,
          idx_scan as scans,
          pg_size_pretty(pg_relation_size(indexrelid)) as size
        FROM pg_stat_user_indexes
        WHERE schemaname = 'public'
        ORDER BY idx_scan ASC, pg_relation_size(indexrelid) DESC
        LIMIT 10
      SQL

      results = conn.execute(query)
      if results.any?
        results.each do |row|
          puts "  #{row['indexname'].ljust(40)} Scans: #{row['scans'].to_s.ljust(10)} Size: #{row['size']}"
        end
      else
        puts "  No index statistics available"
      end

      # Cache hit ratio
      puts "\nCache Hit Ratio:"
      puts "-" * 80
      query = <<-SQL.squish
        SELECT
          sum(heap_blks_read) as heap_read,
          sum(heap_blks_hit)  as heap_hit,
          sum(heap_blks_hit) / (sum(heap_blks_hit) + sum(heap_blks_read)) * 100 AS ratio
        FROM pg_stattio_user_tables
      SQL

      result = conn.execute(query).first
      if result["heap_read"].to_i > 0
        puts "  #{result['ratio'].to_f.round(2)}% (should be > 99%)"
      else
        puts "  No statistics available yet"
      end
    end
  end
end
