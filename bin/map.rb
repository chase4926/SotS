
#
# The Tile class contains contains information specific to a certain map tile.
#
class Tile < Lighting
  # x position of the tile
  attr_accessor :x
  # y position of the tile
  attr_accessor :y
  # z position of the tile
  attr_accessor :z
  # type of tile [floor, wall, light]
  attr_accessor :type
  # name of the tileset
  attr_accessor :name
  # tile number on the tileset
  attr_accessor :tile_number
  # the tile's color
  attr_reader :color
  
  #
  # Sets the tile's image and initializes lighting
  #
  def initialize(image)
    @image = image
    @x = @y = @z = 0
    @type = nil
    @name = nil
    @tile_number = nil
    lighting_initialize()
  end
  
  #
  # Called after the lighting on the block changes, used to change the block's color
  #
  def updatecolor( brightness, preloaded=nil )
    if @dynamic_array.max == nil or @static_level >= @dynamic_array.max then
      calculated_level = @static_level
    else
      calculated_level = @dynamic_array.max
    end
    
    if preloaded != nil then
      if calculated_level <= brightness then
        @color = preloaded[brightness]
      else
        @color = preloaded[calculated_level]
      end
    else
      if calculated_level <= brightness then
        @color = Gosu::Color.rgba(brightness, brightness, brightness, 255)
      else
        @color = Gosu::Color.rgba(calculated_level, calculated_level, calculated_level, 255)
      end
    end
  end
  
  #
  # Draws the tile
  #
  def draw(lighting=0)
    if lighting == 1 then
      @image.draw(@x, @y, @z, 1, 1, @color)
    else
      @image.draw(@x, @y, @z)
    end
  end
end


#
# The Door class contains information specific to a certain door in a level.
#
class Door
  # x position of the door
  attr_reader :x
  # y position of the door
  attr_reader :y
  # current cell the map occupies
  attr_reader :current_cell
  # 0 if the door is open, 1 if the door is closed
  attr_reader :state
  
  #
  # Sets the door's image, location, and id
  #
  def initialize(id, door_image, cell_x, cell_y, state)
    @image = door_image
    @id = id
    @x = cell_x * 32
    @y = cell_y * 32
    @current_cell = [cell_x, cell_y]
    @state = state
    @color = Gosu::Color.rgba(0, 0, 0, 255)
  end
  
  #
  # Changes the @color variable to the color of the tile beneath the door
  #
  def change_lighting(tile)
    if state == 0 then
      @color = Gosu::Color.rgba(tile.color.red, tile.color.green, tile.color.blue, 96)
    else
      @color = tile.color
    end
  end
  
  #
  # Opens the door if it's closed, closes the door if it's open
  #
  def toggle()
    if @state == 0 then
      @state = 1
    else
      @state = 0
    end
  end
  
  #
  # Returns true if the door is open, otherwise it returns else
  #
  def open?()
    @state == 0
  end
  
  #
  # Returns true if the door is closed, otherwise it returns else
  #
  def closed?()
    @state == 1
  end
  
  #
  # Updates the database to apply the current door settings
  #
  def update_db(db)
    db.execute("UPDATE door SET door_state=#{@state} WHERE door_id=#{@id}")
  end
  
  #
  # Draws the door
  #
  def draw()
    @image.draw(@x, @y, 1, 1, 1, @color)
  end
end


#
# The Scripted_Event contains information specific to a scripted event.
#
class Scripted_Event
  #
  # Sets the info for the scripted event
  #
  def initialize()
    @catacombs_info = {'map' => 'dungeon_catacombs', 'cell' => [10,45]}
  end
  
  #
  # Checks the current player position to see when to trigger the event
  #
  def check(map)
    if @catacombs_info != nil and map.current_level == @catacombs_info['map'] and
       map.player.current_cell == @catacombs_info['cell'] and map.player.player_level < 50 then
       num_of_levels = 50 - map.player.player_level
       num_of_levels = 0 if num_of_levels < 1
       map.player.level_up(:player, num_of_levels)
       num_of_levels = 50 - map.player.sword_level
       num_of_levels = 0 if num_of_levels < 1
       map.player.level_up(:sword, num_of_levels)
       map.player.go_crazy()
       @catacombs_info = nil
    end
  end
