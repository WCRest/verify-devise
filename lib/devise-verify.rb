require 'active_support/concern'
require 'active_support/core_ext/integer/time'
require 'devise'

module Devise
  mattr_accessor :verify_remember_device, :verify_enable_onetouch, :verify_enable_qr_code
  @@verify_remember_device = 1.month
  @@verify_enable_onetouch = false
  @@verify_enable_qr_code = false
end

module DeviseVerify
  autoload :Mapping, 'devise-verify/mapping'

  module Controllers
    autoload :Passwords, 'devise-verify/controllers/passwords'
    autoload :Helpers, 'devise-verify/controllers/helpers'
  end

  module Views
    autoload :Helpers, 'devise-verify/controllers/view_helpers'
  end
end

require 'devise-verify/routes'
require 'devise-verify/rails'
require 'devise-verify/models/verify_authenticatable'
require 'devise-verify/models/verify_lockable'
require 'devise-verify/version'

#Verify.user_agent = "DeviseVerify/#{DeviseVerify::VERSION} - #{Verify.user_agent}"

Devise.add_module :verify_authenticatable, :model => 'devise-verify/models/verify_authenticatable', :controller => :devise_verify, :route => :verify
Devise.add_module :verify_lockable,        :model => 'devise-verify/models/verify_lockable'

warn "DEPRECATION WARNING: The verify-devise library is no longer actively maintained. The Verify API is being replaced by the Twilio Verify API. Please see the README for more details."