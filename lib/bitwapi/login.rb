module Bitwapi

  class Login < Cipher
    TYPE = 1

    self.attributes(
      :Uri,
      :Username,
      :Password,
      :Totp
    )

  end

end