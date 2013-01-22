rack-session-encryption
======================

Encrypted session data for rack, with either a password-based key, or a pre-generated key.

This is probably not the **most** secure solution, but it's better than storing your session
data in a cookie as clear text. That being said, it's _much_ more secure to use a
pre-generated key with this module than a password-derived key, but the latter is
provided as a convenience option.
 
If you have strict security requirements, you really shouldn't be storing sensitive data in
the session.

Licensing
=========

This software is licensed under the [Simplified BSD License](http://en.wikipedia.org/wiki/BSD_licenses#2-clause_license_.28.22Simplified_BSD_License.22_or_.22FreeBSD_License.22.29) as described in the LICENSE file.

Requirements
============

* rack
* openssl

Installation
============

    gem install rack-session-encryption

Usage
=====

Just add something like this to your _config.ru_, after your usual _Rack::Session_ middleware:

```ruby
require 'rack/session/encryption'

use Rack::Session::Cookie
use Rack::Session::Encryption, :salt => 'salthere', :crypto_key => 'my_secret'
```

***NOTE***: If you change the session key used by rack (e.g. by passing a ``:key`` option to ``Rack::Session::Cookie``),
you must provide the same key to ``Rack::Session::Encryption`` via the ``:key`` option.

Interaction with Sinatra
========================

In some cases, you may have to toggle Sinatra's ``:sessions`` setting to get it to interoperate with this middleware.

Example
```ruby
class X < Sinatra::Base
  set :sessions, true
end
```

Generating your own Key
=======================

You can generate a key using something like:
```ruby
SecureRandom.random_bytes(key_size_in_bytes)
```
or anything else, as long as the key is the proper size for the cipher.

Using a pre-generated Key
=========================

To use a pre-generated key, you must specify the following options:
```ruby
:cipher     => 'aes-256-cbc', # The cipher algorithm to use (defaults to aes-256-cbc)
:crypto_key => your_key_here, # Your pre-generated key
```

Examples:
```ruby
# Using the default cipher
use Rack::Session::Encryption, :crypto_key => your_key

# Using the specified cipher
use Rack::Session::Encryption, :cipher => your_cipher, :crypto_key => your_key
```

Using a password-derived key
=============================

You can derive a key by specifying the following options:
```ruby
:cipher     => 'aes-256-cbc', # The cipher algorithm to use (default aes-256-cbc)
:salt       => 'salthere',    # Salt to use for key generation
:rounds     => 2000,          # Number of cipher rounds for key generation (default: 2000)
:crypto_key => 'yoursecret',  # A password from which to generate the key
```

``:crypto_key`` and ``:salt`` must be specified in order to enable encryption.
All other options have defaults available.

Example:
```ruby
use Rack::Session::Encryption, :salt => 'salthere', :crypto_key => 'my_secret'
```

