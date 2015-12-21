require 'csv'
require 'fileutils'

class String
  def remove_non_ascii(replacement='')
    self.gsub(/[\uFFFD]/, replacement)
  end
end

def parse_name(values, row)
  parsed_name = row['Full Name'].split
  if parsed_name.length > 2
    until parsed_name.length == 2
      parsed_name.delete_at(1)
    end
  end
  new_values = []
  parsed_name.each do |n|
    new_values << n.capitalize
  end
  return new_values += values
end

Dir.glob('csvs/*.csv') do |file|
  filename = File.basename(file)
  puts 'Currently processing ' + filename

  rows = CSV.read(file, :headers => true, :skip_blanks => false).reject { |row| row.to_hash.values.all?(&:nil?) }.collect do |row|
    row.to_hash
  end

  parse_names = true
  columns = rows.first.keys
  columns.delete(nil)
  if (columns.include?('First Name')) && (columns.include?('Last Name'))
    parse_names = false
    rows = CSV.read(file, :headers => true, :skip_blanks => false).reject { |row| row.to_hash.values.all?(&:nil?) }.uniq {|r| [r[1].downcase, r[0].downcase]}.collect do |row|
      row.to_hash
    end
    p parse_names
  else
    columns.delete('First Name')
    columns.delete('Last Name')
    new_columns = ['First Name', 'Last Name']
    columns += new_columns
    p rows[0]
    rows = CSV.read(file, :headers => true, :skip_blanks => false).reject { |row| row.to_hash.values.all?(&:nil?) }.uniq {|r| r[0]}.collect do |row|
      row.to_hash
    end
  end

  new_csv = CSV.generate do |csv|
    csv << columns
    rows.each do |row|
      values = row.values.map! {|x| x.remove_non_ascii unless x == nil }
      row.delete(nil)
      if parse_names === true
        csv << parse_name(values, row)
      else
        values[0].capitalize!
        values[1].capitalize!
        csv << values
      end
    end
  end

  Dir.chdir('./output') do
    File.open(filename, 'w') { |file| file.write(new_csv) }
  end

  puts "Successfully processed " + filename
end
