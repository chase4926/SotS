# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{gosu}
  s.version = "0.7.41"
  s.platform = %q{x86-mingw32}

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Julian Raschke"]
  s.date = %q{2011-12-17}
  s.description = %q{  2D game development library.

  Gosu features easy to use and game-friendly interfaces to 2D graphics
  and text (accelerated by 3D hardware), sound samples and music as well as
  keyboard, mouse and gamepad/joystick input.

  Also includes demos for integration with RMagick, Chipmunk and OpenGL.
}
  s.email = %q{julian@raschke.de}
  s.homepage = %q{http://www.libgosu.org/}
  s.rdoc_options = ["README.txt", "COPYING", "reference/gosu.rb", "reference/*.rdoc", "--title", "Gosu", "--main", "README.txt"]
  s.require_paths = ["lib"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.8.2")
  s.rubygems_version = %q{1.7.2}
  s.summary = %q{2D game development library.}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
