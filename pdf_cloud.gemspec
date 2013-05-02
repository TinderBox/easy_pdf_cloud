# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pdf_cloud/version'

Gem::Specification.new do |gem|
  gem.name          = "pdf_cloud"
  gem.version       = PdfCloud::VERSION
  gem.authors       = ["Joe Heth"]
  gem.email         = ["joeheth@gmail.com"]
  gem.description   = %q{Simplified access to the pdf-cloud.com RESTful API}
  gem.summary       = %q{Uses oauth2 gem to access the pdf-cloud API}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_runtime_dependency "oauth2", '>= 0.9.1'
end
