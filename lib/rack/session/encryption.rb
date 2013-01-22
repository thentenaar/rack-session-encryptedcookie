#
# Rack::Session::Encryption - Transparent encryption for Rack sessions
#
# Copyright (C) 2013 Tim Hentenaar. All Rights Reserved.
#
# Licensed under the Simplified BSD License. 
# See the LICENSE file for details.
#

require 'openssl'

module Rack
module Session
  class Encryption
    def initialize(app,options={})
      @app  = app
      @opts = {
        :key        => 'rack.session',
        :data_key   => :edat,
        :cipher     => 'aes-256-cbc',
        :salt       => nil,
        :rounds     => 2000,
        :crypto_key => nil
      }

      @opts.merge!(options)
      @opts[:rounds] = @opts[:rounds].to_i || 2000
      @crypto = @opts[:crypto_key].nil? ? false : true
    end

    def call(env)
      dup._call(env)
    end

    def _call(env)
      session = env[@opts[:key]]

      # Decrypt the session data
      unless session.nil? || session.empty?
        hash = ::Marshal.load(cipher(:decrypt,session.delete(@opts[:data_key]).unpack('m').first)) rescue nil
        unless hash.nil? || hash.empty?
          # Update the session hash
          session.clear 
          session.update(hash)
          session.id = hash['session_id']
        end
      end

      # Pass it on
      response = @app.call(env)

      # Encrypt the session data
      unless session.nil? || session.empty?
        sid  = session[:session_id]
        data = [cipher(:encrypt,::Marshal.dump(session.to_hash))].pack('m') rescue nil
        
        unless data.nil?
          session.clear ; session[@opts[:data_key]] = data
          session[:session_id] = sid unless sid.nil?
        end
      end

      response
    end

    private
    def cipher(mode,str)
      return nil unless @crypto && !str.nil?

      # Get our cipher
      begin
        cipher = OpenSSL::Cipher::Cipher.new(@opts[:cipher])
        cipher.send(mode)
      rescue
        warn (<<-XXX).gsub(/^\s*/,'')
        SECURITY WARNING: Session encryption has been disabled because: #{$!.message}
        XXX
        @crypto = false
        return nil
      end

      # Set our key and IV
      cipher.key = @opts[:salt].nil? ? @opts[:crypto_key] : OpenSSL::PKCS5.pbkdf2_hmac_sha1(@opts[:key],@opts[:salt],@opts[:rounds],cipher.key_len)
      iv         = cipher.random_iv
      xstr       = str

      if mode == :decrypt
        # Extract the IV
        iv_len    = iv.length
        str_b,iv  = Array[str[0...iv_len<<1].unpack('C*')].transpose.partition.with_index { |x,i| (i&1).zero? }
        iv.flatten! ; str_b.flatten!

        # Set the IV and buffer
        iv   = iv.pack('C*')
        xstr = str_b.pack('C*') + str[iv_len<<1...str.length]
      end

      # Otherwise, use the random IV
      cipher.iv = iv

      # Get the result
      result = nil
      begin
        result = cipher.update(xstr) + cipher.final
        result = result.bytes.to_a.zip(iv.bytes.to_a).flatten.compact.pack('C*') if mode == :encrypt
      rescue OpenSSL::Cipher::CipherError
        warn (<<-XXX).gsub(/^\s*/,'')
        SECURITY WARNING: Session encryption has been disabled because: #{$!.message}
        XXX
        @crypto = false
        return nil
      end

      return result
    end
  end
end
end

# vi:set ts=2 sw=2 expandtab sta:
