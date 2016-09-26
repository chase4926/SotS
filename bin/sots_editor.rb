#!/usr/bin/env ruby
=begin
TODO:
	-Undo button
  -Optimize!
=end


require 'rubygems'
require_relative '../vendor/bundle/bundler/setup'
$VERBOSE = true
include Gosu

require_relative 'lib/lib.rb'
require_relative 'lib/lib_misc.rb'
require_relative 'db_module.rb'


# Initialize Databases
Databases.init('../core_files/databases')
# ---


$MAPSIZE = 64
if ARGV[0] == '1' then
  $FULLSCREEN = true
else
  $FULLSCREEN = false
end


def marshalfileread(file)
  if ! File.exists?(file) then
    vputs 'That file doesn\'t exist: '  + file.inspect
    return ''
  end
  return Marshal::load( File.open(file, 'r') )
end

class GameWindow < Gosu::Window
  attr_accessor :current_status
  
  def initialize
    super(1280, 800, $FULLSCREEN) # The Window properties
    self.caption = 'Project Wayback Editor' # The Window caption
    @selector = Selector.new(self)
    @gui = Gui.new(self)
    @map = Map.new(self)
    @font = Gosu::Font.new(self, Gosu::default_font_name, 20)
    @textfield = nil
    @current_status = nil
	  @scrollx = @scrolly = 0
	  @scroll_speel = 2
  end # End GameWindow Initialize
  
  def needs_cursor?
    true
  end
  
  def create_textfield(type)
    x = 64
    y = 64
    if type == 'save' then
      @textfield = TextField.new(self, @font, x, y)
      @textfield.text = ''
      self.text_input = @textfield
    elsif type == 'load' then
      @textfield = TextField.new(self, @font, x, y)
      @textfield.text = ''
      self.text_input = @textfield
    end
  end
  
  def update
    @selector.update(mouse_x - @scrollx, mouse_y - @scrolly)
    @gui.update()
    if button_down? Gosu::Button::KbUp or button_down? Gosu::Button::GpUp or button_down? Gosu::Button::KbW then
      @scrolly += @scroll_speed
    end
    if button_down? Gosu::Button::KbDown or button_down? Gosu::Button::GpDown or button_down? Gosu::Button::KbS then
      @scrolly -= @scroll_speed
    end
    if button_down? Gosu::Button::KbLeft or button_down? Gosu::Button::GpLeft or button_down? Gosu::Button::KbA then
      @scrollx += @scroll_speed
    end
    if button_down? Gosu::Button::KbRight or button_down? Gosu::Button::GpRight or button_down? Gosu::Button::KbD then
      @scrollx -= @scroll_speed
    end
    if button_down? Gosu::KbLeftShift or button_down? Gosu::KbRightShift then
      @scroll_speed = 8
    else
      @scroll_speed = 2
    end
    if button_down? Gosu::MsLeft then
	    if mouse_x < 1216 and mouse_x > 0 and mouse_x - @scrollx < $MAPSIZE * 32 and mouse_x - @scrollx > 0 and mouse_y < 736 and mouse_y > 0 and mouse_y - @scrolly < $MAPSIZE * 32 and mouse_y - @scrolly > 0 then
		    if @gui.current_tool == 'place' then
          @map.addtile(self, @selector.x, @selector.y, @gui)
        elsif @gui.current_tool == 'enemy' then
          @map.place_enemy(self, @selector.x, @selector.y, @gui.enemy_type_array[@gui.enemy_type_array[0] + 1][0])
        end
	    end
    elsif button_down? Gosu::MsRight then
      if mouse_x < 1216 and mouse_x > 0 and mouse_x - @scrollx < $MAPSIZE * 32 and mouse_x - @scrollx > 0 and mouse_y < 736 and mouse_y > 0 and mouse_y - @scrolly < $MAPSIZE * 32 and mouse_y - @scrolly > 0 then
        if @gui.current_tool == 'enemy' then
          @map.remove_enemy(@selector.x, @selector.y)
        elsif @gui.current_tool == 'place' then
          z = @gui.get_tileset_layer(@gui.tileset_type)
          @map.removetile( (@selector.x / 32), (@selector.y / 32), z )
        end
      end
    end
  end # End GameWindow Update

  def draw
    if @textfield != nil then
      @textfield.draw()
    end
    if @current_status == 'loading' then
      @font.draw('Type the file to load:', 64, 32, 10, 1.0, 1.0, 0xffffffff)
    elsif @current_status == 'saving' then
      @font.draw('Type the file to save:', 64, 32, 10, 1.0, 1.0, 0xffffffff)
    end
    @gui.draw(self)
    clip_to(0, 0, 1216, 736) do
	    translate(@scrollx, @scrolly) do
        @selector.draw()
        @map.draw(@gui)
	    end
    end
  end # End GameWindow Draw

  def button_down(id)
    if id == Gosu::Button::KbEscape
      if @textfield != nil then
        self.text_input = nil
        @textfield = nil
        @current_status = nil
      else
        close
      end
    end
    if id == Gosu::KbDelete
      @map.fillarea(self, @gui, true) if @gui.current_tool == 'fill'
    end
    if id == Gosu::MsLeft
      @gui.click(mouse_x, mouse_y, self, @map)
      if mouse_x < 1216 and mouse_x > 0 and mouse_x - @scrollx < $MAPSIZE * 32 and mouse_x - @scrollx > 0 and mouse_y < 736 and mouse_y > 0 and mouse_y - @scrolly < $MAPSIZE * 32 and mouse_y - @scrolly > 0 then
        if @gui.current_tool == 'fill' then
          @map.first_fill_x = @selector.x
          @map.first_fill_y = @selector.y
          @map.update_fill_selectors()
        end
      end
    end
    if id == Gosu::MsRight
        if mouse_x < 1216 and mouse_x > 0 and mouse_x - @scrollx < $MAPSIZE * 32 and mouse_x - @scrollx > 0 and mouse_y < 736 and mouse_y > 0 and mouse_y - @scrolly < $MAPSIZE * 32 and mouse_y - @scrolly > 0 then
          if @gui.current_tool == 'fill' then
          @map.second_fill_x = @selector.x
          @map.second_fill_y = @selector.y
          @map.update_fill_selectors()
        end
      end
    end
    if id == Gosu::KbReturn and self.text_input != nil then
      if @current_status == 'saving' then
        @map.save_level(@textfield.text)
      elsif @current_status == 'loading' then
        @map.load_level(@textfield.text, self, @gui)
      end
      self.text_input = nil
      @textfield = nil
      @current_status = nil
    elsif id == Gosu::KbReturn then
      @map.fillarea(self, @gui) if @gui.current_tool == 'fill'
    end
    if id == Gosu::Button::MsMiddle
      puts "#{@selector.x / 32},#{@selector.y / 32}"
    end
  end
