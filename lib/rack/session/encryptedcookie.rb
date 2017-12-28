#
# Rack::Session::EncryptedCookie - Encrypted session middleware for Rack
#
# Copyright (C) 2013 - 2017 Tim Hentenaar. All Rights Reserved.
#
# Licensed under the Simplified BSD License.
# See the LICENSE file for details.
#

require 'rack/request'
require 'rack/utils'
require 'openssl'

module Rack
module Session
  class EncryptedCookie
    NOT_FOUND = [ 404, {}, [ 'Not found' ]].freeze

    # @param [Hash] opts Session options
    # @option opts [String]  :cookie_name Cookie name
    # @option opts [String]  :domain      Domain for the cookie
    # @option opts [Boolean] :http_only   HttpOnly for the cookie
    # @option opts [Integer] :expires     Cookie expiry (in seconds)
    # @option opts [String]  :cipher      OpenSSL cipher to use
    # @option opts [String]  :salt        Salt for the IV
    # @optons opts [Integer] :rounds      Number of salting rounds
    # @option opts [String]  :key         Encryption key for the data
    # @option opts [Integer] :tag_len     Tag length (for GCM/CCM ciphers)
    def initialize(app, opts={})
      @app  = app
      @hash = {}
      @opts = {
        cookie_name: 'rack.session',
        domain:      nil,
        http_only:   false,
        expires:     (15 * 60),
        cipher:      'aes-256-cbc',
        salt:        '3@bG>B@J5vy-FeXJ',
        rounds:      2000,
        key:         'r`*BqnG:c^;AL{k97=KYN!#',
        tag_len:     16
      }.merge(opts)
    end

    def call(env)
      dup.call!(env)
    end

    def call!(env)
      @cb = env['async.callback']
      env['async.callback'] = method(:save_session) if @cb
      env['rack.session']   = self
      load_session(env)

      if @app
        @cb ? @app.call(env) : save_session(@app.call(env))
      else
        @cb ? @cb.call(NOT_FOUND) : NOT_FOUND
      end
    end

    def method_missing(method, *args, &block)
      if @hash.respond_to?(method)
        @hash.send(method, *args, &block)
      else
        raise ArgumentError.new("Method `#{method}` doesn't exist.")
      end
    end

    private

    # Load the sesssion data from the cookie
    # @return [Hash, nil] Session data
    def load_session(env)
      r = Rack::Request.new(env)
      cookie = r.cookies[@opts[:cookie_name]]
      return if cookie.nil?
      @hash = Marshal.load(cipher(:decrypt, cookie)) rescue {}
    end

    # Add our cookie to the response
    #
    # @param [Array] r Upstream Rack response
    # @return [Array] Rack response + our cookie
    def save_session(r)
      return r if !r.is_a?(Array) || (r.is_a?(Array) && r[0] == -1)

      unless @hash.empty? || @opts[:domain].nil?
        data = cipher(:encrypt, Marshal.dump(@hash)) rescue nil
        c = {
          value:  data,
          domain: @opts[:domain],
          path:   '/',
        }

        c[:httponly] = @opts[:http_only] === true
        if @opts.has_key?(:expires)
          c[:expires] = Time.at(Time.now + @opts[:expires])
        end

        r[1]['Set-Cookie'] = Rack::Utils.add_cookie_to_header(
          r[1]['Set-Cookie'], @opts[:cookie_name], c
        ) unless data.nil?
      end

      @cb.call(r) if @cb
      r
    end

    # Warn the user that en/de-cryption failed
    # @param [String] e Exception message
    # @return nil
    def cipher_failed(e='<no message>')
        warn (<<-XXX.gsub(/^\s*/, ''))
        SECURITY WARNING: Session cipher failed: #{e}
        XXX
        return nil
    end

    # Handle en/de-cryption
    # @param [Symbol] :mode :encrypt or :decrypt
    # @param [String] :str  Data to en/de-crypt
    # @return [String, nil] Encrypted data
    def cipher(mode, str)
      return nil if @opts[:key].nil? || str.nil?
      begin
        cipher = OpenSSL::Cipher.new(@opts[:cipher])
        cipher.send(mode)
      rescue
        return cipher_failed($!.message)
      end

      # Set the key and IV
      if @opts[:salt].nil?
        cipher.key = @opts[:key]
      else
        cipher.key = OpenSSL::PKCS5.pbkdf2_hmac_sha1(
          @opts[:key], @opts[:salt],
          @opts[:rounds], cipher.key_len
        )
      end

      # Setup the auth data for GCM/CCM
      if cipher.name.match(%r{/[CG]CM$/i})
        cipher.auth_data = ''
        cipher.tag_len   = @opts[:tag_len]
      end

      iv   = cipher.random_iv
      xstr = str

      if mode == :decrypt
        str = str.unpack('m').first

        # Set the tag for GCM/CCM
        if cipher.name.match(%r{/[CG]CM$/i})
          cipher.auth_tag = str.slice!(0, cipher.tag_len).unpack('C*')
        end

        # Extract the iv
        iv_len   = iv.length
        str_b,iv = Array[str[0 ... iv_len << 1].unpack('C*')].transpose.
                   partition.with_index { |x,i| (i&1).zero? }
        iv.flatten! ; str_b.flatten!

        # Set the IV and buffer
        iv   = iv.pack('C*')
        xstr = str_b.pack('C*') + str[iv_len << 1 ... str.length]
      end

      # Call the cipher
      r         = nil
      cipher.iv = iv
      begin
        r = cipher.update(xstr) + cipher.final
        if mode == :encrypt
          d = r.bytes.zip(iv.bytes).flatten.compact
          if cipher.name.match(%r{/[CG]CM$/i})
            d = cipher.tag.bytes + d.bytes
          end
          r = [d.pack('C*')].pack('m').chomp
        end
      rescue OpenSSL::Cipher::CipherError
        return cipher_failed($!.message)
      end
      r
    end
  end
end
end

# vi:set ts=2 sw=2 et sta:
