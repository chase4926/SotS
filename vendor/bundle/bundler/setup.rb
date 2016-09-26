path = File.expand_path('..', __FILE__)
$:.unshift File.expand_path("#{path}/../ruby/1.9.1/gems/gosu-0.7.41-x86-mingw32/lib")
$:.unshift File.expand_path("#{path}/../ruby/1.9.1/gems/i18n-0.6.0/lib")
$:.unshift File.expand_path("#{path}/../ruby/1.9.1/gems/mime-types-1.17.2/lib")
$:.unshift File.expand_path("#{path}/../ruby/1.9.1/gems/polyglot-0.3.3/lib")
$:.unshift File.expand_path("#{path}/../ruby/1.9.1/gems/treetop-1.4.10/lib")
$:.unshift File.expand_path("#{path}/../ruby/1.9.1/gems/mail-2.3.0/lib")
$:.unshift File.expand_path("#{path}/../ruby/1.9.1/gems/pony-1.4/lib")
$:.unshift File.expand_path("#{path}/../ruby/1.9.1/gems/sqlite3-1.3.5-x86-mingw32/lib")
require 'gosu'
require 'sqlite3'
require 'pony'
