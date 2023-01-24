module ActionDispatch::Routing
  class Mapper
    protected

    def devise_verify(mapping, controllers)
      match "/#{mapping.path_names[:verify_verify]}", :controller => controllers[:devise_verify], :action => :GET_verify_verify, :as => :verify_verify, :via => :get
      match "/#{mapping.path_names[:verify_verify]}", :controller => controllers[:devise_verify], :action => :POST_verify_verify, :as => nil, :via => :post

      match "/#{mapping.path_names[:enable_verify]}", :controller => controllers[:devise_verify], :action => :GET_enable_verify, :as => :enable_verify, :via => :get
      match "/#{mapping.path_names[:enable_verify]}", :controller => controllers[:devise_verify], :action => :POST_enable_verify, :as => nil, :via => :post

      match "/#{mapping.path_names[:disable_verify]}", :controller => controllers[:devise_verify], :action => :POST_disable_verify, :as => :disable_verify, :via => :post

      match "/#{mapping.path_names[:verify_verify_installation]}", :controller => controllers[:devise_verify], :action => :GET_verify_verify_installation, :as => :verify_verify_installation, :via => :get
      match "/#{mapping.path_names[:verify_verify_installation]}", :controller => controllers[:devise_verify], :action => :POST_verify_verify_installation, :as => nil, :via => :post

      match "/#{mapping.path_names[:verify_onetouch_status]}", :controller => controllers[:devise_verify], :action => :GET_verify_onetouch_status, as: :verify_onetouch_status, via: :get

      match "/#{mapping.path_names[:request_sms]}", :controller => controllers[:devise_verify], :action => :request_sms, :as => :request_sms, :via => :post
      match "/#{mapping.path_names[:request_phone_call]}", :controller => controllers[:devise_verify], :action => :request_phone_call, :as => :request_phone_call, :via => :post
    end
  end
end

