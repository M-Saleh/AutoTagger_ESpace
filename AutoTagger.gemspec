# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "AutoTagger/version"

Gem::Specification.new do |s|
  s.name        = "AutoTagger"
  s.version     = AutoTagger::VERSION
  s.authors     = ["Mahmoud Ismail"]
  s.email       = ["mahmoudahmedismail@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{TODO: Write a gem summary}
  s.description = %q{TODO: Write a gem description}

  s.rubyforge_project = "AutoTagger"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  s.add_runtime_dependency "eventmachine"
  s.add_runtime_dependency "em-http-request"
  s.add_runtime_dependency "mysql2"
  s.add_runtime_dependency "sinatra"
  s.add_runtime_dependency  "async_sinatra"
  s.add_runtime_dependency "thin"
  s.add_runtime_dependency "rsolr"
  s.add_runtime_dependency "nokogiri"
  s.add_runtime_dependency "beanstalk-client"
  s.add_runtime_dependency "yard"
end
