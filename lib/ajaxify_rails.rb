require "ajaxify_rails/version"
require "ajaxify_rails/action_controller_additions"

module AjaxifyRails

  module Rails
    class Engine < ::Rails::Engine
    end
  end

  ActiveSupport.on_load(:action_controller) do
    include ActionControllerAdditions
  end

end
