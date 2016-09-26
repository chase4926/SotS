
require 'yaml'

def create_file(file, file_contents)
  begin
    File.open(file, 'w+') do |f|  # open file for update
      f.print file_contents       # write out the example description
    end                           # file is automatically closed
  rescue Exception
  end
end


example_message = 'This is an
example message'


npc_hash = {}

print 'Type the name of the NPC: '
npc_hash['name'] = gets.chomp
print 'Type the name of the picture to use: '
npc_hash['picture'] = gets.chomp
# Default values--
npc_hash['message'] = example_message
npc_hash['ignore_player'] = false
# ---
print 'Enter a filename: '
filename = gets.chomp
create_file("../#{filename}.yml", npc_hash.to_yaml)
puts "NPC file: #{filename}.yml generated"

