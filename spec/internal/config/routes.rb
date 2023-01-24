# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users
  devise_for :lockable_users, # for testing verify_lockable
    class: 'LockableUser',
    :path_names => {
      :verify_verify => "/verify-token",
      :enable_verify => "/enable-two-factor",
      :verify_verify_installation => "/verify-installation",
      :verify_onetouch_status => "/onetouch-status"
    }
  root 'home#index'
end
