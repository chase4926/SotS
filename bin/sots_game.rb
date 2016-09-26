#!/usr/bin/env ruby
=begin
TODO List Here / Notes
----------------------
  =Fix all FIXME's
=end
Dir.chdir(File.dirname(__FILE__)) # Makes the script work correctly even if
                                  # the directory it was launched from isn't
                                  # /bin
$VERSION = '1.1'
if !(ARGV.empty?) and ARGV[0] == '-v' then
  $VERBOSE = true
else
  $VERBOSE = false
end

# Require all the other source code ---
require_relative 'lib/lib.rb'
require_relative 'lib/lib_misc.rb'
require_relative 'lib/lib_lighting.rb'
require_relative 'db_module.rb'
require_relative 'save_module.rb'
require_relative 'menu.rb'
require_relative 'map.rb'
require_relative 'gui.rb'
require_relative 'email.rb'
# ---

# Dependency loading ---
non_verbosely do
  # Do this non verbosely because if there are problems with someone
  # else's library, those aren't for me to deal with.
  require 'rubygems'
  require 'fileutils'
  require 'logger'
  $log = Logger.new('../logfile.log')
  $log.level = Logger::INFO
  $log.info('Program Started')
  begin
    require_relative '../vendor/bundle/bundler/setup'
  rescue => error
    $log.fatal("Couldn't load bundled gems!")
    $log.fatal(error)
  end
  include Gosu
end
# ---

$log.debug('Required all files successfully')

#
# Reads a file containing marshal serialized content
#
def marshalfileread(file)
  if ! File.exists?(file) then
    $log.warn("Marshal file doesn't exist: #{file.inspect}")
    vputs 'That file doesn\'t exist: '  + file.inspect
    return ''
  end
  begin
    return Marshal::load( File.open(file, 'r') )
  rescue
    $log.warn("Error reading marshal file: #{file.inspect}")
    vputs "Error reading file: #{file.inspect}"
    return ''
  end
end

#
# Read the properties file & set global variables
#
if File.exists?('../saves/properties.dat') then
  data = marshalfileread('../saves/properties.dat')
  if data.class == Array then
    $WINDOW_WIDTH = data[0]
    $WINDOW_HEIGHT = data[1]
    $SOUND = data[2] # 0 = None, 1 = Just Sound, 2 = Music & Sound
  else
    $log.warn('Properties file is damaged, replacing it and using default settings.')
    vputs 'Don\'t modify the properties file!'
    properties_data = Marshal::dump([640, 480, 2])
    create_file('../saves/properties.dat', properties_data)
    $WINDOW_WIDTH = 640
    $WINDOW_HEIGHT = 480
    $SOUND = 2
  end
else
  $log.warn('Properties file does not exist, creating it and using default settings.')
  properties_data = Marshal::dump([640, 480, 2])
  create_file('../saves/properties.dat', properties_data)
  $WINDOW_WIDTH = 640
  $WINDOW_HEIGHT = 480
  $SOUND = 2
end
$WIDTH_SCALE = $WINDOW_WIDTH/640.0
$HEIGHT_SCALE = $WINDOW_HEIGHT/480.0
$MAPSIZE = 64
$SCROLL_X = $SCROLL_Y = 0


#
# The GameWindow class contains the main game loop and all relevant code.
#
class GameWindow < Gosu::Window
  # true or false, controls pausing of game's update cycle
  attr_accessor :paused
  # contains an instance of the StartMenu object
  attr_reader :start_menu
  
  #
  # Creates instances of all major game objects and stores them in instance variables
  #
  def initialize()
    begin
      Gosu::enable_undocumented_retrofication() # ...surprisingly this method disables all bilinear filtering
      vputs 'Bilinear filtering is off.'
    rescue
      $log.warn('Bilinear filtering failed to turn off.')
      vputs 'Bilinear filtering is on'
    end
    super($WINDOW_WIDTH, $WINDOW_HEIGHT, false) # Windowed
    #super($WINDOW_WIDTH, $WINDOW_HEIGHT, true) # Fullscreen
    self.caption = 'Wayback Project'
    @start_menu = StartMenu.new(self)
    @map = Map.new(self)
    @bg_music = Gosu::Song.new(self, "../mainfiles/media/music/music#{[1,2,3].shuffle[0]}.ogg")
    @bg_music.play(true) if $SOUND == 2
    @bg_music.volume = 0.2
    @paused = false
    $log.debug('Window initialized successfully.')
  end # End GameWindow Initialize
  
  #
  # Called 60 times a second auto-magically by Gosu::Window.show, updates everything that needs updating
  #
  def update()
    return nil if @paused
    @start_menu.update() if @start_menu.visible
    @map.update(@start_menu)
    if @map.player != nil then
      @map.player.block(button_down?(Gosu::Button::KbR))
      # Movement code ---
      if button_down? Gosu::Button::KbLeft or button_down? Gosu::Button::KbA then
        @map.player.move(:left) if not button_down? Gosu::Button::KbRight and not button_down? Gosu::Button::KbD
      end
      if button_down? Gosu::Button::KbRight or button_down? Gosu::Button::KbD then
        @map.player.move(:right) if not button_down? Gosu::Button::KbLeft and not button_down? Gosu::Button::KbA
      end
      if button_down? Gosu::Button::KbUp or button_down? Gosu::Button::KbW then
        @map.player.move(:up) if not button_down? Gosu::Button::KbDown and not button_down? Gosu::Button::KbS
      end
      if button_down? Gosu::Button::KbDown or button_down? Gosu::Button::KbS then
        @map.player.move(:down) if not button_down? Gosu::Button::KbUp and not button_down? Gosu::Button::KbW
      end
      if button_down? Gosu::Button::KbLeftShift or button_down? Gosu::Button::KbRightShift then # Sprinting code
        @map.player.speed = 3
      else
        @map.player.speed = 1.5
      end
      # ---
      # Scrolling code ---
      if (@map.player.x - 320) <= 0 then
        $SCROLL_X = 320
      elsif (@map.player.x + 320) >= ($MAPSIZE * 32) then
        $SCROLL_X = ($MAPSIZE * 32) - 320
      elsif not (@map.player.x + 320) >= ($MAPSIZE * 32) and not (@map.player.x - 320) <= 0 then
        $SCROLL_X = @map.player.x
      end
      if (@map.player.y - 240) <= 0 then
        $SCROLL_Y = 240
      elsif (@map.player.y + 240) >= ($MAPSIZE * 32) then
        $SCROLL_Y = ($MAPSIZE * 32) - 240
      elsif not (@map.player.y + 240) >= ($MAPSIZE * 32) and not (@map.player.y - 240) <= 0 then
        $SCROLL_Y = @map.player.y
      end
      # ---
    end
  end # End GameWindow Update
  
  #
  # Draw certain elements to the window
  #
  def draw()
    scale($WIDTH_SCALE, $HEIGHT_SCALE) do
      clip_to(0, 0, 640, 480) do
        @start_menu.draw(self) if @start_menu.visible
        translate(($SCROLL_X * -1).to_i + 320, ($SCROLL_Y * -1).to_i + 240) do
          @map.draw() # Only draw (what is visible + enough for smooth screen movement)
        end
        @map.draw_no_translate()
      end
    end
  end # End GameWindow Draw
  
  #
  # Called auto-magically whenever a button is pressed, and is passed the id of that button
  #
  def button_down(id)
    if @start_menu.visible then
      @start_menu.button_pressed(id, self, @map)
      if @paused and id == Gosu::Button::KbEscape then # Escape closes the pause menu
        @start_menu.toggle_pause()
        @paused = false
      end
    elsif not @paused then
      if @map.player != nil then
        if id == Gosu::Button::KbF then
          @map.player.attack()
        elsif id == Gosu::Button::KbE then
          @map.player.interact()
        elsif id == Gosu::Button::KbC then
          @map.player.level_up(:player, 1)
          @map.player.level_up(:sword, 1)
        end
      end
      if id == Gosu::Button::KbEscape # Escape brings up the pause menu
        @start_menu.toggle_pause()
        @paused = true
      end
    end
  end
end # End GameWindow class


#
# The Player class contains all methods and variables relevant to the player.
#
class Player
  # the player's x coordinate
  attr_accessor :x
  # the player's y coordinate
  attr_accessor :y
  # an array of the player's map cell coordinates
  attr_accessor :current_cell
  # the player's movement speed
  attr_accessor :speed
  # a reference to the gui object so the player can update the gui
  attr_accessor :gui
  # the player's current experience
  attr_accessor :player_xp
  # the player's sword's current experience
  attr_accessor :sword_xp
  # the player's current hit points
  attr_accessor :hp
  # the player's maximum hit points
  attr_accessor :max_hp
  # the player's current level
  attr_reader :player_level
  # the player's sword's current level
  attr_reader :sword_level
  # an array containing the minimum and maximum damage that the player can do
  attr_reader :damage_range
  # the player's maximum amount of experience before the next player level
  attr_reader :player_max_xp
  # the player's maximum amount of experience before the next sword level
  attr_reader :sword_max_xp
  
  #
  # Loads images related to the player, and initializes many essential variables
  #
  def initialize(window, map)
    @map = map
    @animation = Gosu::Image::load_tiles(window, '../mainfiles/media/characters/warrior.png', 32, 32, false)
    @attack_animation = Gosu::Image::load_tiles(window, '../mainfiles/media/characters/warrior_attack.png', 32, 32, false)
    @block_image = Gosu::Image.new(window, '../mainfiles/media/characters/warrior_block.png', false)
    @crazy_animation = Gosu::Image::load_tiles(window, '../mainfiles/media/characters/crazy_warrior.png', 32, 32, false)
    @crazy_attack_animation = Gosu::Image::load_tiles(window, '../mainfiles/media/characters/crazy_warrior_attack.png', 32, 32, false)
    @crazy_block_image = Gosu::Image.new(window, '../mainfiles/media/characters/crazy_warrior_block.png', false)
    @crazy = false
    @x = @y = @angle = @desired_angle = 0
    # Player Stats --- 
    @player_level = 1
    @sword_level = 1
    @player_xp = 0
    @player_max_xp = 50
    @sword_xp = 0
    @sword_max_xp = 15
    @max_hp = 80
    @hp = @max_hp
    # ---
    @attack_speed = 15 # in frames
    @attack_tick = @attack_speed
    @speed = 1.5
    @damage_range = [2,7]
    # ---
    @gui = nil
    @current_cell = [0,0]
    @color = 255
    @moving = false
    @attacking = false
    @blocking = false
  end
  
  #
  # Sets @crazy to true
  #
  def go_crazy()
    @crazy = true
  end
  
  #
  # Sets @blocking to a given boolean operator :setter
  #
  def block(bool)
    @blocking = bool
  end
  
  #
  # Returns the angle of the given cell relative to the player's current location
  #
  def angle_from_relative_cell(cell)
    diff_x = @current_cell[0] - cell[0]
    diff_y = @current_cell[1] - cell[1]
    if diff_x == 1 then
      return 270
    elsif diff_x == -1 then
      return 90
    elsif diff_y == 1 then
      return 0
    elsif diff_y == -1 then
      return 180
    else
      return 0
    end
  end
  
  #
  # Damages the player by a certain amount with a source of cell
  #
  def damage(amount, menu, cell) # cell indicates the cell the damage came from
    return nil if @map.fadeload.is_closed?()
    if (@blocking and angle_from_relative_cell(cell) == @desired_angle) or (random(1,6) == 1) then
      amount = (amount * 0.1).round
      @map.scrolling_combat_text.add_number(amount, random((@x - 4).round, (@x + 4).round), random((@y - 4).round, (@y + 4).round), [200,100,100])
    else
      @map.scrolling_combat_text.add_number(amount, random((@x - 4).round, (@x + 4).round), random((@y - 4).round, (@y + 4).round), [255,0,0])
    end
    if amount > @hp then
      @hp = 0
    else
      @hp -= amount
    end
    @gui.update()
    if @hp == 0 then
      # Player is dead
      menu.game_over_screen()
      @map.add_tombstone('player', (@current_cell[0] * 32)+random(1,8), (@current_cell[1] * 32)+random(1,8))
      @map.player_death()
    end
  end
  
  #
  # Interacts with whatever the player is facing
  #
  def interact()
    if @current_cell[0] * 32 == @x - 16 and @current_cell[1] * 32 == @y - 16 and @attacking == false and @blocking == false then
      x_diff = y_diff = 0
      case @desired_angle
        when 0
          y_diff = -1
        when 90
          x_diff = 1
        when 180
          y_diff = 1
        when 270
          x_diff = -1
        when 360
          y_diff = -1
      end
      possible_door = get_barrier_at_pos(@map.door_array, @current_cell[0] + x_diff, @current_cell[1] + y_diff)
      if possible_door.class == Door then
        possible_door.toggle()
      end
    end
  end
  
  #
  # Levels the player up instantly, non-dependant of how much experience the player currently has
  #
  def level_up(type, amount)
    if type == :player then
      xp_needed = fib(50, @player_level+(amount-1)) - @player_xp
      enemy_slain(xp_needed, false)
      update_stats(false)
    elsif type == :sword then
      xp_needed = fib(15, @sword_level+(amount-1)) - @sword_xp
      @sword_xp += xp_needed
      update_stats(false)
    end
  end
  
  #
  # Heals the player by a certain amount
  #
  def heal(amount)
    if @hp + amount > @max_hp then
      @hp = @max_hp
    else
      @hp += amount
    end
    @gui.update()
  end
  
  #
  # Returns the barrier (if any) that exists in a certain cell
  #
  def get_barrier_at_pos(barrier_array, cell_x, cell_y)
    barrier_array.each do |barrier|
      return barrier if barrier.current_cell == [cell_x, cell_y]
    end
    return nil
  end
  
  #
  # Attempts to pick up an item that the player may be standing on
  #
  def pick_up_item()
    @map.item_array.each do |item|
      if item.cell == @current_cell then
        if item.type == 'healing_potion' then
          heal(item.health)
        end
        @map.item_array[@map.item_array.index(item)] = nil
      end
    end
    @map.item_array.compact!
  end
  
  #
  # Attacks the enemy in the direction he is facing
  #
  def attack()
    if @current_cell[0] * 32 == @x - 16 and @current_cell[1] * 32 == @y - 16 and @attacking == false and @blocking == false then
      # If the player is not moving, and not blocking or already attacking, then attack
      @attacking = true
      x_diff = 0
      y_diff = 0
      case @desired_angle
        when 360
          y_diff = -1
        when 0
          y_diff = -1
        when 90
          x_diff = 1
        when 180
          y_diff = 1
        when 270
          x_diff = -1
      end
      enemy = get_barrier_at_pos(@map.enemy_array, @current_cell[0] + x_diff, @current_cell[1] + y_diff)
      if enemy != nil then
        damage_done = random(@damage_range[0], @damage_range[1])
        enemy.damage(damage_done, @map)
        @sword_xp += enemy.weapon_exp_value
        update_stats()
      end
    end
  end
  
  #
  # Adds the needed experience from an enemy's death, and trys to level the player up
  #
  def enemy_slain(exp_value, message=true)
    @player_xp += exp_value
    while @player_xp >= @player_max_xp
      @player_level += 1
      @player_max_xp = fib(50, @player_level)
      if message then
        @map.scrolling_combat_text.add_message('Level up!', random((@x - 48).round, (@x - 44).round), random((@y - 4).round, (@y + 4).round), [0,0,255])
      end
      @max_hp += 20
      @hp = @max_hp
      update_stats(message)
    end
  end
  
  #
  # Updates the stats and levels up the player if he has enough experience
  #
  def update_stats(message=true)
    while @sword_xp >= @sword_max_xp
      @sword_level += 1
      @sword_max_xp = fib(15, @sword_level)
      if message then
        @map.scrolling_combat_text.add_message('Sword +1', random((@x - 48).round, (@x - 44).round), random((@y - 4).round, (@y + 4).round), [0,255,255])
      end
    end
    @damage_range = [(((@sword_level-1)* 4) + 2), (((@sword_level-1)* 4) + 7)]
    @gui.update()
  end
  
  #
  # Draws the enemy's health bar
  #
  def draw_enemy_health_bar(window)
    if @current_cell[0] * 32 == @x - 16 and @current_cell[1] * 32 == @y - 16 then
      x_diff = y_diff = 0
      case @desired_angle
        when 0
          y_diff = -1
        when 90
          x_diff = 1
        when 180
          y_diff = 1
        when 270
          x_diff = -1
        when 360
          y_diff = -1
      end
      enemy = get_barrier_at_pos(@map.enemy_array, @current_cell[0] + x_diff, @current_cell[1] + y_diff)
      if enemy != nil and enemy.hp > 0 then
        proportion = (enemy.hp.to_f / enemy.max_hp.to_f)
        if proportion > 0.75 then
          current_color = 0
        elsif proportion > 0.5 then
          current_color = 1
        elsif proportion > 0.25 then
          current_color = 2
        elsif proportion > 0 then
          current_color = 3
        end
        x1 = enemy.x - 8
        y1 = enemy.y - 8
        colors = [Gosu::Color.rgba(50,205,50,255), Gosu::Color.rgba(255,255,0,255), Gosu::Color.rgba(255,140,0,255), Gosu::Color.rgba(255,0,0,255)]
        window.draw_quad(x1, y1, colors[current_color], x1 + 16, y1, colors[current_color], x1, y1 - 2, colors[current_color], x1 + 16, y1 - 2, colors[current_color], 0.75)
      end
    end
  end
  
  #
  # Draws the player's health bar
  #
  def draw_player_health_bar(window)
    return nil if @hp == @max_hp
    proportion = (@hp.to_f / @max_hp.to_f)
    if proportion > 0.75 then
      current_color = 0
    elsif proportion > 0.5 then
      current_color = 1
    elsif proportion > 0.25 then
      current_color = 2
    elsif proportion > 0 then
      current_color = 3
    end
    x1 = @x - 8
    y1 = @y - 8
    colors = [Gosu::Color.rgba(50,205,50,255), Gosu::Color.rgba(255,255,0,255), Gosu::Color.rgba(255,140,0,255), Gosu::Color.rgba(255,0,0,255)]
    window.draw_quad(x1, y1, colors[current_color], x1 + 16, y1, colors[current_color], x1, y1 - 2, colors[current_color], x1 + 16, y1 - 2, colors[current_color], 1.1)
  end
  
  #
  # Checks a certain cell for obstructions
  #
  def check_for_obstructions(cell_x, cell_y)
    # returns true on obstructions, false otherwise
    possible_door = get_barrier_at_pos(@map.door_array, cell_x, cell_y)
    if possible_door.class == Door and possible_door.closed? then
      return true
    elsif get_barrier_at_pos(@map.enemy_array, cell_x, cell_y).class == Enemy then
      return true
    elsif get_barrier_at_pos(@map.npc_array, cell_x, cell_y).class == NPC then
      return true
    elsif @map.map_array[1][cell_y][cell_x].class == Tile and @map.map_array[1][cell_y][cell_x].type == 'wall' then
      return true
    else
      return false
    end
  end
  
  #
  # Attempts to move in a certain direction
  #
  def move(direction)
    if @current_cell[0] * 32 == @x - 16 and @current_cell[1] * 32 == @y - 16 and @attacking == false then
      @map.update_los()
      pick_up_item()
      map_width  = $MAPSIZE - 1
      map_height = $MAPSIZE - 1
      x_diff = 0
      y_diff = 0
      case direction
        when :up
          return nil if @current_cell[1] == 0
          y_diff = -1
          angle = 0
        when :down
          return nil if @current_cell[1] == map_height
          y_diff = 1
          angle = 180
        when :left
          return nil if @current_cell[0] == 0
          x_diff = -1
          angle = 270
        when :right
          return nil if @current_cell[0] == map_width
          x_diff = 1
          angle = 90
      end
      if @map.map_array[1][@current_cell[1] + y_diff][@current_cell[0] + x_diff] != nil or @map.map_array[1][@current_cell[1] + y_diff][@current_cell[0] + x_diff] == ' ' then
        if check_for_obstructions(@current_cell[0] + x_diff, @current_cell[1] + y_diff) == false and @blocking == false then
          @current_cell[1] = (@current_cell[1] + y_diff)
          @current_cell[0] = (@current_cell[0] + x_diff)
          @map.warp(@current_cell[0], @current_cell[1])
        end
        @desired_angle = angle
        @map.update_view_window_coords()
      end
    end
  end
  
  #
  # Updates certain aspects of the player, called 60 times a second when the player exists
  #
  def update()
    @angle = angle_smoother(@angle, @desired_angle, 12)
    if @current_cell[0] * 32 != @x - 16 or @current_cell[1] * 32 != @y - 16 then
      if @current_cell[0] * 32 != @x - 16 then
        @x = smoother( @x, ((@current_cell[0] * 32) + 16), @speed )
        $SCROLL_X = @x
      end
      if @current_cell[1] * 32 != @y - 16 then
        @y = smoother( @y, ((@current_cell[1] * 32) + 16), @speed )
        $SCROLL_Y = @y
      end
      @moving = true if @moving == false
    elsif @current_cell[0] * 32 == @x - 16 and @current_cell[1] * 32 == @y - 16 then
      if @moving then
        @moving = false
        @map.update_los()
        pick_up_item()
      end
      if @attacking then
        @attack_tick -= 1
        if @attack_tick == 0 then
          @attacking = false
          @attack_tick = @attack_speed
        end
      end
    end
  end
  
  #
  # Draws the image passed to it
  #
  def draw_image(image)
    image.draw_rot(@x, @y, 1, @angle)
  end
  
  #
  # Draws all the things needed to be drawn for the player
  #
  def draw(window)
    draw_player_health_bar(window)
    draw_enemy_health_bar(window)
    if @crazy then
      if @moving then
        if @speed == 1.5 then
          draw_image(@crazy_animation[Gosu::milliseconds / 90 % @crazy_animation.size])
        elsif @speed > 1.5 then
          draw_image(@crazy_animation[Gosu::milliseconds / 70 % @crazy_animation.size])
        end
      elsif @attacking then
        draw_image(@crazy_attack_animation[(@crazy_attack_animation.count - 1) - ((@attack_tick * @crazy_attack_animation.count)/@attack_speed).floor])
      elsif @blocking then
        draw_image(@crazy_block_image)
      else
        draw_image(@crazy_animation[0])
      end
    else
      if @moving then
        if @speed == 1.5 then
          draw_image(@animation[Gosu::milliseconds / 90 % @animation.size])
        elsif @speed > 1.5 then
          draw_image(@animation[Gosu::milliseconds / 70 % @animation.size])
        end
      elsif @attacking then
        draw_image(@attack_animation[(@attack_animation.count - 1) - ((@attack_tick * @attack_animation.count)/@attack_speed).floor])
      elsif @blocking then
        draw_image(@block_image)
      else
        draw_image(@animation[0])
      end
    end
  end
