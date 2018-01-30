require "json"

module Bitwapi

  class Vault

    def self.read_from_file(file, options={})
      new( JSON.parse(File.read(file), symbolize_names: true), options )
    end

    def initialize(data, password:nil)
      @data = data
      @crypto = Crypto.new
      unlock!(password) if password
    end

    def unlock!(password)
      email = @data[:Profile][:Email]
      @key = @crypto.decrypted_key(@data[:Profile][:Key], email, password)
      true
    end

    def lock!
      @key = nil
    end

    def cipher(id)
      cipher = @data[:Ciphers].find { |cipher| cipher[:Id] == id }
      cipher ? decrypted_cipher(cipher) : nil
    end

    def ciphers
      @data[:Ciphers].lazy.map {|cipher_data| decrypted_cipher(cipher_data) }
    end

    def decrypted_cipher(cipher_data)
      Cipher.from_encrypted( cipher_data ) {|data| decrypt_data(data) }
    end

    def save_to_file(file)
      File.write(file, data.to_json)
    end

  private

    def decrypt_data(data)
      @crypto.decrypt(data, @key)
    end

  end

end 