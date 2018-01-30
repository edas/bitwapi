module Bitwapi

  class Card < Cipher
    TYPE = 3

    self.attributes(
      :CardholderName,
      :Brand,
      :Number,
      :ExpMonth,
      :ExpYear,
      :Code
    )

  end

end