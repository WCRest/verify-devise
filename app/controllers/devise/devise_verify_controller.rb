class Devise::DeviseVerifyController < ApplicationController
  prepend_before_action :find_resource, :only => [
    :request_phone_call, :request_sms
  ]
  prepend_before_action :find_resource_and_require_password_checked, :only => [
    :GET_verify_verify, :POST_verify_verify, :GET_verify_onetouch_status
  ]

  prepend_before_action :check_resource_has_verify_id, :only => [
    :GET_verify_verify_installation, :POST_verify_verify_installation
  ]

  prepend_before_action :check_resource_not_verify_enabled, :only => [
    :GET_verify_verify_installation, :POST_verify_verify_installation
  ]

  prepend_before_action :authenticate_scope!, :only => [
    :GET_enable_verify, :POST_enable_verify, :GET_verify_verify_installation,
    :POST_verify_verify_installation, :POST_disable_verify
  ]

  before_action :set_client, only: [:create, :start_verification, :verify]

  include Devise::Controllers::Helpers

  def GET_verify_verify
    if resource_class.verify_enable_onetouch
      approval_request = send_one_touch_request(@resource.verify_id)['approval_request']
      @onetouch_uuid = approval_request['uuid'] if approval_request.present?
    end
    render :verify_verify
  end

  # verify 2fa
  def POST_verify_verify
    token = Verify::API.verify({
      :id => @resource.verify_id,
      :token => params[:token],
      :force => true
    })

    if token.ok?
      remember_device(@resource.id) if params[:remember_device].to_i == 1
      remember_user
      record_verify_authentication
      respond_with resource, :location => after_sign_in_path_for(@resource)
    else
      handle_invalid_token :verify_verify, :invalid_token
    end
  end

  # enable 2fa
  def GET_enable_verify
    if resource.verify_id.blank? || !resource.verify_enabled
      render :enable_verify
    else
      set_flash_message(:notice, :already_enabled)
      redirect_to after_verify_enabled_path_for(resource)
    end
  end

  def POST_enable_verify
    account_sid = ENV['TWILIO_ACCOUNT_SID']
    auth_token = ENV['TWILIO_AUTH_TOKEN']
    byebug
    @client = Twilio::REST::Client.new(account_sid, auth_token)

    @verify_user = Verify::API.register_user(
      :email => resource.email,
      :cellphone => params[:cellphone],
      :country_code => params[:country_code]
    )

    if @verify_user.ok?
      resource.verify_id = @verify_user.id
      if resource.save
        redirect_to [resource_name, :verify_verify_installation] and return
      else
        set_flash_message(:error, :not_enabled)
        redirect_to after_verify_enabled_path_for(resource) and return
      end
    else
      set_flash_message(:error, :not_enabled)
      render :enable_verify
    end
  end

  # Disable 2FA
  def POST_disable_verify
    verify_id = resource.verify_id
    resource.assign_attributes(:verify_enabled => false, :verify_id => nil)
    resource.save(:validate => false)

    other_resource = resource.class.find_by(:verify_id => verify_id)
    if other_resource
      # If another resource has the same verify_id, do not delete the user from
      # the API.
      forget_device
      set_flash_message(:notice, :disabled)
    else
      response = Verify::API.delete_user(:id => verify_id)
      if response.ok?
        forget_device
        set_flash_message(:notice, :disabled)
      else
        # If deleting the user from the API fails, set everything back to what
        # it was before.
        # I'm not sure this is a good idea, but it was existing behaviour.
        # Could be changed in a major version bump.
        resource.assign_attributes(:verify_enabled => true, :verify_id => verify_id)
        resource.save(:validate => false)
        set_flash_message(:error, :not_disabled)
      end
    end
    redirect_to after_verify_disabled_path_for(resource)
  end

  def GET_verify_verify_installation
    start_verification('+19546955576', 'sms')
    render :verify_verify_installation
  end

  def POST_verify_verify_installation
    token = Verify::API.verify({
      :id => self.resource.verify_id,
      :token => params[:token],
      :force => true
    })

    self.resource.verify_enabled = token.ok?

    if token.ok? && self.resource.save
      remember_device(@resource.id) if params[:remember_device].to_i == 1
      record_verify_authentication
      set_flash_message(:notice, :enabled)
      redirect_to after_verify_verified_path_for(resource)
    else
      if resource_class.verify_enable_qr_code
        response = Verify::API.request_qr_code(id: resource.verify_id)
        @verify_qr_code = response.qr_code
      end
      handle_invalid_token :verify_verify_installation, :not_enabled
    end
  end

  def GET_verify_onetouch_status
    response = Verify::OneTouch.approval_request_status(:uuid => params[:onetouch_uuid])
    status = response.dig('approval_request', 'status')
    case status
    when 'pending'
      head 202
    when 'approved'
      remember_device(@resource.id) if params[:remember_device].to_i == 1
      remember_user
      record_verify_authentication
      render json: { redirect: after_sign_in_path_for(@resource) }
    when 'denied'
      head :unauthorized
    else
      head :internal_server_error
    end
  end

  def request_phone_call
    unless @resource
      render :json => { :sent => false, :message => "User couldn't be found." }
      return
    end

    response = Verify::API.request_phone_call(:id => @resource.verify_id, :force => true)
    render :json => { :sent => response.ok?, :message => response.message }
  end

  def request_sms
    if !@resource
      render :json => {:sent => false, :message => "User couldn't be found."}
      return
    end

    response = Verify::API.request_sms(:id => @resource.verify_id, :force => true)
    render :json => {:sent => response.ok?, :message => response.message}
  end

  private
  
  def check_verification(phone, code)
    verification_check = @client.verify.services(ENV['VERIFICATION_SID'])
                                       .verification_checks
                                       .create(:to => phone, :code => code)
    return verification_check.status == 'approved'
  end

  def set_client
    @client = Twilio::REST::Client.new(ENV['TWILIO_ACCOUNT_SID'], ENV['TWILIO_AUTH_TOKEN'])
  end

  def check_verification(phone, code)
    verification_check = @client.verify.services(ENV['VERIFICATION_SID'])
                                       .verification_checks
                                       .create(:to => phone, :code => code)
    return verification_check.status == 'approved'
  end

  def start_verification(to, channel='sms')
    channel = 'sms' unless ['sms', 'voice'].include? channel
    verification = @client.verify.services(ENV['VERIFICATION_SID'])
                                 .verifications
                                 .create(:to => to, :channel => channel)
    return verification.sid
  end


  def authenticate_scope!
    send(:"authenticate_#{resource_name}!", :force => true)
    self.resource = send("current_#{resource_name}")
    @resource = resource
  end

  def find_resource
    @resource = send("current_#{resource_name}")

    if @resource.nil?
      @resource = resource_class.find_by_id(session["#{resource_name}_id"])
    end
  end

  def find_resource_and_require_password_checked
    find_resource

    if @resource.nil? || session[:"#{resource_name}_password_checked"].to_s != "true"
      redirect_to invalid_resource_path
    end
  end

  def check_resource_has_verify_id
    redirect_to [resource_name, :enable_verify] if !resource.verify_id
  end

  def check_resource_not_verify_enabled
    if resource.verify_id && resource.verify_enabled
      redirect_to after_verify_verified_path_for(resource)
    end
  end

  protected

  def after_verify_enabled_path_for(resource)
    root_path
  end

  def after_verify_verified_path_for(resource)
    after_verify_enabled_path_for(resource)
  end

  def after_verify_disabled_path_for(resource)
    root_path
  end

  def invalid_resource_path
    root_path
  end

  def handle_invalid_token(view, error_message)
    if @resource.respond_to?(:invalid_verify_attempt!) && @resource.invalid_verify_attempt!
      after_account_is_locked
    else
      set_flash_message(:error, error_message)
      render view
    end
  end

  def after_account_is_locked
    sign_out_and_redirect @resource
  end

  def remember_user
    if session.delete("#{resource_name}_remember_me") == true && @resource.respond_to?(:remember_me=)
      @resource.remember_me = true
    end
  end
end