end


#
# The Enemy class contains all methods and variables relevant to a specific enemy.
#
class Enemy
  # the enemy's x coordinate
  attr_accessor :x
  # the enemy's y coordinate
  attr_accessor :y
  # the type of enemy
  attr_reader :enemy_type
  # the current amount of hit points that the enemy has
  attr_reader :hp
  # the maximum amount of hit points that the enemy can obtain
  attr_reader :max_hp
  # whether or not the enemy is active (see's the player)
  attr_reader :active
  # an array containing the enemy's cell coordinates
  attr_reader :current_cell
  # the amount of player experience that the enemy gives the player when killed
  attr_reader :exp_value
  # the amount of weapon experience that the enemy gives the player when killed
  attr_reader :weapon_exp_value
  # the enemy's level (used for potion calculation, and scripted events)
  attr_reader :enemy_level
  
  #
  # Assigns loaded images related to the specific enemy, loads the enemy's
  # stats from the database, and initializes many essential variables
  #
  def initialize(window, enemy_type, cell_x, cell_y, map, enemy_image_hash)
    @enemy_type = enemy_type
    @image = enemy_image_hash["#{enemy_type}_movement.png"]
    stats = $db.execute("Select * From enemy_stats Where enemy_type = '#{enemy_type}'")[0]
    @max_hp = stats[1]
    @speed = stats[2]
    @max_attack_tick = stats[3]
    @damage_range = [stats[4], stats[5]]
    @exp_value = stats[6].to_i
    @weapon_exp_value = stats[7].to_i
    @enemy_level = stats[8].to_i
    @hp = @max_hp
    @current_cell = [cell_x, cell_y]
    @x = (@current_cell[0] * 32) + 16
    @y = (@current_cell[1] * 32) + 16
    @angle = @desired_angle = [0, 90, 180, 270].shuffle[0]
    @active = false
    @moving = false
    @attacking = false
    @attack_tick = @max_attack_tick
    @color = Gosu::Color.rgba(0, 0, 0, 255)
    @sight = false
  end
  
  #
  # Updates the enemy's line of sight
  #
  def update_los(player, wall_layer, door_array)
    if Gosu::distance(@x, @y, player.x, player.y) < 192 then
      get_line(@current_cell[0],@current_cell[1],player.current_cell[0],player.current_cell[1]).each do |cell|
        if wall_layer[cell[:y]][cell[:x]].is_a?(Tile)
          @sight = false
          return nil
        end
        door_array.each do |door|
          if door.closed? and door.current_cell == [cell[:x],cell[:y]]
            @sight = false
            return nil
          end
        end
      end
      @sight = true
    end
  end
  
  #
  # Changes the @color variable of the enemy to the tile underneathe the enemy
  #
  def change_lighting(tile)
    @color = tile.color
  end
  
  #
  # Damages the enemy for a certain amount
  #
  def damage(amount, map)
    map.scrolling_combat_text.add_number(amount, random((@x - 4).round, (@x + 4).round), random((@y - 4).round, (@y + 4).round), [255,255,255])
    if amount > @hp then
      @hp = 0
    else
      @hp -= amount
    end
    if @hp == 0 then
      map.player.enemy_slain(@exp_value)
      map.add_tombstone('enemy', (@current_cell[0] * 32)+random(1,8), (@current_cell[1] * 32)+random(1,8))
      if @enemy_level >= 1000 then
        map.credits()
      elsif random(1,10) <= 4 or @enemy_level >= 100 then
        map.add_item('healing_potion', ((@current_cell[0] * 32) + 16), ((@current_cell[1] * 32) + 16), @current_cell, @enemy_level, Gosu::Color.rgba(255,0,0,255))
      end
      map.enemy_array.delete(self)
      map.enemy_array.compact!
    end
  end
  
  #
  # Attempts to return the barrier at a certain cell position
  #
  def get_barrier_at_pos(barrier_array, cell_x, cell_y)
    barrier_array.each do |barrier|
      return barrier if barrier.current_cell == [cell_x, cell_y]
    end
    return nil
  end
  
  #
  # Checks a certain cell position for obstructions
  #
  def check_for_obstructions(cell_x, cell_y, map)
    # returns true on obstructions, false otherwise
    possible_door = get_barrier_at_pos(map.door_array, cell_x, cell_y)
    if possible_door.class == Door and possible_door.closed? then
      return true
    elsif get_barrier_at_pos(map.enemy_array, cell_x, cell_y).class == Enemy then
      return true
    elsif get_barrier_at_pos(map.npc_array, cell_x, cell_y).class == NPC then
      return true
    elsif map.map_array[1][cell_y][cell_x].class == Tile and map.map_array[1][cell_y][cell_x].type == 'wall' then
      return true
    else
      return false
    end
  end
  
  #
  # Converts any given angle to a cardinal angle
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
      vputs 'Weird angle in \'to_direction\' method of \'Enemy\' class.'
      return 0
    end
  end
  
  #
  # Attempts to attack / damage the player
  #
  def attack_player(map, menu)
    if @current_cell[0] * 32 == @x - 16 and @current_cell[1] * 32 == @y - 16 then
      if Gosu::distance(@x, @y, (map.player.current_cell[0] * 32)+16, (map.player.current_cell[1] * 32)+16) <= 32 then
        # Next to the player
        if @attack_tick > 0 then
          @attack_tick -= 1
        else
          # Attack!
          map.player.damage(random(@damage_range[0], @damage_range[1]), menu, @current_cell)
          @attack_tick = @max_attack_tick
        end
      else
        @attack_tick = @max_attack_tick
      end
    end
  end
  
  #
  # Attempts to move toward the player
  #
  def move_towards_player(map)
    if @current_cell[0] * 32 == @x - 16 and @current_cell[1] * 32 == @y - 16 and @sight then
      if Gosu::distance(@x - 16, @y - 16, map.player.current_cell[0] * 32, map.player.current_cell[1] * 32) > 32 then
        directions_to_move = []
        if @x < map.player.x then
          directions_to_move[0] = 'right'
        elsif @x == map.player.x then
          directions_to_move[0] = nil
        else
          directions_to_move[0] = 'left'
        end
        if @y < map.player.y then
          directions_to_move[1] = 'down'
        elsif @y == map.player.y then
          directions_to_move[1] = nil
        else
          directions_to_move[1] = 'up'
        end
        
        if directions_to_move[0] != nil then
          # Move left or right to the player's x coord
          if ((@x - 16) - (map.player.current_cell[0] * 32)).abs >= 32
            if directions_to_move[0] == 'right' then
              if check_for_obstructions(@current_cell[0] + 1, @current_cell[1], map) == false then
                @current_cell[0] += 1
                @desired_angle = 90
                return nil
              end
            else
              if check_for_obstructions(@current_cell[0] - 1, @current_cell[1], map) == false then
                @current_cell[0] -= 1
                @desired_angle = 270
                return nil
              end
            end
          end
        end
        if directions_to_move[1] != nil then
          # Move up or down to the player's y coord
          if ((@y - 16) - (map.player.current_cell[1] * 32)).abs >= 32 then
            if directions_to_move[1] == 'down' then
              if check_for_obstructions(@current_cell[0], @current_cell[1] + 1, map) == false then
                @current_cell[1] += 1
                @desired_angle = 180
                return nil
              end
            else
              if check_for_obstructions(@current_cell[0], @current_cell[1] - 1, map) == false then
                @current_cell[1] -= 1
                @desired_angle = 0
                return nil
              end
            end
          end
        end
      else
        # Stare in the player's direction
        @desired_angle = to_direction(Gosu::angle(@x, @y, map.player.x, map.player.y))
      end
    end
  end
  
  #
  # Updates various variables in the enemy
  #
  def update(map, menu)
    @angle = angle_smoother(@angle, @desired_angle, 16)
    if @active then
      # Try to attack player
      attack_player(map, menu) if map.player != nil
      if map.player != nil
        # Try to move towards player
        move_towards_player(map)
        # Try to deactivate
        if Gosu::distance(@x, @y, map.player.x, map.player.y) > 192 then
          @active = false
        end
      end
    else
      if map.player != nil then
        # Try to activate
        if Gosu::distance(@x, @y, map.player.x, map.player.y) < 192 then
          @active = true
        end
      end
    end
    if map.player != nil then
      if @current_cell[0] * 32 != @x - 16 or @current_cell[1] * 32 != @y - 16 then
        @x = smoother( @x, ((@current_cell[0] * 32) + 16), @speed )
        @y = smoother( @y, ((@current_cell[1] * 32) + 16), @speed )
        @moving = true if @moving == false
      else
        @moving = false if @moving
      end
    end
  end
  
  #
  # Draws an enemy image
  #
  def draw_image(image)
    image.draw_rot(@x, @y, 0.5, @angle, 0.5, 0.5, 1, 1, @color)
  end
  
  #
  # Draws the enemy
  #
  def draw(window)
    if @image.class == Array then
      if @moving then
        if @speed == 0.5 then
          draw_image(@image[Gosu::milliseconds / 140 % @image.size])
        elsif @speed == 0.75 then
          draw_image(@image[Gosu::milliseconds / 120 % @image.size])
        elsif @speed == 1 then
          draw_image(@image[Gosu::milliseconds / 110 % @image.size])
        elsif @speed == 1.5 then
          draw_image(@image[Gosu::milliseconds / 90 % @image.size])
        elsif @speed == 2 then
          draw_image(@image[Gosu::milliseconds / 70 % @image.size])
        end
      else
        draw_image(@image[0])
      end
    else
      draw_image(@image)
    end
  end
end


# Error handling code & Window creation
#begin
  window = GameWindow.new()
  window.show()
  $log.debug('GameWindow created & shown')
#rescue => error # This will catch any error not caught by above methods.
                ## Errors caught by this are unrecoverable due to being
                ## caught after the window is destroyed.
                ## These are huge deals, and as such an email is sent.
  #$log.fatal('An undefined error has occurred')
  #$log.fatal(error)
  #send_email("Error: V.#{$VERSION}", error.inspect)
  #vputs 'An error has occured'
  #vputs 'Please check logfile.log for more information'
#ensure
  Databases.unload()
  $log.debug('Databases Unloaded')
  $log.info('Program Ended')
  $log.close()
#end


__END__