end


#
# The Item class contains information specific to a certain dropped item.
#
class Item
  # x position of the item
  attr_accessor :x
  # y position of the item
  attr_accessor :y
  # z position of the item
  attr_accessor :z
  # Cell the item is located in
  attr_accessor :cell
  # Type of item
  attr_reader :type
  # If the item is a potion, the amount of health the potion contains
  attr_reader :health
  
  #
  # Sets various variables related to the item
  #
  def initialize(window, type, x, y, cell, enemy_level, item_image_array, color=Gosu::Color.rgba(255,255,255,255))
    @health = nil
    if type == 'healing_potion' then
      @image = item_image_array[0] #Set image to Healing Potion
      @health = (((enemy_level-1) * 5) + 20).round
    else
      @image = item_image_array.last #Set image to question mark image if item not found
    end
    @type = type
    @x = x
    @y = y
    @z = 0.45
    @cell = cell
    @color = color
  end
  
  #
  # Draws the item
  #
  def draw()
    @image.draw(@x, @y, @z, 1, 1, @color)
  end
end


#
# The NPC class contains information specific to a certain npc on the a level.
#
class NPC
  # the x pixel position of the npc
  attr_reader :x
  # the y pixel position of the npc
  attr_reader :y
  # an array of cell coordinates of the npc
  attr_reader :current_cell
  
  #
  # Initializes various variables and reads data from the data_hash passed in
  #
  def initialize(window, font, data_hash)
    @message_box = Image.new(window, "../mainfiles/media/npc_text/#{data_hash['config_file']}.png", false)
    @image = data_hash['picture']
    @name = data_hash['name']
    @x = data_hash['x'] + 16
    @y = data_hash['y'] + 16
    @id = data_hash['id']
    @ignore_player = data_hash['ignore_player']
    @original_angle = @desired_angle = @angle = data_hash['angle']
    @view_distance = 36 # In pixels
    @current_cell = [(@x/32).round,(@y/32).round]
    @player_in_range = false
    @color = Gosu::Color.rgba(0, 0, 0, 255)
  end
  
  #
  # Changes the passed angle to a cardinal direction
  #
  def to_direction(angle)
    if angle >=45 and angle < 135 then
      return 90
    elsif angle >= 135 and angle < 225 then
      return 180
    elsif angle >= 225 and angle < 315 then
      return 270
    elsif angle >= 315 and angle < 360 then
      return 0
    elsif angle >= 0 and angle < 45 then
      return 0
    else
      vputs 'Weird angle in \'to_direction\' method of \'NPC\' class.'
      return 0
    end
  end
  
  #
  # Changes the @color variable to the color of the tile beneath the npc
  #
  def change_lighting(tile)
    @color = tile.color
  end
  
  #
  # Changes @angle to face the player
  #
  def face_player(player)
    @desired_angle = to_direction(Gosu::angle(@x, @y, player.x, player.y))
  end
  
  #
  # Updates the npc, and performs various checks in relation to the player
  #
  def update(map)
    @angle = angle_smoother(@angle, @desired_angle, 16)
    if map.player == nil then
      @player_in_range = false
    else
      @player_in_range = Gosu::distance(@x, @y, map.player.x, map.player.y) <= @view_distance
    end
    if not @ignore_player then
      if @player_in_range then
        # Stare in the player's direction
        face_player(map.player)
      elsif @desired_angle != @original_angle then
        # Player is away, reset angle
        @desired_angle = @original_angle
      end
    end
  end
  
  #
  # Draws the npc to the screen
  #
  def draw()
    @image.draw_rot(@x, @y, 1, @angle, 0.5, 0.5, 1, 1, @color)
    @message_box.draw(@x - 64, @y - @message_box.height - 8, 1.1) if @player_in_range
  end
