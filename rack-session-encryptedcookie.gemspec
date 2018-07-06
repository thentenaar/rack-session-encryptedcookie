Gem::Specification.new do |gem|
  gem.name        = 'rack-session-encryptedcookie'
  gem.version     = '0.2.7'
  gem.author      = 'Tim Hentenaar'
  gem.email       = 'tim.hentenaar@gmail.com'
  gem.license     = 'BSD-2-Clause'
  gem.homepage    = 'https://github.com/thentenaar/rack-session-encryptedcookie'
  gem.summary     = 'Encrypted session middleware for Rack'
  gem.description = <<__XXX__
  Rack middleware that persists session data in an encrypted cookie
__XXX__

  gem.files = Dir['lib/**/*','README*', 'LICENSE']
  gem.add_development_dependency 'rake', '>= 12.0'
  gem.add_development_dependency 'rspec', '>= 3.5'
  gem.add_runtime_dependency 'rack', '>= 2.0'
end

# vi:set ts=2 sw=2 et sta:
