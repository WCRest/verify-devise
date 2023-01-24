module DeviseVerify
  module Views
    module Helpers
      def verify_request_phone_call_link(opts = {})
        title = opts.delete(:title) do
          I18n.t('request_phone_call', scope: 'devise')
        end
        opts = {
          :id => "verify-request-phone-call-link",
          :method => :post,
          :remote => true
        }.merge(opts)

        link_to(
          title,
          url_for([resource_name.to_sym, :request_phone_call]),
          opts
        )
      end

      def verify_request_sms_link(opts = {})
        title = opts.delete(:title) do
          I18n.t('request_sms', scope: 'devise')
        end
        opts = {
          :id => "verify-request-sms-link",
          :method => :post,
          :remote => true
        }.merge(opts)

        link_to(
          title,
          url_for([resource_name.to_sym, :request_sms]),
          opts
        )
      end

      def verify_verify_form(opts = {}, &block)
        opts = default_opts.merge(:id => 'devise_verify').merge(opts)
        form_tag([resource_name.to_sym, :verify_verify], opts) do
          buffer = hidden_field_tag(:"#{resource_name}_id", @resource.id)
          buffer << capture(&block)
        end
      end

      def enable_verify_form(opts = {}, &block)
        opts = default_opts.merge(opts)
        form_tag([resource_name.to_sym, :enable_verify], opts) do
          capture(&block)
        end
      end

      def verify_verify_installation_form(opts = {}, &block)
        opts = default_opts.merge(opts)
        form_tag([resource_name.to_sym, :verify_verify_installation], opts) do
          capture(&block)
        end
      end

      private

      def default_opts
        { :class => 'verify-form', :method => :post }
      end
    end
  end
end
