module Bitwapi

  class Field

    def self.from_data(data)
      klass = case data[:Type]
        when TextField::TYPE then TextField
        when HiddenField::TYPE then HiddenField
        when BooleanField::TYPE then BooleanField
        else raise "unknown field type #{data[:Type]}"
      end
      klass.new(data)
    end

    def initialize(data)
      @data = data
    end

    def name 
      @data[:Name]
    end

    def value
      @data[:Value]
    end

    def type
      @data[:Type]
    end

  end
end