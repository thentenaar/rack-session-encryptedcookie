rack-session-encryptedcookie
============================

[![Travis CI Status](https://secure.travis-ci.org/thentenaar/rack-session-encryptedcookie.svg?branch=master)](https://travis-ci.org/thentenaar/rack-session-encryptedcookie)

Rack session handling middleware that serializes the session data into
an encrypted cookie; that's also async-aware.

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

Installation
============

    gem install rack-session-encryptedcookie

Usage
=====

Just add something like this to your _config.ru_:

```ruby
require 'rack/session/encryptedcookie'

use Rack::Session::EncryptedCookie domain: 'domain.name', salt: 'salthere', key: 'my_secret'
```

... and you can access the session hash via ``env['rack.session']`` per
usual.

The full list of options is:

| Option          | Description                                      |
| --------------- | ------------------------------------------------ |
| ``cookie_name`` | Cookie name (default: 'rack.session')            |
| ``domain``      | Domain for the cookie (mandatory)                |
| ``http_only``   | HttpOnly for the cookie                          |
| ``expires``     | Cookie expiry (in seconds, optional)             |
| ``cipher``      | OpenSSL cipher to use (default: aes-256-cbc)     |
| ``salt``        | Salt for the IV (password-derrived key)          |
| ``rounds``      | Number of salting rounds (password-derrived key) |
| ``key``         | Encryption key / password for the cookie         |
| ``tag_len``     | Tag length (for GCM/CCM ciphers, optional)       |

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
cipher: 'aes-256-cbc', # The cipher algorithm to use (defaults to aes-256-cbc)
key:    your_key_here, # Your pre-generated key
```

Examples:
```ruby
# Using the default cipher
use Rack::Session::EncryptedCookie, key: your_key

# Using the specified cipher
use Rack::Session::EncryptedCookie, cipher: your_cipher, key: your_key
```

Using a password-derived key
=============================

You can derive a key by specifying the following options:
```ruby
cipher  'aes-256-cbc', # The cipher algorithm to use (default aes-256-cbc)
salt    'salthere',    # Salt to use for key generation
rounds: 2000,          # Number of cipher rounds for key generation (default: 2000)
key:    'yoursecret',  # A password from which to generate the key
```

``crypto_key`` and ``salt`` must be specified in order to enable encryption.
All other options have defaults available.

Example:
```ruby
use Rack::Session::EncryptedCookie, salt: 'salthere', crypto_key: 'my_secret'
```

