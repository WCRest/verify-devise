# frozen_string_literal: true

module DeviseVerify
  module Generators
    class DeviseVerifyGenerator < Rails::Generators::NamedBase
      namespace "devise_verify"

      desc "Add :verify_authenticatable directive in the given model, plus accessors. Also generate migration for ActiveRecord"

      def inject_devise_verify_content
        path = File.join(destination_root, "app", "models", "#{file_path}.rb")
        if File.exist?(path) &&
           !File.read(path).include?("verify_authenticatable")
          inject_into_file(path,
                           "verify_authenticatable, :",
                           :after => "devise :")
        end

        if File.exist?(path) &&
           !File.read(path).include?(":verify_id")
          inject_into_file(path,
                           ":verify_id, :last_sign_in_with_verify, ",
                           :after => "attr_accessible ")
        end
      end

      hook_for :orm
    end
  end
end