end


#
# The Warp class contains information specific to a specific warp on a level.
#
class Warp
  # Contains an array of the destination coordinates on the target level
  attr_reader :dest
  # Contains a string of the destination level's name
  attr_reader :level
  
  #
  # Sets the warp's destination coordinates and target level
  #
  def initialize(dest, level)
    @dest = dest
    @level = level
  end
end


#
# The ScrollingCombatText class is responsible for handling all the combat messages.
#
class ScrollingCombatText
  #
  # Sets the font, and font_scale
  #
  def initialize(font, font_scale)
    @font = font
    @font_scale = font_scale
    @queue = []
    @message_queue = []
  end
  
  #
  # Adds a number to the message queue FIXME: Delete this, just add a tick and speed option to the message one
  #
  def add_number(number, x, y, rgb)
    #Syntax: [number, x, y, tick, alpha, rgb]
    @queue << [number, x, y, 25, 255, rgb]
  end
  
  #
  # Adds a message to the message queue
  #
  def add_message(message, x, y, rgb)
    @message_queue << [message, x, y, 60, 255, rgb]
  end
  
  #
  # Updates all the message's tick, and moves them up
  #
  def update()
    @queue.each_index do |i|
      if @queue[i][3] > 0 then
        @queue[i][3] -= 1 # tick
        @queue[i][2] -= 1.5 # move up
        @queue[i][4] = ((@queue[i][3].to_f * 255.0) / 25.0).to_i
      else
        @queue[i] = nil
      end
    end
    @queue.compact!
    
    @message_queue.each_index do |i|
      if @message_queue[i][3] > 0 then
        @message_queue[i][3] -= 1 # tick
        @message_queue[i][2] -= 0.75 # move up
        @message_queue[i][4] = ((@message_queue[i][3].to_f * 255.0) / 60.0).to_i
      else
        @message_queue[i] = nil
      end
    end
    @message_queue.compact!
  end
  
  #
  # Draws the messages
  #
  def draw(window)
    @queue.each do |item|
      # Draw number
      color = Gosu::Color.rgba(item[5][0],item[5][1],item[5][2],item[4])
      @font.draw(item[0], item[1], item[2], 3, 1 / @font_scale, 1 / @font_scale, color)
    end
    @message_queue.each do |item|
      # Draw message
      color = Gosu::Color.rgba(item[5][0],item[5][1],item[5][2],item[4])
      @font.draw(item[0], item[1], item[2], 3, 1 / @font_scale, 1 / @font_scale, color)
    end
  end
end


#
# The Tombstone class contains information about the object that is created when something dies.
#
class Tombstone
  # the x position of the tombstone
  attr_reader :x
  # the y position of the tombstone
  attr_reader :y
  #
  # Sets the position, and image
  #
  def initialize(map, type, x, y)
    @x = x
    @y = y
    if type == 'enemy' then
      @image = map.enemy_image_hash['enemy_tombstone.png']
    elsif type == 'player' then
      @image = map.hero_death
    end
    @color = Gosu::Color.rgba(0, 0, 0, 255)
  end
  
  #
  # Changes the @color variable to the color of the tile beneath the tombstone
  #
  def change_lighting(tile)
    @color = tile.color
  end
  
  #
  # Draws the object
  #
  def draw()
    @image.draw(@x, @y, 0.4, 1, 1, @color)
  end
end


