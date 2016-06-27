module Rakudax
  class Settings < Settingslogic
    source Rakudax::Base.settings_path
    namespace Rakudax::Base.env
    suppress_errors true
  end
end