end # End GameWindow class


class Selector
  attr_accessor :x, :y

  def initialize(window)
    @image = Gosu::Image.new(window, '../mainfiles/media/gui/editor/selector.png', false)
    @x = @y = 0.0
  end
  
  def update(mousex, mousey)
    #if mousex < 1216 and mousex > 0 then
	  if mousex < $MAPSIZE * 32 and mousex > 0 then
      @x = (((mousex.to_f - 16) / 32.0).round * 32)
    else
      if mousex < 0 then
        @x = 0
      end
      if mousex > $MAPSIZE * 32 then
        @x = ($MAPSIZE * 32) - 32
      end
    end
    if mousey < $MAPSIZE * 32 and mousey > 0 then
      @y = (((mousey.to_f - 16) / 32.0).round * 32)
    else
      if mousey < 0 then
        @y = 0
      end
      if mousey > $MAPSIZE * 32 then
        @y = ($MAPSIZE * 32) - 32
      end
    end
  end
  
  def draw()
    @image.draw(@x, @y, 5)
  end
end


class Tile
  attr_accessor :x, :y, :z, :type, :name, :tile_number
  
  def initialize(window, image)
    @image = image
    @x = @y = @z = 0
    @type = nil
    @name = nil
    @tile_number = nil
  end
  
  def draw()
    @image.draw(@x, @y, @z)
  end
end