#
# The FadeLoad class controls the fading that happens when the player passes a warp.
#
class FadeLoad
  # Contains a string that holds the level's name
  attr_accessor :level
  # Contains an array of destination coordinates
  attr_accessor :coords
  
  #
  # Saves a reference to the window, and sets various instance variables
  #
  def initialize(window)
    @window = window
    @level = ''
    @coords = []
    @type = 'open'
    @width = 0
    @height = 0
    @color = Gosu::Color.rgba(0, 0, 0, 255)
    @flash_alpha = 0
  end
  
  #
  # Closes the fade bars (dark close)
  #
  def close()
    @type = 'closed'
  end
  
  #
  # Opens the fade bars (dark open)
  #
  def open()
    @type = 'open'
  end
  
  #
  # Returns true if either of the types of bars are closed or closing
  #
  def is_closed?()
    @type == 'closed' or @type == 'flash_closed'
  end
  
  #
  # Quickly closes the fade bars (white close)
  #
  def flash_close()
    @type = 'flash_close'
  end
  
  #
  # Quickly opens the fade bars (white open)
  #
  def flash_open()
    @type = 'flash_open'
  end
  
  #
  # Updates the fade bars positions if need be
  #
  def update(map, window)
    if @type == 'closed' then
      @width = smoother(@width, 321, 4)
      @height = smoother(@height, 241, 3)
      if @width == 321 and @height == 241 then
        SaveManager.save_door_positions(map.door_array)
        map.load_level(@level, window)
        map.player.x = (@coords[0] * 32) + 16
        map.player.y = (@coords[1] * 32) + 16
        map.player.current_cell.replace(@coords)
        map.update_view_window_coords()
        SaveManager.update_player_database(map)
        open()
      end
    elsif @type == 'open' then
      @width = smoother(@width, 0, 4)
      @height = smoother(@height, 0, 3)
    elsif @type == 'flash_close' then
      if @flash_alpha != 255 then
        @flash_alpha = smoother(@flash_alpha, 255, 25)
      else
        map.player.x = (@coords[0] * 32) + 16
        map.player.y = (@coords[1] * 32) + 16
        map.player.current_cell.replace(@coords)
        map.update_view_window_coords()
        flash_open()
      end
    elsif @type == 'flash_open' then
      if @flash_alpha != 0 then
        @flash_alpha = smoother(@flash_alpha, 0, 25)
      else
        open()
      end
    end
  end
  
  #
  # Draws the fade bars
  #
  def draw()
    if @type == 'flash_close' or @type == 'flash_open' then
      #Blink close rect
      @window.draw_quad(0, 0, Gosu::Color.rgba(255,255,255,@flash_alpha), 640, 0, Gosu::Color.rgba(255,255,255,@flash_alpha), 0, 480, Gosu::Color.rgba(255,255,255,@flash_alpha), 640, 480, Gosu::Color.rgba(255,255,255,@flash_alpha), 10, :default)
    end
    #Top rect
    @window.draw_quad( 0, 0, @color, 640, 0, @color, 0, 0 + @height, @color, 640, 0 + @height, @color, 10, :default )
    #Bottom rect
    @window.draw_quad( 0, 480 - @height, @color, 640, 480 - @height, @color, 0, 480, @color, 640, 480, @color, 10, :default )
    #Left rect
    @window.draw_quad( 0, 0, @color, 0 + @width, 0, @color, 0, 480, @color, 0 + @width, 480, @color, 10, :default )
    #Right rect
    @window.draw_quad( 640 - @width, 0, @color, 640, 0, @color, 640 - @width, 480, @color, 640, 480, @color, 10, :default )
  end
end


