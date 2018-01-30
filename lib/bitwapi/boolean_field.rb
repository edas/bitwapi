module Bitwapi

  class BooleanField < Field
  	TYPE = 2

    def value
      !! super
    end

  end

end