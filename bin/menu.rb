
#
# The StartMenu class controls the start menu and sub-menus in the game, as well as the death menu.
#
class StartMenu
  # Controls whether or not the menu is visible (true|false)
  attr_accessor :visible
  # Contains a string of the name of the current profile
  attr_reader :current_profile
  
  #
  # Loads all the images, fonts, and sounds into variables and sets various variables.
  #
  def initialize(window)
    @font_scale = 2.0
    @menu_x, @menu_y = 256, 192
    @visible = true
    @profile_array = get_profile_array()
    if @profile_array.empty? then
      @profile_array << 'new_profile'
    end
    @current_profile = @profile_array[0]
    # Main screen
    @title_background = Gosu::Image.new(window, '../mainfiles/media/gui/game/title.png', true)
    @main_selector_positions = [@menu_y, @menu_y + 32, @menu_y + 64, @menu_y + 96]
    @main_selector_pos = 0
    # ---
    # Play screen
    @play_selector_positions = [@menu_y, @menu_y + 32]
    @play_selector_pos = 0
    # ---
    # Options screen
    @options_selector_positions = [@menu_y, @menu_y + 32, @menu_y + 64]
    @options_selector_pos = 0
    @options_resolutions = [[640, 480], [800, 600], [1024, 768]]
    @options_resolutions_pos = 0
    @sound_values = ['No Sound', 'Sound', 'Sound & Music']
    @sound_pos = 2
    # ---
    # Game Over screen
    @game_over_selector_positions = [@menu_y + 32, @menu_y + 64]
    @game_over_selector_pos = 0
    # ---
    # Pause screen
    @pause_selector_positions = [@menu_y + 32, @menu_y + 64, @menu_y + 96]
    @pause_selector_pos = 0
    # ---
    # Credits screen
    @closure = Gosu::Image.new(window, '../mainfiles/media/gui/game/closure.png', true)
    # ---
    @selector = Gosu::Image.new(window, '../mainfiles/media/gui/game/selector.png', true)
    @screen = 'main'
    @menu_beep = Gosu::Sample.new(window, '../mainfiles/media/sound/menu_beep.ogg')
    @menu_enter_beep = Gosu::Sample.new(window, '../mainfiles/media/sound/menu_enter_beep.ogg')
    @dark_color = Gosu::Color.rgba(0, 0, 0, 200)
    @bit_8_font_small = Gosu::Font.new(window, '../mainfiles/fonts/8bit.ttf', (10 * @font_scale).to_i)
    @bit_8_font = Gosu::Font.new(window, '../mainfiles/fonts/8bit.ttf', (16 * @font_scale).to_i)
    @bit_8_font_large = Gosu::Font.new(window, '../mainfiles/fonts/8bit.ttf', (24 * @font_scale).to_i)
    @startup_timer = 240
    @startup = true
    @inactivity_timer = 0
    @inactivity_time = 20
  end
  
  #
  # Returns an array of all the save profiles
  #
  def get_profile_array()
    results = search_directory('../saves/', '*')
    results.each_index do |i|
      if File.directory?(results[i]) then
        results[i] = results[i].split('/').last
      else
        results[i] = nil
      end
    end
    return results.compact
  end
  
  #
  # Toggles the pause screen displaying
  #
  def toggle_pause()
    if @screen == 'pause' then
      @screen = 'main'
      @visible = false
    else
      @screen = 'pause'
      @visible = true
    end
  end
  
  #
  # Sets the current menu screen to game_over
  #
  def credits_screen()
    @screen = 'credits'
    @visible = true
  end
  
  #
  # Sets the current menu screen to game_over
  #
  def game_over_screen()
    @screen = 'game_over'
    @visible = true
  end
  
  #
  # Handles all the button pressing events in the menu
  #
  def button_pressed(id, window, map)
    @inactivity_timer = 0
    if @startup == false then
      if id == Gosu::Button::KbEscape
        @screen = 'main' if @screen != 'game_over' and @screen != 'pause'
      end
      if id == Gosu::Button::KbUp
        arrow_key_pressed(:up)
      end
      if id == Gosu::Button::KbDown
        arrow_key_pressed(:down)
      end
      if id == Gosu::Button::KbLeft
        arrow_key_pressed(:left)
      end
      if id == Gosu::Button::KbRight
        arrow_key_pressed(:right)
      end
      if id == Gosu::Button::KbReturn
        enter_key_pressed(window, map)
      end
      if @screen == 'play_yes_no' then
        if id == Gosu::Button::KbY
          # Yes to new game
          $log.info("New game started with profile '#{@current_profile}'")
          map.new_game(@current_profile)
          @visible = false
        end
        if id == Gosu::Button::KbN
          # No to new game
          @screen = 'play'
        end
      end
    else
      @startup = false
    end
  end
  
  #
  # Handles all the arrow key pressing events in the menu (called from button_pressed)
  #
  def arrow_key_pressed(type)
    if @screen == 'main' then
      if type == :up then # Up
        if @main_selector_pos > 0 then
          @main_selector_pos -= 1
        else
          @main_selector_pos = (@main_selector_positions.count - 1)
        end
      elsif type == :down then # Down
        if @main_selector_pos < (@main_selector_positions.count - 1) then
          @main_selector_pos += 1
        else
          @main_selector_pos = 0
        end
      elsif type == :left then # Left
        index = @profile_array.index(@current_profile)
        if index > 0 then
          index -= 1
        else
          index = @profile_array.count - 1
        end
        @current_profile = @profile_array[index]
      elsif type == :right then # Right
        index = @profile_array.index(@current_profile)
        if index < @profile_array.count - 1 then
          index += 1
        else
          index = 0
        end
        @current_profile = @profile_array[index]
      end
    elsif @screen == 'play' then
      if type == :up then # Up
        if @play_selector_pos > 0 then
          @play_selector_pos -= 1
        else
          @play_selector_pos = 1
        end
      elsif type == :down then # Down
        if @play_selector_pos < 1 then
          @play_selector_pos += 1
        else
          @play_selector_pos = 0
        end
      end
    elsif @screen == 'options' then
      if type == :up then # Up
        if @options_selector_pos > 0 then
          @options_selector_pos -= 1
        else
          @options_selector_pos = (@options_selector_positions.count - 1)
        end
      elsif type == :down then # Down
        if @options_selector_pos < (@options_selector_positions.count - 1) then
          @options_selector_pos += 1
        else
          @options_selector_pos = 0
        end
      end
    elsif @screen == 'pause' then
      if type == :up then # Up
        if @pause_selector_pos > 0 then
          @pause_selector_pos -= 1
        else
          @pause_selector_pos = 2
        end
      elsif type == :down then # Down
        if @pause_selector_pos < 2 then
          @pause_selector_pos += 1
        else
          @pause_selector_pos = 0
        end
      end
    elsif @screen == 'game_over' then
      if type == :up then # Up
        if @game_over_selector_pos > 0 then
          @game_over_selector_pos -= 1
        else
          @game_over_selector_pos = 1
        end
      elsif type == :down then # Down
        if @game_over_selector_pos < 1 then
          @game_over_selector_pos += 1
        else
          @game_over_selector_pos = 0
        end
      end
    end
    @menu_beep.play(0.1, 1, false) if $SOUND != 0
  end
  
  #
  # Handles all the enter key pressing events (called from button_pressed)
  #
  def enter_key_pressed(window, map)
    if @screen == 'main' then
      if @main_selector_pos == 0 then # Play game button
        @screen = 'play'
      elsif @main_selector_pos == 1 then # Options button
        @screen = 'options'
      elsif @main_selector_pos == 2 then # Help button
        @screen = 'help'
      elsif @main_selector_pos == 3 then # Exit button
        window.close()
      end
    elsif @screen == 'play' then
      if @play_selector_pos == 0 then
        @screen = 'play_yes_no'
      elsif @play_selector_pos == 1 then
        # Check to see if files exist
        save_path = "../saves/#{@current_profile}"
        if File.exists?("#{save_path}/core_database.db") and File.exists?("#{save_path}/player.db") then
          $log.info("Game continued with profile '#{@current_profile}'")
          map.continue_game(@current_profile)
          @visible = false
        end
      end
    elsif @screen == 'help' then
      @screen = 'main'
    elsif @screen == 'options' then
      if @options_selector_pos == 0 then # Resolution changer
        if @options_resolutions_pos < (@options_resolutions.count - 1) then
          @options_resolutions_pos += 1
        else
          @options_resolutions_pos = 0
        end
      elsif @options_selector_pos == 1 then # Sound changer
        if @sound_pos < (@sound_values.count - 1) then
          @sound_pos += 1
        else
          @sound_pos = 0
        end
      elsif @options_selector_pos == 2 then # Save & Exit
        if @sound_values[@sound_pos] == 'No Sound' then
          sound = 0
        elsif @sound_values[@sound_pos] == 'Sound' then
          sound = 1
        elsif @sound_values[@sound_pos] == 'Sound & Music' then
          sound = 2
        end
        properties_data = Marshal::dump([@options_resolutions[@options_resolutions_pos][0], @options_resolutions[@options_resolutions_pos][1], sound])
        create_file('../saves/properties.dat', properties_data)
        @options_selector_pos = 0
        @screen = 'main'
      end
    elsif @screen == 'pause' then # Pause Menu
      if @pause_selector_pos == 0 then # Resume
        un_pause(window)
      elsif @pause_selector_pos == 1 then # Load Last Save
        un_pause(window)
        load_last_save(map)
      else # Main Menu
        window.paused = false
        map.clear_map_data()
        @screen = 'main'
      end
    elsif @screen == 'game_over' then # Game Over screen
      if @game_over_selector_pos == 0 then # Load Last Save
        load_last_save(map)
      elsif @game_over_selector_pos == 1 then # Back to main menu
        map.clear_map_data()
        @screen = 'main'
      end
    end
    @menu_enter_beep.play(0.1, 1, false) if $SOUND != 0
  end
  
  def un_pause(window)
    @screen = 'main'
    @visible = false
    window.paused = false
  end
  
  def load_last_save(map)
    # Check to see if files exist
    save_path = "../saves/#{@current_profile}"
    if File.exists?("#{save_path}/core_database.db") and File.exists?("#{save_path}/player.db") then
      map.continue_game(@current_profile)
      @visible = false
    end
  end
  
  #
  # Returns the current menu z layer
  #
  def get_z()
    if @screen == 'main' then
      return 1
    else
      return 2
    end
  end
  
  #
  # Updates the inactivity timer on the menu
  #
  def update()
    # Incremented 60 times a second
    @inactivity_timer += 1
    if @startup == true then
      if @startup_timer > 0 then
        @startup_timer -= 1
      else
        @startup = false
      end
    end
  end
  
  #
  # Draws all visible elements on the menu
  #
  def draw(window)
    if @startup == false and (@inactivity_timer / 60) < @inactivity_time and @screen != 'game_over' and @screen != 'credits' and @screen != 'pause' then
      @title_background.draw(0,0,0)
      # Main menu
      @bit_8_font.draw('Play', @menu_x + 8, @menu_y, get_z, 1 / @font_scale, 1 / @font_scale)
      @bit_8_font.draw('Options', @menu_x + 8, @menu_y + 32, get_z, 1 / @font_scale, 1 / @font_scale)
      @bit_8_font.draw('Help', @menu_x + 8, @menu_y + 64, get_z, 1 / @font_scale, 1 / @font_scale)
      @bit_8_font.draw('Exit', @menu_x + 8, @menu_y + 96, get_z, 1 / @font_scale, 1 / @font_scale)
      @selector.draw(@menu_x - 16, @main_selector_positions[@main_selector_pos], get_z)
      # Profile Selector
      @bit_8_font.draw("< #{@current_profile} >", @menu_x + 96, @menu_y, get_z, 1 / @font_scale, 1 / @font_scale)
      # ---
      @bit_8_font_small.draw($VERSION, 8, 464, get_z, 1 / @font_scale, 1 / @font_scale)
      # ---
      # Play screen
      if @screen == 'play' or @screen == 'play_yes_no' then
        @selector.draw(@menu_x - 48, @play_selector_positions[@play_selector_pos], get_z + 1)
        @bit_8_font_large.draw('Play', @menu_x - 10, @menu_y - 64, 3, 1 / @font_scale, 1 / @font_scale)
        @bit_8_font.draw('New Game', @menu_x - 16, @menu_y, 3, 1 / @font_scale, 1 / @font_scale)
        @bit_8_font.draw('Continue', @menu_x - 16, @menu_y + 32, 3, 1 / @font_scale, 1 / @font_scale)
      elsif @screen == 'help' then
        @bit_8_font_large.draw('Help:', @menu_x - 24, @menu_y - 128, get_z + 1, 1 / @font_scale, 1 / @font_scale)
        @bit_8_font.draw('Controls:', @menu_x - 224, @menu_y - 64, get_z + 1, 1 / @font_scale, 1 / @font_scale)
        @bit_8_font.draw('---------', @menu_x - 224, @menu_y - 32, get_z + 1, 1 / @font_scale, 1 / @font_scale)
        @bit_8_font.draw('WASD / Arrows | Movement', @menu_x - 224, @menu_y, get_z + 1, 1 / @font_scale, 1 / @font_scale)
        @bit_8_font.draw('Shift         | Sprint', @menu_x - 224, @menu_y + 32, get_z + 1, 1 / @font_scale, 1 / @font_scale)
        @bit_8_font.draw('\'F\'           | Swing Sword', @menu_x - 224, @menu_y + 64, get_z + 1, 1 / @font_scale, 1 / @font_scale)
        @bit_8_font.draw('\'R\'           | Block Attacks', @menu_x - 224, @menu_y + 96, get_z + 1, 1 / @font_scale, 1 / @font_scale)
        @bit_8_font.draw('\'E\'           | Interact', @menu_x - 224, @menu_y + 128, get_z + 1, 1 / @font_scale, 1 / @font_scale)
        @bit_8_font.draw('Consult Manual for further info.', @menu_x - 224, @menu_y + 192, get_z + 1, 1 / @font_scale, 1 / @font_scale)
      elsif @screen == 'options' then
        @selector.draw(@menu_x - 48, @options_selector_positions[@options_selector_pos], get_z + 1)
        @bit_8_font_large.draw('Options', @menu_x - 32, @menu_y - 64, 10, 1 / @font_scale, 1 / @font_scale)
        @bit_8_font.draw("#{@options_resolutions[@options_resolutions_pos][0]}x#{@options_resolutions[@options_resolutions_pos][1]}", @menu_x - 16, @menu_y, 10, 1 / @font_scale, 1 / @font_scale)
        @bit_8_font.draw(@sound_values[@sound_pos], @menu_x - 16, @menu_y + 32, 10, 1 / @font_scale, 1 / @font_scale)
        @bit_8_font.draw('Save & Exit', @menu_x - 16, @menu_y + 64, 10, 1 / @font_scale, 1 / @font_scale)
      end
      if @screen == 'play_yes_no' then
        @bit_8_font.draw('Are you sure you want to', @menu_x - 128, @menu_y, 10, 1 / @font_scale, 1 / @font_scale)
        @bit_8_font.draw('start a new game?', @menu_x - 80, @menu_y + 16, 10, 1 / @font_scale, 1 / @font_scale)
        @bit_8_font.draw('\'y\' or \'n\'', @menu_x - 32, @menu_y + 48, 10, 1 / @font_scale, 1 / @font_scale)
        window.draw_quad( 0, 0, @dark_color, $WINDOW_WIDTH, 0, @dark_color, 0, $WINDOW_HEIGHT, @dark_color, $WINDOW_WIDTH, $WINDOW_HEIGHT, @dark_color, get_z + 1, :default )
      end
      if get_z > 1 then
        window.draw_quad( 0, 0, @dark_color, $WINDOW_WIDTH, 0, @dark_color, 0, $WINDOW_HEIGHT, @dark_color, $WINDOW_WIDTH, $WINDOW_HEIGHT, @dark_color, get_z, :default )
      end
    elsif @startup == true then
      # Startup Screen
      @bit_8_font_large.draw('Blitbit Interactive', @menu_x - 176, @menu_y - 128, 10, 1 / @font_scale, 1 / @font_scale)
      @bit_8_font_large.draw('and', @menu_x + 16, @menu_y - 80, 10, 1 / @font_scale, 1 / @font_scale)
      @bit_8_font_large.draw('Team SG-1', @menu_x - 48, @menu_y - 32, 10, 1 / @font_scale, 1 / @font_scale)
      @bit_8_font_large.draw('Present', @menu_x - 32, @menu_y + 16, 10, 1 / @font_scale, 1 / @font_scale)
      # ---
    elsif @screen == 'credits' then
      @bit_8_font_large.draw('Credits:', @menu_x - 128, @menu_y - 128, 10, 1 / @font_scale, 1 / @font_scale)
      @bit_8_font.draw('Chase Arnold    - Programming', @menu_x - 128, @menu_y - 96, 10, 1 / @font_scale, 1 / @font_scale)
      @bit_8_font.draw('Scott Batzer    - Writer', @menu_x - 128, @menu_y - 64, 10, 1 / @font_scale, 1 / @font_scale)
      @bit_8_font.draw('Clayton Mathews - Art & Media', @menu_x - 128, @menu_y - 32, 10, 1 / @font_scale, 1 / @font_scale)
      @bit_8_font.draw('Thanks for playing!', @menu_x - 128, @menu_y + 32, 10, 1 / @font_scale, 1 / @font_scale)
      @bit_8_font_small.draw('And then as he sat on his throne,', @menu_x - 208, @menu_y + 80, 10, 1 / @font_scale, 1 / @font_scale)
      @bit_8_font_small.draw('he ordered that one dude executed.', @menu_x - 208, @menu_y + 96, 10, 1 / @font_scale, 1 / @font_scale)
      @closure.draw(@menu_x + 144, @menu_y + 64, 10, 0.5, 0.5)
    elsif @screen == 'pause' then
      @selector.draw(@menu_x - 48, @pause_selector_positions[@pause_selector_pos], 10)
      window.draw_quad( 0, 0, 0xFF000000, $WINDOW_WIDTH, 0, 0xFF000000, 0, $WINDOW_HEIGHT, 0x69000000, $WINDOW_WIDTH, $WINDOW_HEIGHT, 0x69000000, 6, :default )
      @bit_8_font_large.draw('--------', @menu_x - 32, @menu_y - 64, 10, 1 / @font_scale, 1 / @font_scale, 0xffFF0000)
      @bit_8_font_large.draw(' PAUSED ', @menu_x - 32, @menu_y - 48, 10, 1 / @font_scale, 1 / @font_scale)
      @bit_8_font_large.draw('<      >', @menu_x - 32, @menu_y - 48, 10, 1 / @font_scale, 1 / @font_scale, 0xffFF0000)
      @bit_8_font_large.draw('--------', @menu_x - 32, @menu_y - 32, 10, 1 / @font_scale, 1 / @font_scale, 0xffFF0000)
      @bit_8_font.draw('Resume Game', @menu_x - 16, @menu_y + 32, 10, 1 / @font_scale, 1 / @font_scale)
      @bit_8_font.draw('Last Save', @menu_x - 16, @menu_y + 64, 10, 1 / @font_scale, 1 / @font_scale)
      @bit_8_font.draw('Main Menu', @menu_x - 16, @menu_y + 96, 10, 1 / @font_scale, 1 / @font_scale)
    elsif @screen == 'game_over' then #Display game over screen and asks to either load a save or exit to main menu
      @selector.draw(@menu_x - 48, @game_over_selector_positions[@game_over_selector_pos], 10)
      window.draw_quad( 0, 0, @dark_color, $WINDOW_WIDTH, 0, @dark_color, 0, $WINDOW_HEIGHT, @dark_color, $WINDOW_WIDTH, $WINDOW_HEIGHT, @dark_color, 6, :default )
      @bit_8_font_large.draw('You died!', @menu_x - 48 + 3, @menu_y - 48 - 3, 10, 1 / @font_scale, 1 / @font_scale, 0xff00FF22)
      @bit_8_font_large.draw('You died!', @menu_x - 48, @menu_y - 48, 10, 1 / @font_scale, 1 / @font_scale, 0xffFF0090, :additive)
      @bit_8_font.draw('Last Save', @menu_x - 16, @menu_y + 32, 10, 1 / @font_scale, 1 / @font_scale)
      @bit_8_font.draw('Main Menu', @menu_x - 16, @menu_y + 64, 10, 1 / @font_scale, 1 / @font_scale)
    elsif (@inactivity_timer / 60) >= @inactivity_time then
      # In case of inactivity for 20 seconds, then display Credits and Controls
      current_inactivity = (@inactivity_timer / 60.0) - @inactivity_time
      if current_inactivity < 7 then
        # Controls
        if current_inactivity < 5.5 then #Attack Key
          @bit_8_font.draw('\'F\' Key - Attack', @menu_x - 128, @menu_y - 32, 10, 1 / @font_scale, 1 / @font_scale)
        end
        if current_inactivity < 6 then   #Use Key
          @bit_8_font.draw('\'E\' Key - Use', @menu_x - 128, @menu_y - 64, 10, 1 / @font_scale, 1 / @font_scale)
        end
        if current_inactivity < 6.5 then #Movement Keys
          @bit_8_font.draw('W,A,S,D  - Walking', @menu_x - 128, @menu_y - 96, 10, 1 / @font_scale, 1 / @font_scale)
        end
        if current_inactivity < 7 then   #Displays all Controls
          @bit_8_font_large.draw('Controls:', @menu_x - 128, @menu_y - 128, 10, 1 / @font_scale, 1 / @font_scale)
        end
        # ---
      elsif current_inactivity >= 7 and current_inactivity < 14 then
        # Credits
        if current_inactivity < 12.5 then #Display Clayton's Credit
          @bit_8_font.draw('Clayton Mathews - Art & Media', @menu_x - 128, @menu_y - 32, 10, 1 / @font_scale, 1 / @font_scale)
        end
        if current_inactivity < 13 then   #Display Scott's Credit
          @bit_8_font.draw('Scott Batzer    - Writer', @menu_x - 128, @menu_y - 64, 10, 1 / @font_scale, 1 / @font_scale)
        end
        if current_inactivity < 13.5 then #Display Chase's Credit
          @bit_8_font.draw('Chase Arnold    - Programming', @menu_x - 128, @menu_y - 96, 10, 1 / @font_scale, 1 / @font_scale)
        end
        if current_inactivity < 14 then   #Credit
          @bit_8_font_large.draw('Credits:', @menu_x - 128, @menu_y - 128, 10, 1 / @font_scale, 1 / @font_scale)
        end
        # ---
      elsif current_inactivity >= 14 then
        @inactivity_timer = 0
      end
      # ---
    end
  end
end
