Gem::Specification.new do |gem|
  gem.name        = 'rack-session-encryption'
  gem.version     = '0.1.0'
  gem.author      = 'Tim Hentenaar'
  gem.email       = 'tim.hentenaar@gmail.com'
  gem.homepage    = 'https://github.com/thentenaar/rack-session-encryption'
  gem.summary     = 'Encrypted sessions for Rack'
  gem.description = <<__XXX__
  Rack middleware that transparently encrypts/decrypts session data
__XXX__

  gem.files = Dir['lib/**/*','README*', 'LICENSE']
  gem.add_dependency 'rack'
end

# vi:set ts=2 sw=2 expandtab sta:
