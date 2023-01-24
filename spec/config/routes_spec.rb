# frozen_string_literal: true

RSpec.describe "routes with devise_verify", type: :controller do
  describe "with default devise_for" do
    it "route to devise_verify#GET_verify_verify" do
      expect(get: '/users/verify_verify').to route_to("devise/devise_verify#GET_verify_verify")
    end

    it "routes to devise_verify#POST_verify_verify" do
      expect(post: '/users/verify_verify').to route_to("devise/devise_verify#POST_verify_verify")
    end

    it "routes to devise_verify#GET_enable_verify" do
      expect(get: '/users/enable_verify').to route_to("devise/devise_verify#GET_enable_verify")
    end

    it "routes to devise_verify#POST_enable_verify" do
      expect(post: '/users/enable_verify').to route_to("devise/devise_verify#POST_enable_verify")
    end

    it "routes to devise_verify#POST_disable_verify" do
      expect(post: '/users/disable_verify').to route_to("devise/devise_verify#POST_disable_verify")
    end

    it "route to devise_verify#GET_verify_verify_installation" do
      expect(get: '/users/verify_verify_installation').to route_to("devise/devise_verify#GET_verify_verify_installation")
    end

    it "routes to devise_verify#POST_verify_verify_installation" do
      expect(post: '/users/verify_verify_installation').to route_to("devise/devise_verify#POST_verify_verify_installation")
    end

    it "routes to devise_verify#request_sms" do
      expect(post: '/users/request-sms').to route_to("devise/devise_verify#request_sms")
    end

    it "routes to devise_verify#request_phone_call" do
      expect(post: '/users/request-phone-call').to route_to("devise/devise_verify#request_phone_call")
    end

    it "routes to devise_verify#GET_verify_onetouch_status" do
      expect(get: '/users/verify_onetouch_status').to route_to("devise/devise_verify#GET_verify_onetouch_status")
    end
  end

  describe "with customised mapping" do
    # See routing in spec/internal/config/routes.rb for the mapping
    it "updates to new routes set in the mapping" do
      expect(get: '/lockable_users/verify-token').to route_to("devise/devise_verify#GET_verify_verify")
      expect(post: '/lockable_users/verify-token').to route_to("devise/devise_verify#POST_verify_verify")
      expect(get: '/lockable_users/enable-two-factor').to route_to("devise/devise_verify#GET_enable_verify")
      expect(post: '/lockable_users/enable-two-factor').to route_to("devise/devise_verify#POST_enable_verify")
      expect(get: '/lockable_users/verify-installation').to route_to("devise/devise_verify#GET_verify_verify_installation")
      expect(post: '/lockable_users/verify-installation').to route_to("devise/devise_verify#POST_verify_verify_installation")
      expect(get: '/lockable_users/onetouch-status').to route_to("devise/devise_verify#GET_verify_onetouch_status")
    end

    it "doesn't change routes not in custom mapping" do
      expect(post: '/lockable_users/disable_verify').to route_to("devise/devise_verify#POST_disable_verify")
      expect(post: '/lockable_users/request-sms').to route_to("devise/devise_verify#request_sms")
      expect(post: '/lockable_users/request-phone-call').to route_to("devise/devise_verify#request_phone_call")
    end
  end
end
