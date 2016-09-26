
#
# This module handles the saving and loading within the game, aswell as creating new profiles and loading profiles
#
module SaveManager
  #
  # Saves player xy coords, hp, max hp, experience, and current map
  #
  def self.update_player_database(map)
    $player_db.execute("UPDATE stats SET x=#{map.player.x-16}")
    $player_db.execute("UPDATE stats SET y=#{map.player.y-16}")
    $player_db.execute("UPDATE stats SET current_health=#{map.player.hp}")
    $player_db.execute("UPDATE stats SET max_health=#{map.player.max_hp}")
    $player_db.execute("UPDATE stats SET current_player_xp=#{map.player.player_xp}")
    $player_db.execute("UPDATE stats SET current_sword_xp=#{map.player.sword_xp}")
    $player_db.execute("UPDATE stats SET current_map='#{map.current_level}'")
  end
  
  #
  # Saves the position of doors as an array
  #
  def self.save_door_positions(door_array)
    door_array.each do |door|
      door.update_db($db)
    end
  end
  
  #
  # Opens source database for backing up, creates destination database and then backs it up
  #
  def self.copy_database(source_path, destination_path)
    db = SQLite3::Database.new(source_path)
    dest_db = SQLite3::Database.new(destination_path)
    b = SQLite3::Backup.new(dest_db, 'main', db, 'main')
    b.finish
    ddb = SQLite3::Database.new(destination_path)
    b = SQLite3::Backup.new(dest_db, 'main', db, 'main')
    b.step(-1)
    b.finish
  end
  
  #
  # Starts a new game with a given profile name
  #
  def self.new_game(profile_name)
    save_path = "../saves/#{profile_name}"
    # Delete old tables if they exist
    if directory_exists?(save_path) then
      FileUtils.rm_rf(save_path) # Remove the directory and all files inside
    end
    # ---
    Dir.mkdir(save_path) # Make a new directory
    # Populate new directory with copies of files ---
    copy_database('../core_files/databases/core_database.db', "#{save_path}/core_database.db")
    copy_database('../core_files/databases/player.db', "#{save_path}/player.db")
    # ---
    # Initialize the correct database
    Databases.init(save_path)
    # ---
  end
  
  #
  # Loads enemies, player status, and door states from database
  #
  def self.continue_game(profile_name)
    Databases.init("../saves/#{profile_name}")
  end
end

