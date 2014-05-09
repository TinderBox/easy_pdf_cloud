# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'easy_pdf_cloud/version'

Gem::Specification.new do |gem|
  gem.name          = "pdf_cloud"
  gem.version       = EasyPdfCloud::VERSION
  gem.authors       = ["Joe Heth"]
  gem.email         = ["joeheth@gmail.com"]
  gem.description   = %q{Simplified access to the easypdfcloud.com RESTful API}
  gem.summary       = %q{Document conversion using easypdfcloud.com}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_runtime_dependency "oauth2"
end
