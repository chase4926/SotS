=begin
  This renders all npc text into an image file
=end

ARGV.clear()
Dir.chdir(File.dirname(__FILE__))

require_relative '../bin/lib/lib.rb'
require 'rubygems'
require_relative '../vendor/bundle/bundler/setup'
include Gosu


class GameWindow < Gosu::Window
  def initialize()
    super(2, 2, false) # Windowed
    self.caption = 'Text Renderer'
    render_text()
  end # End GameWindow Initialize
  
  def render_text()
    search_directory('../core_files/npc_scripts', '*.yml').each do |config_file|
      config_file = config_file.split('/').last().split('.yml')[0]
      config = YAML::load(File.open("../core_files/npc_scripts/#{config_file}.yml", 'r'))
      Image.from_text(self, config['message'], "Pet Me 64", 8, 1, 128, :center).save("../mainfiles/media/npc_text/#{config_file}.png")
    end
  end
  
  def update()
    self.close()
  end
end


window = GameWindow.new().show()
