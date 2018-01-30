module Bitwapi

  class Identity < Cipher
    TYPE = 4

    self.attributes(
      :Title,
      :FirstName,
      :MiddleName,
      :LastName,
      :Address1,
      :Address2,
      :Address3,
      :City,
      :State,
      :PostalCode,
      :Country,
      :Company,
      :Email,
      :Phone,
      :SSN,
      :Username,
      :PassportNumber,
      :LicenseNumber
    )

    def address
      [address1, address2, address3].freeze
    end

  end

end