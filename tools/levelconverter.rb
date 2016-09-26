=begin
  This converts all of the old style levels to the new style
=end


ARGV.clear()
Dir.chdir(File.dirname(__FILE__))

require_relative 'bin/lib/lib.rb'
require_relative 'bin/lib/lib_misc.rb'


def marshalfileread(file)
  if ! File.exists?(file) then
    $log.warn("Marshal file doesn't exist: #{file.inspect}")
    vputs 'That file doesn\'t exist: '  + file.inspect
    return ''
  end
  begin
    return Marshal::load( File.open(file, 'r') )
  rescue
    puts "Error reading file: #{file.inspect}"
    return ''
  end
end


def convert_level(filename)
  return nil if filename == ''
  if File.exists?("core_files/levels/#{filename}/level.dat") then
    map_array = Array.new(2){Array.new(64){Array.new(64)}}
    read_file = marshalfileread("core_files/levels/#{filename}/level.dat")
    3.times do |z|
      64.times do |y|
        64.times do |x|
          if read_file[z][y][x] != ' ' and read_file[z][y][x] != "\n" and read_file[z][y][x] != '' then
            info_array = read_file[z][y][x].split('////')
            info_array[2] = info_array[2].to_i
            if info_array[1] == 'floor' then
              index = 0
            elsif info_array[1] == 'wall' then
              index = 1
            elsif info_array[1] == 'light' then
              index = 1
            end
            map_array[index][y][x] = info_array
          end
        end
      end
    end
    File.open("core_files/levels/#{filename}/level_converted.dat", 'wb') do |f|
      f.print Marshal::dump(map_array)
    end
    puts 'File converted!'
  else
    puts 'File doesn\'t exist!'
  end
end


print 'Enter name of level to convert: '
filename = gets.chomp


if filename == 'all' then
  search_directory('core_files/levels').each do |path|
    convert_level(path.split('/').last)
  end
else
  convert_level(filename)
end
