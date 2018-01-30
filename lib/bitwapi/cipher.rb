require 'securerandom'
require 'time'

module Bitwapi

  class Cipher

    TYPE = nil
    ATTRIBUTES = [ ]

    def empty_block 
      {      
        CollectionIds: [],
        FolderId: nil,
        Favorite: true,
        Edit: true,
        Type: self.class::TYPE,
        Id: nil,
        OrganizationId: nil,
        Data: empty_data_block,
        Attachments: nil,
        OrganizationUseTotp: false,
        RevisionDate: nil,
        Object: "cipherDetails",
      }
    end

    def empty_data_block
      {
        Name: nil,
        Notes: nil,
        Fields: [ ],
      }.merge( self.class::ATTRIBUTES.map {|attribute| [attribute, nil] }.to_h )
    end

    def self.attributes(*names)
      self.const_set(:ATTRIBUTES, names)
      names.each do |title| 
        underscore = title.to_s.gsub(/([A-Z])([A-Z]*[a-z]*)/){"_#{$1.downcase}#{$2}"}[1..-1]
        define_method(underscore.to_sym) { @data[:Data][title.to_sym] }
      end
    end

    def self.from_encrypted(data, &block)
      klass = case data[:Type]
        when Login::TYPE then Login
        when Note::TYPE then Note
        when Card::TYPE then Card
        when Identity::TYPE then Identity
        else raise "unknown cipher type"
      end
      data = data.clone
      data[:Data] = _decrypt(data[:Data], &block)
      klass.new(data)
    end

    def initialize(data, &block)
      @data = data
    end

    def self._decrypt(data, &block)
      case data
      when Hash
        data.transform_values {|value| _decrypt(value, &block) }
      when Array
        data.map {|value| _decrypt(value, &block) }
      when String
        block.call(data)
      else
        data.clone
      end
    end

    def folder_id
      @data[:FolderId]
    end

    def favorite?
      @data[:Favorite]
    end

    def id
      @data[:Id]
    end

    def organization_id
      @data[:OrganizationId]
    end

    def organization_use_totp?
      @data[:OrganizationUseTotp]
    end

    def type
      @data[:Type]
    end

    def revision_date
      @data[:RevisionDate] ? Time.parse(@data[:RevisionDate]+"Z") : nil
    end

    def attachments
      @data[:Attachments]
    end

    def name
      @data[:Data][:Name]
    end

    def notes
      @data[:Data][:Notes]
    end

    def fields
      @data[:Data][:Fields].map {|field| Field.from_data(field) }.freeze
    end

  end

end