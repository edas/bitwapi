require 'securerandom'
require 'json'
require 'jwt'

module Bitwapi

  class API

    BITWARDEN_OFFICIAL_URLS = {
      base_url: "https://api.bitwarden.com",
      identity_url: "https://identity.bitwarden.com",
      icons_url: "https://icons.bitwarden.com",
    }

    def self.default_device_type
      DeviceType::Firefox
    end

    def self.default_options
      { device_type: self.default_device_type }
    end

    def self.default_agent_string
      "bitwapi/#{VERSION}"
    end

    def self.official(options={})
      self.new(BITWARDEN_OFFICIAL_URLS.merge(default_options).merge(options))
    end

    def self.unofficial(base, options={})
      urls = {
        base_url: "#{base}/api",
        identity_url: "#{base}/identity",
        icons_url: "#{base}/icons",
      }
      self.new(urls.merge(default_options).merge(options))
    end

    def initialize(base_url:, identity_url:, icons_url:, device_type:nil, access_token:nil, refresh_token:nil, agent_string:nil)
      @base_url = base_url
      @identity_url = identity_url
      @icons_url = icons_url
      @device_type = device_type || self.class.default_device_type
      @agent_string = agent_string || self.class.default_agent_string
      @access_token = access_token
      @refresh_token = refresh_token
      @expire_at = get_token_expiration(access_token) if @access_token
      @crypto = Crypto.new
      @transport = Transport.new(device_type: @device_type, agent_string: @agent_string, access_token: @access_token)
    end

    def transport
      @transport.tap { |t| t.access_token = get_valid_token }
    end

    def credentials
      {
        base_url: @base_url,
        identity_url: @identity_url,
        icons_url: @icons_url,
        device_type: @device_type,
        access_token: @access_token,
        refresh_token: @refresh_token,
      }
    end

    def register(email, password, name:nil, hint:nil, access_token:nil, kdf:nil, iterations:nil)
      kdf ||= Bitwapi::Crypto::PBKDF2_SHA256
      iterations ||= Bitwapi::Crypto::DEFAULT_ITERATIONS[kdf]
      destination = "#{@base_url}/accounts/register"
      internal_key = @crypto.make_master_key(password, email, kdf, iterations)
      key = @crypto.make_enc_key(internal_key)
      master_password_hash = @crypto.hash_password(password, email, kdf, iterations)
      @transport.json_post(destination, {
        name: name,
        email: email,
        masterPasswordHash: master_password_hash,
        masterPasswordHint: hint,
        key: key
      }, { 'Authorization' => "none"})
      true
    end

    def generate_identifier
      SecureRandom.uuid
    end

    def prelogin(email)
      destination = "#{@base_url}/accounts/prelogin"
      @transport.json_post(destination, {
        email: email
      }, { 'Authorization' => "none"})
    end

    def login(email, password, device_type: @device_type, device_identifier: generate_identifier, device_name: @agent_string, device_push_token: "", client_id:"browser", two_factor_provider: nil, two_factor_token: nil, two_factor_remember: 1, kdf_type:nil, kdf_iterations:nil)
      if kdf_type.nil? || kdf_iterations.nil?
        data = prelogin(email)
        kdf_type = data[:Kdf] || Bitwapi::Crypto::PBKDF2_SHA256
        kdf_iterations = data[:KdfIterations] || Bitwapi::Crypto::DEFAULT_ITERATIONS[kdf_type]
      end
      destination = "#{@identity_url}/connect/token"
      master_password_hash = @crypto.hash_password(password, email, kdf_type, kdf_iterations)
      grant = {
        grant_type: 'password',
        username: email,
        password: master_password_hash,
        scope: "api offline_access",
        client_id: client_id,
        deviceType: device_type,
        deviceIdentifier: device_identifier,
        deviceName: device_name,
        devicePushToken: device_push_token,
      }
      if two_factor_provider and two_factor_token 
        grant.merge!({
          twoFactorToken: two_factor_token,
          twoFactorProvider: two_factor_provider,
          twoFactorRemember: two_factor_remember,
        })
      end
      @transport.post(destination, grant, { 'Authorization' => "none"}).tap do |resp|
        resp[:expire_at] = get_token_expiration(resp[:access_token])
        @access_token = resp[:access_token]
        @refresh_token = resp[:refresh_token]
        @expire_at = resp[:expire_at]
      end
      credentials
    end

    def get_valid_token
      is_token_valid? || refresh_token
      @access_token
    end

    def get_token_expiration(token=@access_token)
      Time.at decode_token(token)["exp"].to_i
    end

    def is_token_valid?(token=@access_token)
      token and (Time.now < get_token_expiration(token) + 60)
    end

    def decode_token(token=@access_token)
      JWT.decode(token, nil, false, { verify_expiration: false })[0]
    end

    def sync
      destination = "#{@base_url}/sync"
      Vault.new(
        transport.get(destination)
      )
    end

    def get_vault
      sync
    end

    def refresh_token
      destination = "#{@identity_url}/connect/token"
      @transport.post(destination, {
        "grant_type": "refresh_token",
        "client_id": "browser",
        "refresh_token": @refresh_token,
      }, { 'Authorization' => "none"}).tap do |resp|
        resp[:expire_at] = get_token_expiration(resp[:access_token])
        @access_token = resp[:access_token]
        @refresh_token = resp[:refresh_token]
        @expire_at = resp[:expire_at]
      end
    end

  end

end
