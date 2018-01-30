require 'rest-client'
require 'json'

module Bitwapi
  class Transport

    def initialize(options)
      @options = options
    end

    def access_token=(token)
      @options[:access_token] = token
    end

    def json_post(destination, playload, headers={})
      json_playload = playload.to_json
      headers_with_json = {'Content-Type' => 'application/json; charset=utf-8' }
      post(destination, json_playload, headers_with_json.merge(headers))
    end

    def post(destination, playload=nil, headers={})
      request(destination, playload, headers) do |destination, playload, headers|
        RestClient.post(destination, playload, headers)
      end
    end

    def get(destination, headers={})
      request(destination, nil, headers) do |destination, playload, headers|
        RestClient.get(destination, headers)
      end
    end

    def request(destination, playload=nil, headers={})
      headers = default_headers.merge(headers)
      headers['Authorization'] ||= "Bearer #{@options[:access_token]}"
      resp = yield(destination, playload, headers)
      JSON.parse(resp.body.strip == "" ? "null" : resp.body, symbolize_names: true)
    end

    def default_headers
      {
        'accept' => :json,
        'Device-Type' => @options[:device_type].to_s,
        'User-Agent' => @options[:agent_string].to_s
      }
    end

  end
end
