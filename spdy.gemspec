# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "spdy/version"

Gem::Specification.new do |s|
  s.name        = "spdy"
  s.version     = Spdy::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Ilya Grigorik"]
  s.email       = ["ilya@igvita.com"]
  s.homepage    = ""
  s.summary     = "spdy"
  s.description = s.summary

  s.rubyforge_project = "spdy"

  s.add_development_dependency "rspec"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
