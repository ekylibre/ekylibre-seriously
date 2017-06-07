module Seriously
  AUTH_PREF = 'serious.auth.token'.freeze

  autoload :Game,       'seriously/game'
  autoload :Farm,       'seriously/farm'
  autoload :Timescope,  'seriously/timescope'
end
