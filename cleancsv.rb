require 'csv'
require 'fileutils'

class String
  def remove_non_ascii(replacement='')
    self.gsub(/[\uFFFD]/, replacement)
  end

  def parse_name!
    self.replace(self.split[0])
  end
end

global_start_time = Time.now
duplicates = 0

Dir.glob('input/*.csv') do |file|
  start_time = Time.now

  filename = File.basename(file)
  puts 'Currently processing ' + filename

  rows = CSV.read(file, :headers => true, :skip_blanks => false, :encoding => 'windows-1251:utf-8').reject { |row| row.to_hash.values.all?(&:nil?) }.collect do |row|
    row.to_hash
  end

  puts 'File has a total of ' + rows.length.to_s + ' rows'

  columns = rows.first.keys
  columns.delete(nil)

  if (!columns.include?('First Name') && !columns.include?('Last Name'))
    return p 'Incompatible file columns'
  end

  rows_cache = rows.length
  rows.uniq! { |r| r.values_at('First Name', 'Last Name')}
  post_name_cache = rows.length
  puts (rows_cache - post_name_cache).to_s + ' rows had duplicate names'
  rows.uniq! { |r| r['Borrower Home Phone']}.uniq! { |r| r['Borrower Business Phone']}
  puts (post_name_cache - rows.length).to_s + ' rows had duplicate phone numbers'
  duplicates = rows_cache - rows.length
  puts 'Deleted ' + duplicates.to_s + ' duplicates!'


  new_csv = CSV.generate do |csv|
    csv << columns
    rows.each do |row|
      row['First Name'].parse_name!
      row['Last Name'].parse_name!
      values = row.values.map! { |x| x.remove_non_ascii unless x == nil}
      csv << values
    end
  end

  Dir.chdir('./output') do
    File.open(filename, 'w') { |file| file.write(new_csv) }
  end

  end_time = Time.now
  puts 'Successfully processed ' + filename + ' in ' + ((end_time - start_time)).to_s + ' seconds'
end

global_end_time = Time.now
total_run_time = global_end_time - global_start_time
puts 'Total run time: ' + total_run_time.to_s + ' seconds'

%x(open ./output)
%x(osascript -e 'tell app "Finder" to display dialog "Found a total of #{duplicates} duplicates! Total run time: #{total_run_time} seconds."' )
