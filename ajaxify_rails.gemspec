# -*- encoding: utf-8 -*-
require File.expand_path('../lib/ajaxify_rails/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Nico Ritsche"]
  gem.email         = ["ncrdevmail@gmail.com"]
  gem.description   = %q{Rails gem for automatically turning internal links into ajax links that load content without a full page reload.
                         Uses the html5 history interface for changing the url and making the browser's back and forward buttons working with ajax.
                         Falls back to a hash based approach for browsers without the history interface (like Internet Explorer).
                         Transparently handles redirects and supports flash messages and page titles. Requires Ruby 1.9 and the asset pipeline.}
  gem.summary       = %q{Rails gem for automatically turning internal links into ajax links that load content without a full page reload.}
  gem.homepage      = "https://github.com/ncri/ajaxify_rails"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "ajaxify_rails"
  gem.require_paths = ["lib"]
  gem.version       = AjaxifyRails::VERSION

  gem.add_dependency 'rails', '>= 3.1.0'
end
