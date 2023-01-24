module DeviseVerify
  class Engine < ::Rails::Engine
    ActiveSupport.on_load(:action_controller) do
      include DeviseVerify::Controllers::Helpers
    end
    ActiveSupport.on_load(:action_view) do
      include DeviseVerify::Views::Helpers
    end

    # extend mapping with after_initialize because it's not reloaded
    config.after_initialize do
      Devise::Mapping.send :prepend, DeviseVerify::Mapping
    end
  end
end

