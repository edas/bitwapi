# Most of the code here originated from the the file /lib/bitwarden.rb
# in the 'bitwarden-ruby' project, and was modified since then.
#
# The original code is Copyright (c) 2017 joshua stein <jcs@jcs.org> 
# and licensed under the ISC license
#
# https://github.com/jcs/bitwarden-ruby/blob/master/LICENSE
# https://github.com/jcs/bitwarden-ruby/blob/ba61496b1cc10671ce51c93415026438af0d259f/lib/bitwarden.rb

require "pbkdf2"
require "openssl"

module Bitwapi

  class Crypto

    AESCBC256_B64                     = 0
    AESCBC128_HMACSHA256_B64          = 1
    AESCBC256_HMACSHA256_B64          = 2
    RSA2048_OAEPSHA256_B64            = 3
    RSA2048_OAEPSHA1_B64              = 4
    RSA2048_OAEPSHA256_HMACSHA256_B64 = 5
    RSA2048_OAEPSHA1_HMACSHA256_B64   = 6

    PBKDF2_SHA256 = 0
    DEFAULT_ITERATIONS = {
      PBKDF2_SHA256 => 100_000
    }.freeze
    ITERATION_RANGES = {
      PBKDF2_SHA256 => 5_000..1_000_000
    }.freeze

    def make_master_key(password, email, kdf_type, kdf_iterations)
      make_key(password, email.downcase, kdf_type, kdf_iterations)
    end

    def make_key(password, salt, kdf_type, kdf_iterations)
      case kdf_type
      when PBKDF2_SHA256
        range = ITERATION_RANGES[kdf_type]
        unless range.include?(kdf_iterations)
          raise "PBKDF2 iterations must be between #{range}"
        end

        PBKDF2.new(:password => password, :salt => salt,
          :iterations => kdf_iterations, :hash_function => OpenSSL::Digest::SHA256,
          :key_length => (256/8)).bin_string
      else
        raise "unknown kdf type #{kdf_type.inspect}"
      end
    end

    def hash_password(password, salt, kdf_type, kdf_iterations)
      key = make_master_key(password, salt, kdf_type, kdf_iterations)
      Base64.strict_encode64(PBKDF2.new(:password => key, :salt => password,
        :iterations => 1, :key_length => 256/8,
        :hash_function => OpenSSL::Digest::SHA256).bin_string)
    end

    def make_enc_key(key)
      pt = OpenSSL::Random.random_bytes(64)
      iv = OpenSSL::Random.random_bytes(16)

      cipher = OpenSSL::Cipher.new "AES-256-CBC"
      cipher.encrypt
      cipher.key = key
      cipher.iv = iv
      ct = cipher.update(pt)
      ct << cipher.final

      compose_cipher_string(AESCBC256_B64, iv, ct)
    end

    def encrypt(pt, key, macKey=nil)
      key, macKey = split_key(key) if macKey.nil?

      iv = OpenSSL::Random.random_bytes(16)

      cipher = OpenSSL::Cipher.new "AES-256-CBC"
      cipher.encrypt
      cipher.key = key
      cipher.iv = iv
      ct = cipher.update(pt)
      ct << cipher.final

      mac = OpenSSL::HMAC.digest(OpenSSL::Digest.new("SHA256"), macKey, iv + ct)

      compose_cipher_string(AESCBC256_HMACSHA256_B64, iv, ct, mac)
    end

    def macs_equal(mac_key, mac1, mac2)
      hmac1 = OpenSSL::HMAC.digest(OpenSSL::Digest.new("SHA256"), mac_key, mac1)
      hmac2 = OpenSSL::HMAC.digest(OpenSSL::Digest.new("SHA256"), mac_key, mac2)
      return hmac1 == hmac2
    end

    def decrypt(str, key, mac_key=nil)
      key, mac_key = split_key(key) if mac_key.nil?

      type, iv, ct, mac = decompose_cipher_string(str)

      case type
      when AESCBC256_B64, AESCBC256_HMACSHA256_B64

        if type == AESCBC256_HMACSHA256_B64
          cmac = OpenSSL::HMAC.digest(OpenSSL::Digest.new("SHA256"), mac_key, iv + ct)
          if !macs_equal(mac_key, mac, cmac)
            raise "invalid mac"
          end
        end

        cipher = OpenSSL::Cipher.new "AES-256-CBC"
        cipher.decrypt
        cipher.iv = iv
        cipher.key = key
        pt = cipher.update(ct)
        pt << cipher.final
        return pt

      else
        raise "TODO implement #{c.type}"
      end
    end

    def decrypted_key(enc_key, email, password, kdf_type, kdf_iterations)
      master_key = make_master_key(password, email, kdf_type, kdf_iterations)
      decrypt(enc_key, master_key, nil)
    end

    def split_key(key)
      [key[0,32], key[32,32]]
    end

    def compose_cipher_string(type, iv, ct, mac = nil)
      [ 
        type.to_s + "." + Base64.strict_encode64(iv), 
        Base64.strict_encode64(ct), 
        mac ? Base64.strict_encode64(mac) : nil,
      ].reject{|p| !p }.join("|")
    end

    def decompose_cipher_string(str)
      if !(m = str.to_s.match(/\A(\d)\.([^|]+)\|(.+)\z/))
        raise "Invalid CipherString: #{str.inspect}"
      end
      type = m[1].to_i
      iv = m[2]
      ct, mac = m[3].split("|", 2)
      [type, Base64.decode64(iv), Base64.decode64(ct), mac ? Base64.decode64(mac) : nil]
    end

  end

end
