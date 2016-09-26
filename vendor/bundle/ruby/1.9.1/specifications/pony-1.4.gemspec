# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{pony}
  s.version = "1.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Adam Wiggins", "maint: Ben Prew"]
  s.date = %q{2011-11-29}
  s.description = %q{Send email in one command: Pony.mail(:to => 'someone@example.com', :body => 'hello')}
  s.email = %q{ben.prew@gmail.com}
  s.homepage = %q{http://github.com/benprew/pony}
  s.rdoc_options = ["--inline-source", "--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{pony}
  s.rubygems_version = %q{1.7.2}
  s.summary = %q{Send email in one command: Pony.mail(:to => 'someone@example.com', :body => 'hello')}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<mail>, ["> 2.0"])
      s.add_development_dependency(%q<rspec>, [">= 2.0.0"])
    else
      s.add_dependency(%q<mail>, ["> 2.0"])
      s.add_dependency(%q<rspec>, [">= 2.0.0"])
    end
  else
    s.add_dependency(%q<mail>, ["> 2.0"])
    s.add_dependency(%q<rspec>, [">= 2.0.0"])
  end
end
