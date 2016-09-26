
#
# The Gui class handles GUI elements and draws them on the game windows
#
class Gui
  #
  # Loads GUI images, and sets various variables
  #
  def initialize(window, player)
    @font_scale = 2.0
    @window = window
    @player = player
    @heart_tileset = Gosu::Image::load_tiles(window, '../mainfiles/media/gui/game/tileset_hearts.png', 16, 16, false)
    @font_12 = Gosu::Font.new(window, '../mainfiles/fonts/8bit.ttf', (12 * @font_scale).to_i)
    @heart_stages = [5,5,5,5]
  end
  
  #
  # Updates per-heart information
  #
  def update()
    heart_max_hp = (@player.max_hp / 4) #Finds the maximum health value for each heart
    heart_array = [20,20,20,20]
    heart_array.each_index do |i|
      if @player.hp >= (heart_max_hp * (i+1)) then
        # Full heart
        heart_array[i] = heart_max_hp
      elsif @player.hp < (heart_max_hp * i) then
        # Empty heart
        heart_array[i] = 0
      else
        # Partial heart
        heart_array[i] = @player.hp % heart_max_hp
      end
    end
    
    @heart_stages.each_index do |i|
      percentage = (heart_array[i].to_f / heart_max_hp.to_f) #Calculates the percentage of each heart
      if percentage == 1 then
        @heart_stages[i] = 5 #6/6 heart
      elsif percentage >= 0.75 then
        @heart_stages[i] = 4 #5/6 heart
      elsif percentage >= 0.5 then
        @heart_stages[i] = 3 #4/6 heart
      elsif percentage >= 0.25 then
        @heart_stages[i] = 2 #3/6 heart
      elsif percentage > 0 then
        @heart_stages[i] = 1 #2/6 heart
      else
        @heart_stages[i] = 0 #1/6 heart
      end
    end
  end
  
  #
  # Draws the GUI
  #
  def draw()
    # Health Hearts ---
    4.times do |i| #Draws the hearts depending on how much health is in each heart
      @heart_tileset[@heart_stages[i]].draw((18 * i) + 32, 8, 5, 1, 1, 0xFFFF0000)
    end
    @font_12.draw("#{@player.hp}/#{@player.max_hp}", 116, 10, 5, 1 / @font_scale, 1 / @font_scale)
    # ---
    # Draws the user interface for Damage, Player Level, Sword Level, and experience values
    @font_12.draw("Damage: #{@player.damage_range[0]}-#{@player.damage_range[1]}", 448, 8, 5, 1 / @font_scale, 1 / @font_scale)
    @font_12.draw("Player Level: #{@player.player_level}", 32, 448, 5, 1 / @font_scale, 1 / @font_scale)
    @font_12.draw("Sword  Level: #{@player.sword_level}", 32, 464, 5, 1 / @font_scale, 1 / @font_scale)
    @font_12.draw("(#{@player.player_xp}/#{@player.player_max_xp})", 240, 448, 5, 1 / @font_scale, 1 / @font_scale)
    @font_12.draw("(#{@player.sword_xp}/#{@player.sword_max_xp})", 240, 464, 5, 1 / @font_scale, 1 / @font_scale)
    # ---
  end
end