class Map
  attr_accessor :map_array, :first_fill_x, :first_fill_y, :second_fill_x, :second_fill_y
  
  def initialize(window)
    @map_array = create_3d_array( $MAPSIZE, $MAPSIZE, 3 )
	  @first_fill_selector = Gosu::Image.new(window, '../mainfiles/media/gui/editor/fill_selector1.png', false)
	  @second_fill_selector = Gosu::Image.new(window, '../mainfiles/media/gui/editor/fill_selector2.png', false)
    @first_fill_x = @first_fill_y = 0
	  @second_fill_x = @second_fill_y = 32
    @enemy_array = create_2d_array($MAPSIZE, $MAPSIZE)
    #Enemy Images ---
    @enemy_images = Hash.new(nil)
    search_directory('../mainfiles/media/enemies', '*_movement.png').each do |filename|
      @enemy_images[filename.split('/').last.split('_movement')[0]] = Gosu::Image::load_tiles(window, filename, 32, 32, false)[0]
    end
    # ---
  end
  
  def addtile(window, x, y, gui)
    if gui.current_tileset != nil then
      if gui.current_tileset[(((gui.current_tileset_page - 1) * 10) + gui.current_tile_selected)] != nil then
	      z = gui.get_tileset_layer(gui.tileset_type)
        if @map_array[z][y / 32][x / 32].class != Tile then
		      tile = Tile.new(window, gui.current_tileset[(((gui.current_tileset_page - 1) * 10) + gui.current_tile_selected)])
          tile.name = gui.tileset_name
          tile.tile_number = (((gui.current_tileset_page - 1) * 10) + gui.current_tile_selected)
          tile.x = x
          tile.y = y
          tile.z = z
		      tile.type = gui.tileset_type
          @map_array[z][y / 32][x / 32] = tile
		    elsif @map_array[z][y / 32][x / 32].name != gui.tileset_name or @map_array[z][y / 32][x / 32].tile_number != (((gui.current_tileset_page - 1) * 10) + gui.current_tile_selected) or @map_array[z][y / 32][x / 32].type != gui.tileset_type then
		      tile = Tile.new(window, gui.current_tileset[(((gui.current_tileset_page - 1) * 10) + gui.current_tile_selected)])
          tile.name = gui.tileset_name
          tile.tile_number = (((gui.current_tileset_page - 1) * 10) + gui.current_tile_selected)
          tile.x = x
          tile.y = y
          tile.z = z
		      tile.type = gui.tileset_type
          @map_array[z][y / 32][x / 32] = tile
		    end
      end
    end
  end
  
  def fillarea(window, gui, delete=false)
    x1 = @first_fill_x
	  y1 = @first_fill_y
	  x2 = @second_fill_x
	  y2 = @second_fill_y
	  x1 /= 32
	  x2 /= 32
	  y1 /= 32
	  y2 /= 32
    if (x2 - x1) + 1 < 0 or (y2 - y1) + 1 < 0 then
      puts "Are you trying to make it crash?"
      return nil
    else
	    iterate_array = create_2d_array((x2 - x1) + 1, (y2 - y1) + 1)
	    iterate_array.each_index do |y|
	      iterate_array[y].each_index do |x|
          if delete == true then
            removetile(x + x1, y + y1, gui.get_tileset_layer(gui.tileset_type))
          else
	          addtile(window, (x * 32)+(x1 * 32), (y * 32)+(y1 * 32), gui)
          end
	      end
	    end
    end
  end
  
  def update_fill_selectors()
    if ((@second_fill_x - @first_fill_x) + 1) < 1 or ((@second_fill_y - @first_fill_y) + 1) < 1 then
      temp_first_fill_x = @first_fill_x
      temp_first_fill_y = @first_fill_y
      @first_fill_x = @second_fill_x
      @first_fill_y = @second_fill_y
      @second_fill_x = temp_first_fill_x
      @second_fill_y = temp_first_fill_y
    end
  end
  
  def removetile(x, y, z)
    @map_array[z][y][x] = ' ' if @map_array[z][y][x] != ' '
  end
  
  def place_enemy(window, x, y, type = 'poison_spider')
    tile = Tile.new(window, @enemy_images[type])
    tile.type = type
    tile.x = x
    tile.y = y
    tile.z = 0.5
    @enemy_array[y/32][x/32] = tile
  end
  
  def remove_enemy(x, y)
    @enemy_array[y/32][x/32] = nil
  end
  
  def save_level( filename )
    return nil if filename == ''
    result = Marshal::dump(convert_map_to_strings( @map_array ))
    if not File.directory?("../core_files/levels/#{filename}") then
      Dir.mkdir("../core_files/levels/#{filename}")
    end
    create_file("../core_files/levels/#{filename}/level.dat", result)
    # Clear old enemies from the database
    Databases::Enemy.clear_enemies_from_map(filename)
    # Add all enemies to the database
    @enemy_array.each do |enemy_row|
      enemy_row.each do |enemy|
        if enemy.class == Tile then
          Databases::Enemy.add_enemy(enemy.type, filename, enemy.x, enemy.y)
        end
      end
    end
  end
  
  def convert_map_to_strings( array_3d )
    result = create_3d_array( $MAPSIZE, $MAPSIZE, 3 )
    array_3d.each_index do |z|
      array_3d[z].each_index do |y|
        array_3d[z][y].each_index do |x|
          if array_3d[z][y][x] != " " and array_3d[z][y][x] != "\n" then
            name = array_3d[z][y][x].name
            type = array_3d[z][y][x].type
            tile_number = array_3d[z][y][x].tile_number
            result[z][y][x] = "#{name}////#{type}////#{tile_number}"
          end
        end
      end
    end
    return result
  end
  
  def load_level( filename, window, gui )
    return nil if filename == ''
    if File.exists?("../core_files/levels/#{filename}/level.dat")
      @map_array = create_3d_array( $MAPSIZE, $MAPSIZE, 3 ) # Blank Screen
      @enemy_array = create_2d_array($MAPSIZE, $MAPSIZE)
      read_file = marshalfileread("../core_files/levels/#{filename}/level.dat")
      read_file.each_index do |z|
        read_file[z].each_index do |y|
          read_file[z][y].each_index do |x|
            if read_file[z][y][x] != ' ' and read_file[z][y][x] != "\n" and read_file[z][y][x] != '' then
              info_array = read_file[z][y][x].split('////')
              name = info_array[0]
              type = info_array[1]
              tile_number = (info_array[2]).to_i
              if type == 'floor' then
                index = 0
              elsif type == 'wall' then
                index = 1
              elsif type == 'light' then
                index = 2
              elsif type == 'misc' then
                index = 3
              end
              tileset_name_and_number = (((gui.tileset_array[index]).grep %r{^#{name}} )[0] )
              if tileset_name_and_number != nil then
                tile_sheet_index = (tileset_name_and_number.split('////')[1] ).to_i
                tileset = gui.preloaded_tilesets[tile_sheet_index]
                tile = Tile.new(window, tileset[tile_number])
                tile.x = (x * 32)
                tile.y = (y * 32)
                tile.name = name
                tile.type = type
                tile.tile_number = tile_number
                @map_array[z][y][x] = tile
              end
            end
          end
        end
      end
      # Load enemies from database
      enemy_array = Databases::Enemy.get_enemies_from_map(filename)
      enemy_array.each do |enemy|
        place_enemy(window, enemy[3], enemy[4], enemy[1])
      end
	  end
  end
  
  def draw(gui)
    if gui.current_tool == 'fill' then
	    @first_fill_selector.draw(@first_fill_x, @first_fill_y, 4)
	    @second_fill_selector.draw(@second_fill_x, @second_fill_y, 4)
	  end
    @enemy_array.each do |y|
      y.each do |x|
        x.draw() if x.class == Tile
      end
    end
    @map_array.each do |z|
      z.each do |y|
        y.each do |x|
          if x != ' ' and x != "\n" and x != nil then
            x.draw()
          end
        end
      end
	  end
  end
end


class Gui
  attr_accessor :current_tool, :current_tileset, :current_tile_selected, :current_tileset_page, :tileset_array, :tileset_type, :tileset_name
  attr_reader :preloaded_tilesets, :enemy_type_array
  
  def initialize(window)
    @sidebar = Gosu::Image.new(window, '../mainfiles/media/gui/editor/sidebar.png', false)
    @bottombar = Gosu::Image.new(window, '../mainfiles/media/gui/editor/bottombar.png', false)
    @gui_selector = Gosu::Image.new(window, '../mainfiles/media/gui/editor/gui_selector.png', false)
    @place_button = Gosu::Image.new(window, '../mainfiles/media/gui/editor/place_button.png', false)
	  @fill_button = Gosu::Image.new(window, '../mainfiles/media/gui/editor/fill_button.png', false)
    @save_button = Gosu::Image.new(window, '../mainfiles/media/gui/editor/save_button.png', false)
    @load_button = Gosu::Image.new(window, '../mainfiles/media/gui/editor/load_button.png', false)
    @enemy_button = Gosu::Image.new(window, '../mainfiles/media/gui/editor/enemy_button.png', false)
    @page_arrows = Gosu::Image.new(window, '../mainfiles/media/gui/editor/page_arrows.png', false)
	  @font1 = Gosu::Font.new(window, Gosu::default_font_name, 25)
    @font2 = Gosu::Font.new(window, Gosu::default_font_name, 19)
    @current_tool = 'place'
    @current_tile_selected = 0
    @selector_x = 16
    @selector_y = 752
    @tilesheet_x = @tile_selector_x = 1232
    @tilesheet_y = @tile_selector_y = 16
    @tileset_array = []
    @current_tileset = nil
    @tileset_type = nil
    @tileset_name = nil
    @preloaded_tilesets = []
    @tileset_array = grab_tilesets('../mainfiles/media/tilesets', window)
    change_tileset_by_string(get_first_tileset())
    @current_tileset_page = 1
    
    @enemy_type_array = get_enemy_types(window)
  end
  
  def get_enemy_types(window)
    result = []
    result << 0
    search_directory('../mainfiles/media/enemies', '*_movement.png').each do |filename|
      result << [filename.split('/').last.split('_movement')[0], Gosu::Image.new(window, filename, false)]
    end
    return result
  end
  
  def grab_tilesets(folder, window)  #returns an array of "dungeon////1"
    array = search_directory(folder, 'tileset_*')
    result = [[],[],[],[]]
    array.each do |e|
      a = e.split('tileset_')[1]
      type = a.split('_')[0]
      set = a.split('_')[1].split('.png')[0]
      filename = "/tileset_#{type}_#{set}.png"
      index = @preloaded_tilesets.count
      tileset = Gosu::Image.load_tiles(window, folder + filename, 32, 32, true)
      @preloaded_tilesets[index] = tileset
      if type == 'floor' then
        result[0] << "#{set}////#{index}"
      elsif type == 'wall' then
        result[1] << "#{set}////#{index}"
      elsif type == 'light' then
        result[2] << "#{set}////#{index}"
      elsif type == 'misc' then
        result[3] << "#{set}////#{index}"
      end
    end
    return result
  end
  
  def get_first_tileset()
    if @tileset_array[0].first != nil then
      @tileset_type = 'floor'
      @tileset_name = (@tileset_array[0].first).split('////')[0]
      return @tileset_array[0].first
    elsif @tileset_array[1].first != nil then
      @tileset_type = 'wall'
      @tileset_name = (@tileset_array[1].first).split('////')[0]
      return @tileset_array[1].first
    elsif @tileset_array[2].first != nil then
      @tileset_type = 'light'
      @tileset_name = (@tileset_array[2].first).split('////')[0]
      return @tileset_array[2].first
    elsif @tileset_array[3].first != nil then
      @tileset_type = 'misc'
      @tileset_name = (@tileset_array[3].first).split('////')[0]
      return @tileset_array[3].first
    else
      return nil
    end
  end
  
  def change_tileset(what_to_change, window)
    folder = '../mainfiles/media/tilesets/'
    if what_to_change == 'name' then
      if @tileset_name != nil then
        if @tileset_type == 'floor' then
          count = (@tileset_array[0].count - 1)
          current_index = 0
          index_info = ((@tileset_array[current_index]).grep %r{^#{@tileset_name}} )[0]
          index = @tileset_array[0].index(index_info)
        elsif @tileset_type == 'wall' then
          count = (@tileset_array[1].count - 1)
          current_index = 1
          index_info = ((@tileset_array[current_index]).grep %r{^#{@tileset_name}} )[0]
          index = @tileset_array[1].index(index_info)
        elsif @tileset_type == 'light' then
          count = (@tileset_array[2].count - 1)
          current_index = 2
          index_info = ((@tileset_array[current_index]).grep %r{^#{@tileset_name}} )[0]
          index = @tileset_array[2].index(index_info)
        elsif @tileset_type == 'misc' then
          count = (@tileset_array[3].count - 1)
          current_index = 3
          index_info = ((@tileset_array[current_index]).grep %r{^#{@tileset_name}} )[0]
          index = @tileset_array[3].index(index_info)
        else
          vputs "@tileset_type is weird: #{@tileset_type}"
        end
        if index < count then
          @tileset_name = (@tileset_array[current_index][index + 1]).split('////')[0]
        else
          @tileset_name = (@tileset_array[current_index][0]).split('////')[0]
        end
        tileset_index = ((((@tileset_array[current_index]).grep %r{^#{@tileset_name}} )[0] ).split('////')[1] ).to_i
        @current_tileset = @preloaded_tilesets[tileset_index]
      end
    elsif what_to_change == 'type' then
      if @tileset_type == 'floor' then
        @tileset_type = 'wall'
        current_index = 1
      elsif @tileset_type == 'wall' then
        @tileset_type = 'light'
        current_index = 2
      elsif @tileset_type == 'light' then
        @tileset_type = 'misc'
        current_index = 3
      elsif @tileset_type == 'misc' then
        @tileset_type = 'floor'
        current_index = 0
      else
        vputs "@tileset_type is weird: #{@tileset_type}"
      end
      if @tileset_array[current_index].empty? then
        @tileset_name = nil
        @current_tileset = nil
      else
        @tileset_name = (@tileset_array[current_index][0].to_s).split('////')[0]
        @current_tileset = @preloaded_tilesets[(((@tileset_array[current_index][0].to_s).split('////')[1]).to_i)]
      end
    else
      vputs 'what_to_change was given a weird value in change_tileset() in Gui'
    end
  end
  
  def draw_tileset_indicator()
    x = 1224
    y = 384
    if @tileset_name != nil then
      name = @tileset_name
      @font2.draw(name, x, y, 1, 1.0, 1.0, 0xffffffff)
    end 
    if @tileset_type != nil then
      type = @tileset_type
      @font2.draw(type, x, y + 20, 1, 1.0, 1.0, 0xffffffff)
    end
  end
  
  def get_tileset_layer( tile_type )
    if tile_type == 'floor' then
      return 0
    elsif tile_type == 'wall' then
      return 1
    elsif tile_type == 'light' then
      return 2
    elsif tile_type == 'misc' then
      return 3
    else
      vputs 'Trying to get tileset layer of unknown tileset. Error in get_tileset_layer() of Gui!'
      return 0
    end
  end
  
  def change_tileset_by_string( string ) #ex. "dungeon////1"
    index = (string.split('////')[1]).to_i
    @current_tileset = @preloaded_tilesets[index]
  end
  
  def change_tileset_page(integer)
    if integer == 0 then
      if @current_tileset_page > 1 then
        @current_tileset_page -= 1
      else
        @current_tileset_page = 10
      end
    elsif integer == 1 then
      if @current_tileset_page < 10 then
        @current_tileset_page += 1
      else
        @current_tileset_page = 1
      end
    end
  end
  
  def click(mousex, mousey, window, map)
    if mousey > 752 and mousey < 784 then
      if mousex > 16 and mousex < 48 then # Mouse over place tool
        @selector_x = 16
        @current_tool = 'place'
      elsif mousex > 96 and mousex < 128 then # Mouse over fill button
        @selector_x = 96
        @current_tool = 'fill'
      elsif mousex > 136 and mousex < 168 then # Mouse over save button
        if window.current_status == nil then
          window.current_status = 'saving'
          window.create_textfield('save')
        end
      elsif mousex > 176 and mousex < 208 then # Mouse over load button
        if window.current_status == nil then
          window.current_status = 'loading'
          window.create_textfield('load')
        end
      elsif mousex > 216 and mousex < 248 then # Mouse over enemy button
        @selector_x = 216
        @current_tool = 'enemy'
      elsif mousex > 256 and mousex < 320 then # Mouse over enemy selector
        if @enemy_type_array[0] == @enemy_type_array.count - 2 then
          @enemy_type_array[0] = 0
        else
          @enemy_type_array[0] += 1
        end
      end
    end
    if mousex > 1224 and mousex < 1288 then
      if mousey > 376 and mousey < 400 then # Mouse over tileset name
        change_tileset('name', window)
      elsif mousey > 400 and mousey < 424 then # Mouse over tileset type
        change_tileset('type', window)
      end
    end
    if mousex > @tilesheet_x and mousex < (@tilesheet_x + 32) then
      if  mousey > (@tilesheet_y + (32 * 0)) and mousey < (@tilesheet_y + (32 * 1)) then # Mouse over Tile 0
        @tile_selector_y = (@tilesheet_y + (32 * 0))
        @current_tile_selected = 0
      elsif mousey > (@tilesheet_y + (32 * 1)) and mousey < (@tilesheet_y + (32 * 2)) then # Mouse over Tile 1
        @tile_selector_y = (@tilesheet_y + (32 * 1))
        @current_tile_selected = 1
      elsif mousey > (@tilesheet_y + (32 * 2)) and mousey < (@tilesheet_y + (32 * 3)) then # Mouse over Tile 2
        @tile_selector_y = (@tilesheet_y + (32 * 2))
        @current_tile_selected = 2
      elsif mousey > (@tilesheet_y + (32 * 3)) and mousey < (@tilesheet_y + (32 * 4)) then # Mouse over Tile 3
        @tile_selector_y = (@tilesheet_y + (32 * 3))
        @current_tile_selected = 3
      elsif mousey > (@tilesheet_y + (32 * 4)) and mousey < (@tilesheet_y + (32 * 5)) then # Mouse over Tile 4
        @tile_selector_y = (@tilesheet_y + (32 * 4))
        @current_tile_selected = 4
      elsif mousey > (@tilesheet_y + (32 * 5)) and mousey < (@tilesheet_y + (32 * 6)) then # Mouse over Tile 5
        @tile_selector_y = (@tilesheet_y + (32 * 5))
        @current_tile_selected = 5
      elsif mousey > (@tilesheet_y + (32 * 6)) and mousey < (@tilesheet_y + (32 * 7)) then # Mouse over Tile 6
        @tile_selector_y = (@tilesheet_y + (32 * 6))
        @current_tile_selected = 6
      elsif mousey > (@tilesheet_y + (32 * 7)) and mousey < (@tilesheet_y + (32 * 8)) then # Mouse over Tile 7
        @tile_selector_y = (@tilesheet_y + (32 * 7))
        @current_tile_selected = 7
      elsif mousey > (@tilesheet_y + (32 * 8)) and mousey < (@tilesheet_y + (32 * 9)) then # Mouse over Tile 8
        @tile_selector_y = (@tilesheet_y + (32 * 8))
        @current_tile_selected = 8
      elsif mousey > (@tilesheet_y + (32 * 9)) and mousey < (@tilesheet_y + (32 * 10)) then # Mouse over Tile 9
        @tile_selector_y = (@tilesheet_y + (32 * 9))
        @current_tile_selected = 9
      end
    end
    if mousex > (@tilesheet_x - 16) and mousex < (@tilesheet_x + 16) and mousey > (@tilesheet_y + 320) and mousey < (@tilesheet_y + 352) then # Left Arrow
      change_tileset_page(0)
    elsif mousex > (@tilesheet_x + 16) and mousex < (@tilesheet_x + 48) and mousey > (@tilesheet_y + 320) and mousey < (@tilesheet_y + 352) then # Right Arrow
      change_tileset_page(1)
    end
  end
  
  def update()
  end
  
  def draw_tileset_page()
    if @current_tileset != nil then
      first_tile = ((@current_tileset_page - 1) * 10)
	    10.times do |i|
	      if @current_tileset[first_tile + i] != nil then
          @current_tileset[first_tile + i].draw(@tilesheet_x, @tilesheet_y + (32 * i), 1)
        end
	    end
    end
  end
  
  def draw(window)
    @sidebar.draw(1216, 0,0)
    @bottombar.draw(0, 736, 0)
    @place_button.draw(16, 752, 1)
	  @fill_button.draw(96, 752, 1)
    @save_button.draw(136, 752, 1)
    @load_button.draw(176, 752, 1)
    @enemy_button.draw(216, 752, 1)
    @gui_selector.draw(@selector_x, @selector_y, 2)
    @gui_selector.draw(@tile_selector_x, @tile_selector_y, 2)
    draw_tileset_page()
    @page_arrows.draw(@tilesheet_x - 16, @tilesheet_y + 320, 1)
    @font1.draw(@current_tileset_page.to_s, @tilesheet_x + 5, @tilesheet_y + 324, 2, 1.0, 1.0, 0xffffffff)
    @font2.draw(@enemy_type_array[@enemy_type_array[0] + 1][0].to_s, 256, 760, 2, 1.0, 1.0, 0xffffffff)
    draw_tileset_indicator()
  end
end


class TextField < Gosu::TextInput
  # Some constants that define our appearance.
  INACTIVE_COLOR  = 0xcc666666
  ACTIVE_COLOR    = 0xccff6666
  SELECTION_COLOR = 0xcc0000ff
  CARET_COLOR     = 0xffffffff
  PADDING = 5
  
  attr_reader :x, :y
  
  def initialize(window, font, x, y)
    # TextInput's constructor doesn't expect any arguments.
    super()
    @window, @font, @x, @y = window, font, x, y
    # Start with a self-explanatory text in each field.
    self.text = ''
  end
  
  # Example filter method. You can truncate the text to employ a length limit (watch out
  # with Ruby 1.8 and UTF-8!), limit the text to certain characters etc.
  def filter text
    text#.upcase
  end
  
  def draw
    # Depending on whether this is the currently selected input or not, change the
    # background's color.
    if @window.text_input == self then
      background_color = ACTIVE_COLOR
    else
      background_color = INACTIVE_COLOR
    end
    @window.draw_quad(x - PADDING,         y - PADDING,          background_color,
                      x + width + PADDING, y - PADDING,          background_color,
                      x - PADDING,         y + height + PADDING, background_color,
                      x + width + PADDING, y + height + PADDING, background_color, 100)
    # Calculate the position of the caret and the selection start.
    pos_x = x + @font.text_width(self.text[0...self.caret_pos])
    sel_x = x + @font.text_width(self.text[0...self.selection_start])
    # Draw the selection background, if any; if not, sel_x and pos_x will be
    # the same value, making this quad empty.
    @window.draw_quad(sel_x, y,          SELECTION_COLOR,
                      pos_x, y,          SELECTION_COLOR,
                      sel_x, y + height, SELECTION_COLOR,
                      pos_x, y + height, SELECTION_COLOR, 100)

    # Draw the caret; again, only if this is the currently selected field.
    if @window.text_input == self then
      @window.draw_line(pos_x, y,          CARET_COLOR,
                        pos_x, y + height, CARET_COLOR, 100)
    end
    # Finally, draw the text itself!
    @font.draw(self.text, x, y, 100)
  end
  # This text field grows with the text that's being entered.
  # (Usually one would use clip_to and scroll around on the text field.)
  def width
    @font.text_width(self.text)
  end
  
  def height
    @font.height
  end

  # Hit-test for selecting a text field with the mouse.
  def under_point?(mouse_x, mouse_y)
    mouse_x > x - PADDING and mouse_x < x + width + PADDING and
      mouse_y > y - PADDING and mouse_y < y + height + PADDING
  end
  
  # Tries to move the caret to the position specifies by mouse_x
  def move_caret(mouse_x)
    # Test character by character
    1.upto(self.text.length) do |i|
      if mouse_x < x + @font.text_width(text[0...i]) then
        self.caret_pos = self.selection_start = i - 1;
        return
      end
    end
    # Default case: user must have clicked the right edge
    self.caret_pos = self.selection_start = self.text.length
  end
end


window = GameWindow.new.show