#
# The Map class contains the map that the game is played on, and many methods to deal with that map.
#
class Map
  # a 3d array of Tiles, this array is drawn to form the level which is played on
  attr_accessor :map_array
  # a 2d array of Warps, this array is read from to allow level transfer to take place
  attr_accessor :warp_array
  # an instance of the Player class
  attr_accessor :player
  # the coordinates of the window from which the player views the map -- used for drawing the map
  attr_accessor :view_window_coords
  # an array of lights which produce light during the night
  attr_accessor :light_array
  # an array of Enemys, this array contains all enemies in the currently loaded level
  attr_accessor :enemy_array
  # an array of Items, this array contains all current items on the map
  attr_accessor :item_array
  # an instance of the Gui class
  attr_accessor :gui
  # an instance of the ScrollingCombatText class
  attr_accessor :scrolling_combat_text
  # an array of Doors, this array contains all doors currently loaded on the map
  attr_accessor :door_array
  # the scale that is applied to fonts to make them seem more crisp
  attr_reader :font_scale
  # an instance of a font which is generally small
  attr_reader :small_8bit_font
  # an array of the item images
  attr_reader :item_image_array
  # a string that contains the name of the currently loaded level
  attr_reader :current_level
  # boolean value which is true is underground, false if above ground
  attr_reader :underground
  # an instance of the FadeLoad class
  attr_reader :fadeload
  # an instance of the image displayed when an enemy dies
  attr_reader :enemy_death
  # an instance of the image displayed when the hero dies
  attr_reader :hero_death
  # an array of Npcs, this array contains all npcs currently loaded on the map
  attr_reader :npc_array
  # a hash containing all of the loaded enemy images
  attr_reader :enemy_image_hash
  
  #
  # Sets various variables related to the Map class
  #
  def initialize(window)
    @window = window
    @map_array = create_3d_array( $MAPSIZE, $MAPSIZE, 3 )
    @warp_array = create_2d_array( $MAPSIZE, $MAPSIZE )
    @preloaded_tilesets = []
    @tileset_array = grab_tilesets('../mainfiles/media/tilesets')
    @player = nil
    @gui = nil
    @view_window_coords = [0,0]
    @fadeload = FadeLoad.new(@window)
    @light_array = []
    @enemy_array = []
    @npc_array = []
    @tombstone_array = []
    @item_array = []
    @door_array = []
    @font_scale = 2.0
    @small_8bit_font = Gosu::Font.new(@window, '../mainfiles/fonts/8bit.ttf', (10 * @font_scale).to_i)
    @message_box_font = Gosu::Font.new(@window, '../mainfiles/fonts/8bit.ttf', 8)
    @item_image_array = Gosu::Image::load_tiles(@window, '../mainfiles/media/items/tileset_items.png', 16, 16, false)
    @door_image = Gosu::Image.new(@window, '../mainfiles/media/objects/door.png', true)
    @enemy_image_hash = load_enemy_images()
    @hero_death = Gosu::Image.new(@window, '../mainfiles/media/characters/hero_tombstone.png', false)
    @npc_image_hash = load_npc_images()
    @scrolling_combat_text = ScrollingCombatText.new(@small_8bit_font, @font_scale)
    @current_level = nil
    @underground = nil
    @scripted_event = Scripted_Event.new()
    @lighting_controller = Lighting.new()
    @preloaded_colors = @lighting_controller.get_preloaded_colors()
    @day_length = 2.5 * 3600 # First number is the number of mins
    @current_day_tick = 0
    @day_tick_addition = 1
    @time = 'day'
    @day_rgb = 255
    $log.debug('Map initialized successfully.')
  end
  
  #
  # Turns on the credits screen
  #
  def credits()
    clear_map_data()
    @window.start_menu.credits_screen()
    @credits = Gosu::Song.new(@window, '../mainfiles/media/music/credits.ogg')
    @credits.play(false)
    @credits.volume = 0.2
  end
  
  #
  # Updates the line of sight of all enemies loaded
  #
  def update_los()
    @enemy_array.each do |enemy|
      enemy.update_los(@player, @map_array[1], @door_array)
    end
  end
  
  #
  # Adds an item to @item_array
  #
  def add_item(type, x, y, cell, enemy_level, color=Gosu::Color.rgba(255,255,255,255))
    @item_array << Item.new(@window, type, x, y, cell, enemy_level, @item_image_array, color)
  end
  
  #
  # Adds a tombstone to @tombstone_array
  #
  def add_tombstone(type, x, y)
    @tombstone_array << Tombstone.new(self, type, x, y)
  end
  
  #
  # Loads all the enemy images, and stores them by filename in a hash
  #
  def load_enemy_images()
    array = search_directory('../mainfiles/media/enemies', '*')
    result = {}
    array.each do |path|
      image = Gosu::Image::load_tiles(@window, path, 32, 32, false)
      image = Gosu::Image.new(@window, path, false) if image.empty?
      result[path.split('/enemies/')[1]] = image
    end
    return result
  end
  
  #
  # Loads all the npc images, and stores them by filename in a hash
  #
  def load_npc_images()
    array = search_directory('../mainfiles/media/characters/npc', '*')
    result = {}
    array.each do |path|
      result[path.split('/npc/')[1]] = Gosu::Image.new(@window, path, false)
    end
    return result
  end
  
  #
  # Starts a new game on profile: profile_name
  #
  def new_game(profile_name)
    SaveManager.new_game(profile_name)
    load_level( $player_db.execute("Select current_map From stats")[0][0], @window )
    @player = Player.new(@window, self)
    x = $player_db.execute("Select x From stats")[0][0]
    y = $player_db.execute("Select y From stats")[0][0]
    @player.current_cell = [(x/32).round, (y/32).round] # players starting coords
    @player.x = x+16
    @player.y = y+16
    @gui = Gui.new(@window, @player)
    @player.gui = @gui
    update_view_window_coords()
  end
  
  #
  # Continue a save game on profile: profile_name
  #
  def continue_game(profile_name)
    SaveManager.continue_game(profile_name)
    load_level( $player_db.execute("Select current_map From stats")[0][0], @window )
    @player = Player.new(@window, self)
    x = $player_db.execute("Select x From stats")[0][0]
    y = $player_db.execute("Select y From stats")[0][0]
    @player.current_cell = [(x/32).round, (y/32).round] # players starting coords
    @player.x = x+16
    @player.y = y+16
    @gui = Gui.new(@window, @player)
    @player.gui = @gui
    @player.enemy_slain($player_db.execute("Select current_player_xp From stats")[0][0], false)
    @player.sword_xp += $player_db.execute("Select current_sword_xp From stats")[0][0]
    @player.update_stats(false)
    if @player.player_level >= 50 and @player.sword_level >= 50 then
      @player.go_crazy()
    end
    @player.hp = $player_db.execute("Select current_health From stats")[0][0]
    @player.gui.update()
    update_view_window_coords()
  end
  
  #
  # Clears all map data
  #
  def clear_map_data()
    @map_array = create_3d_array( $MAPSIZE, $MAPSIZE, 3 )
    @warp_array = create_2d_array( $MAPSIZE, $MAPSIZE )
    @player = nil
    @gui = nil
    @current_level = nil
    @light_array = []
    @enemy_array = []
    @tombstone_array = []
    @item_array = []
    @door_array = []
    @npc_array = []
    Databases.unload()
  end
  
  #
  # Nils out the player
  #
  def player_death()
    @player = nil
  end
  
  #
  # Recalculates the lighting on a certain tile
  #
  def recalculate_lighting(tile)
    tile.start_light_block()
    tile.updatelight( 'dynamic', 200, @day_rgb, @player.x - 16, @player.y - 16 ) if @player != nil
    tile.updatecolor(@day_rgb ,@preloaded_colors)
  end
  
  #
  # Updates various map objects and variables
  #
  def update(menu)
    # Day / Night code ---
    @current_day_tick += @day_tick_addition
    if @current_day_tick > @day_length then
      @day_tick_addition = -1
      @time = 'night'
    elsif @current_day_tick < 0 then
      @day_tick_addition = 1
      @time = 'day'
    end
    
    if @underground == true then
      @day_rgb = 30
    else
      if @time == 'day' then #RGB value calculation
        #225 until 600 ticks of night, then down to 30
        if @current_day_tick < (@day_length - 600) then
          @day_rgb = 225
        else
          @day_rgb = 225 - ((195 * (@current_day_tick - (@day_length - 600))) / 600)
        end
      elsif @time == 'night' then
        #30 until 600 ticks of day, then up to 225
        if @current_day_tick > 600 then
          @day_rgb = 30
        else
          @day_rgb = 225 - ((195 * @current_day_tick) / 600)
        end
      end
      @day_rgb = @day_rgb.round
    end
    @tombstone_array.each do |tomb|
      tomb.change_lighting(@map_array[0][(tomb.y/32).round][(tomb.x/32).round])
    end
    @door_array.each do |door|
      door.change_lighting(@map_array[0][(door.y/32).round][(door.x/32).round])
    end 
    @npc_array.each do |npc|
      npc.update(self)
      npc.change_lighting(@map_array[0][(npc.y/32).round][(npc.x/32).round])
    end
    @enemy_array.each do |enemy|
      enemy.update(self, menu)
      enemy.change_lighting(@map_array[0][(enemy.y/32).round][(enemy.x/32).round])
    end
    # ---
    if @player != nil
      @player.update()
      @scripted_event.check(self)
    end
    @scrolling_combat_text.update()
    @fadeload.update(self, @window)
  end
  
  #
  # Checks if there is a warp at the x, y cell coordinates, if so, it warps.
  #
  def warp(x, y)
    if @warp_array[y][x].class == Warp then
      # Turn off input (except escape)?
      @fadeload.level = String.new(@warp_array[y][x].level)
      @fadeload.coords.replace(@warp_array[y][x].dest)
      if @fadeload.level == @current_level then
        @fadeload.flash_close()
      else
        @fadeload.close()
      end
      # Turn on input?
    end
  end
  
  #
  # Updates the coordinates of the viewing rectangle (Used in drawing the map)
  #
  def update_view_window_coords()
    # Width
    if @player.current_cell[0] - 10.5 <= 0 then # left
      @view_window_coords[0] = 0
    elsif @player.current_cell[0] - 10.5 >= 44 then# right
      @view_window_coords[0] = 44
    else # between
      @view_window_coords[0] = @player.current_cell[0] - 11
    end
    # Height
    if @player.current_cell[1] - 9 <= 0 then # top
      @view_window_coords[1] = 0
    elsif @player.current_cell[1] - 9 >= 45 then # bottom
      @view_window_coords[1] = 45
    else # between
      @view_window_coords[1] = @player.current_cell[1] - 9
    end
  end
  
  #
  # Returns all the tilesets in a defined folder
  #
  def grab_tilesets(folder)
    array = search_directory(folder, 'tileset_*')
    result = [[],[],[],[]]
    array.each do |e|
      a = e.split('tileset_')[1]
      type = a.split('_')[0]
      set = a.split('_')[1].split('.png')[0]
      filename = "/tileset_#{type}_#{set}.png"
      index = @preloaded_tilesets.count
      tileset = Gosu::Image.load_tiles(@window, folder + filename, 32, 32, true)
      @preloaded_tilesets[index] = tileset
      if type == 'floor' then
        result[0] << "#{set}////#{index}"
      elsif type == 'wall' then
        result[1] << "#{set}////#{index}"
      elsif type == 'light' then
        result[1] << "#{set}////#{index}"
      end
    end
    return result
  end
  
  #
  # Loads the level: filename
  #
  def load_level( filename, window )
    return nil if filename == ''
    if File.exists?("../core_files/levels/#{filename}/level_converted.dat") then
      @warp_array = create_2d_array( $MAPSIZE, $MAPSIZE )
      @light_array = []
      @enemy_array = []
      @npc_array = []
      @tombstone_array = []
      @item_array = []
      @door_array = []
      @current_level = filename
      if filename.start_with?('dungeon_') then
        @underground = true
      else
        @underground = false
      end
      warps_array = $db.execute("Select * From warps Where source_map = '#{filename}'")
      warps_array.each do |warp|
        source = [warp[2].split(',')[0].to_i, warp[2].split(',')[1].to_i]
        dest = [warp[3].split(',')[0].to_i, warp[3].split(',')[1].to_i]
        @warp_array[ source[1] ][ source[0] ] = Warp.new(dest, warp[1])
      end
      @map_array = create_3d_array( $MAPSIZE, $MAPSIZE, 2 ) # Blank Screen
      read_file = marshalfileread("../core_files/levels/#{filename}/level_converted.dat")
      2.times do |z|
        $MAPSIZE.times do |y|
          $MAPSIZE.times do |x|
            if read_file[z][y][x].is_a?(Array) then
              info_array = read_file[z][y][x]
              name = info_array[0]
              type = info_array[1]
              tile_number = (info_array[2]).to_i
              if type == 'floor' then
                index = 0
              elsif type == 'wall' then
                index = 1
              elsif type == 'light' then
                index = 1
                @light_array << [(x * 32),(y * 32)]
              end
              tileset_name_and_number = ((@tileset_array[index]).grep %r{^#{name}} )[0]
              if tileset_name_and_number != nil then
                tile_sheet_index = (tileset_name_and_number.split('////')[1]).to_i
                tileset = @preloaded_tilesets[tile_sheet_index]
                tile = Tile.new(tileset[tile_number])
                tile.x = (x * 32)
                tile.y = (y * 32)
                tile.z = index
                tile.name = name
                tile.type = type
                tile.tile_number = tile_number
                @map_array[z][y][x] = tile
              end
            end
          end
        end
      end
      
      if @light_array.count > 0 then
        @light_array.each do |light|
          2.times do |z|
            @map_array[z].each_index do |y|
              @map_array[z][y].each_index do |x|
                if @map_array[z][y][x].class == Tile then
                  @map_array[z][y][x].updatelight( 'static', 160, 255, light[0], light[1])
                end
              end
            end
          end
        end
      end
      # Load NPCs from database
      npc_array = Databases::NPC.get_npcs_from_map(filename)
      npc_array.each do |npc|
        # [key, "config", x, y, "map", angle]
        config = YAML::load( File.open("../core_files/npc_scripts/#{npc[1]}.yml", 'r') )
        config['id'] = npc[0]
        config['x'] = npc[2]
        config['y'] = npc[3]
        config['angle'] = npc[5]
        config['picture'] = @npc_image_hash[config['picture']]
        config['config_file'] = npc[1]
        @npc_array << NPC.new(@window, @message_box_font, config)
      end
      # Load enemies from database
      enemy_array = Databases::Enemy.get_enemies_from_map(filename)
      enemy_array.each do |enemy|
        @enemy_array << Enemy.new(@window, enemy[1], (enemy[3]/32), (enemy[4]/32), self, @enemy_image_hash)
      end
      # Load doors from database
      door_array = Databases::Door.get_doors_from_map(filename)
      door_array.each do |door|
        @door_array << Door.new(door[0], @door_image, door[2]/32, door[3]/32, door[1]) #(door_image, cell_x, cell_y, state)
      end
      $log.info("Level #{filename} loaded.")
    end
  end
  
  #
  # Draws certain elements without translating them around
  #
  def draw_no_translate()
    @fadeload.draw()
    @gui.draw() if @gui != nil
  end
  
  #
  # Draws all the major map items (with translation)
  #
  def draw()
    @player.draw(@window) if @player != nil
    @scrolling_combat_text.draw(@window)
    @enemy_array.each do |enemy|
      enemy.draw(@window)
    end
    @npc_array.each do |npc|
      npc.draw()
    end
    @tombstone_array.each do |tombstone|
      tombstone.draw()
    end
    @item_array.each do |item|
      item.draw()
    end
    @door_array.each do |door|
      door.draw()
    end
    2.times do |z| # Only draw (what is visible + enough for smooth screen movement)
      19.times do |y|
        24.times do |x|
          if @map_array[z][y+@view_window_coords[1]][x+@view_window_coords[0]] != ' ' and @map_array[z][y+@view_window_coords[1]][x+@view_window_coords[0]] != "\n" and @map_array[z][y+@view_window_coords[1]][x+@view_window_coords[0]] != nil then
            recalculate_lighting(@map_array[z][y+@view_window_coords[1]][x+@view_window_coords[0]])
            if z == 2 then
              @map_array[z][y+@view_window_coords[1]][x+@view_window_coords[0]].draw(0)
            else
              @map_array[z][y+@view_window_coords[1]][x+@view_window_coords[0]].draw(1)
            end
          end
        end
      end
    end
  end
end
