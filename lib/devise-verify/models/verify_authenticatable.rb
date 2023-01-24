require 'devise-verify/hooks/verify_authenticatable'
module Devise
  module Models
    module VerifyAuthenticatable
      extend ActiveSupport::Concern

      def with_verify_authentication?(request)
        if self.verify_id.present? && self.verify_enabled
          return true
        end

        return false
      end

      module ClassMethods
        def find_by_verify_id(verify_id)
          where(verify_id: verify_id).first
        end

        Devise::Models.config(self, :verify_remember_device, :verify_enable_onetouch, :verify_enable_qr_code)
      end
    end
  end
end

