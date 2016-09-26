
#
# The Databases module and submodules contain methods that handle database transactions.
#

$db = nil
$player_db = nil

#
# Checks if a specified table exists, if so - return true, otherwise - return false
#
def table_exists?(db, tablename)
  if db.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='#{tablename}'").count > 0 then
    return true
  else
    return false
  end
end

$db = nil

#
# Contains modules and methods related to database connectivity
#
module Databases
  #
  # Assigns the global variables $db and $player_db to the correct database
  #
  def self.init(path)
    $db = SQLite3::Database.new("#{path}/core_database.db")
    $player_db = SQLite3::Database.new("#{path}/player.db")
  end
  
  #
  # Closes the $db and $player_db databases
  #
  def self.unload()
    $db.close() if $db != nil
    $player_db.close() if $player_db != nil
    $db = nil
    $player_db = nil
  end
  
  #
  # A submodule which contains methods specific to the <npc> table in the database
  #
  module NPC
    #
    # Returns all the npcs from a specific map -- Used in game for loading
    #
    def self.get_npcs_from_map(map)
      return $db.execute("Select * From npc Where map = '#{map}'")
    end
  end
  
  #
  # A submodule which contains methods specific to the <enemy> table in the database
  #
  module Enemy
    #
    # Add into the table enemy a enemy value -- Used in the level editor
    #
    def self.add_enemy(enemy_type, map, x, y)
      $db.execute("Insert Into enemy(enemy_type, map, x, y) Values('#{enemy_type}', '#{map}', #{x}, #{y})")
    end
    
    #
    # Returns a specified column from table enemy
    #
    def self.get_column(column)
      return $db.execute("Select #{column} From enemy")
    end
    
    #
    # Returns all the enemies from a specific map -- Used in both the editor and game for loading
    #
    def self.get_enemies_from_map(map)
      return $db.execute("Select * From enemy Where map = '#{map}'")
    end
    
    #
    # Delete all enemies in table enemy for a specific map -- Used in editor when saving
    #
    def self.clear_enemies_from_map(map)
      return $db.execute("Delete From enemy Where map = '#{map}'")
    end
    
    #
    # Updates a specific enemy in the database
    #
    def self.update_enemy(enemy_id, x, y)
      $db.execute("Update enemy Set x = #{x}, y = #{y} Where enemy_id = #{enemy_id}")
    end
  end
  
  #
  # A submodule which contains methods specific to the <door> table in the database
  #
  module Door
    #
    # Adds a door to the door database
    #
    def self.add_door(door_state, level, map, x, y, is_locked=0)
      $db.execute("Insert Into door(door_state, map, x, y, is_locked) Values('#{door_state}', '#{map}', '#{x}', '#{y}', #{is_locked})")
    end
    
    #
    # Returns all the doors from a specified map -- Used in both the editor and game for loading
    #
    def self.get_doors_from_map(map)
      return $db.execute("Select * From door Where map = '#{map}'")
    end
    
    #
    # Returns an array of items from a specified column in the door database
    #
    def self.get_column(column)
      return $db.execute("Select #{column} From door")
    end
    
    #
    # Delete all doors in table door for a specific map -- Used in Database interface
    #
    def self.clear_doors_from_map(map)
      return $db.execute("Delete From door Where map = '#{map}'")
    end
  end
  
  #
  # A submodule which contains methods specific to the <warps> table in the database
  #
  module Warps
    #
    # Delete all warps in table warps for a specific map -- Used in Database interface
    #
    def self.clear_warps_from_map(source_map)
      return $db.execute("Delete From warps Where source_map = '#{source_map}'")
    end
  end
end


#
# Console configuration interface -- only used when making game, never used when playing
#
if ARGV[0].class == String then
  if ARGV[0].gsub('-','').gsub('/','') == 'config' then
    ARGV.clear()
    require 'sqlite3'
    Databases.init('../core_files/databases')
    puts "Database Config.\n\n" # Display user's options
    puts 'Options:'
    puts '1: Delete all enemies from a specific map.'
    puts '2: Delete all warps from a specific map.'
    puts '3: Delete all doors from a specific map.'
    puts '4: Delete all elements from a specific map.'
    puts "5: Exit.\n"
    exit = false
    while exit == false
      print "\n"
      print 'Enter Option: '
      option = gets.chomp.to_i
      #print "\n"
      if option == 1 then
        begin
          # --- Deleting enemies from database
          print 'Enter the name of the map: '
          map = gets.chomp
          Databases::Enemy.clear_enemies_from_map(map)
        rescue => error
          puts "SQLite3 Error: #{error}"
        end
      elsif option == 2 then
        begin
          # --- Deleting warps from database
          print 'Enter the name of the source map: '
          source_map = gets.chomp
          Databases::Warps.clear_warps_from_map(source_map)
        rescue => error
          puts "SQLite3 Error: #{error}"
        end
      elsif option == 3 then
        begin
          # --- Deleting doors from database
          print 'Enter the name of the map: '
          map = gets.chomp
          Databases::Door.clear_doors_from_map(map)
        rescue => error
          puts "SQLite3 Error: #{error}"
        end 
      elsif option == 4 then
        begin
          # --- Deleting all elements from database
          print 'Enter the name of the map: '
          map = gets.chomp
          Databases::Warps.clear_warps_from_map(map)
          Databases::Door.clear_doors_from_map(map)
          Databases::Enemy.clear_enemies_from_map(map)
        rescue => error
          puts "SQLite3 Error: #{error}"
        end 
      elsif option == 5 then
        exit = true
      else
        puts "Unknown Option- #{option}"
      end
    end
    $db.close()
  end
end



