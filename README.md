🚨🚨🚨

**This library is no longer actively maintained.** The Verify API has been replaced with the [Twilio Verify API](https://www.twilio.com/docs/verify). Twilio will support the Verify API through November 1, 2022 for SMS/Voice. After this date, we’ll start to deprecate the service for SMS/Voice. Any requests sent to the API after May 1, 2023, will automatically receive an error.  Push and TOTP will continue to be supported through July 2023.

[Learn more about migrating from Verify to Verify.](https://www.twilio.com/blog/migrate-verify-to-verify)

Please visit the Twilio Docs for:
* [Verify + Ruby (Rails) quickstart](https://www.twilio.com/docs/verify/quickstarts/ruby-rails)
* [Twilio Ruby helper library](https://www.twilio.com/docs/libraries/ruby)
* [Verify API reference](https://www.twilio.com/docs/verify/api)
* **Coming soon**: Look out for a new Devise plugin to use Twilio Verify with Devise

Please direct any questions to [Twilio Support](https://support.twilio.com/hc/en-us). Thank you!

🚨🚨🚨

---

# Verify Devise [![Build Status](https://github.com/twilio/verify-devise/workflows/build/badge.svg)](https://github.com/twilio/verify-devise/actions)

This is a [Devise](https://github.com/plataformatec/devise) extension to add [Two-Factor Authentication with Verify](https://www.twilio.com/docs/verify) to your Rails application.

* [Pre-requisites](#pre-requisites)
* [Demo](#demo)
* [Getting started](#getting-started)
  * [Configuring Models](#configuring-models)
    * [With the generator](#with-the-generator)
    * [Manually](#manually)
    * [Final steps](#final-steps)
* [Custom Views](#custom-views)
  * [Request a phone call](#request-a-phone-call)
* [Custom Redirect Paths (eg. using modules)](#custom-redirect-paths-eg-using-modules)
* [I18n](#i18n)
* [Session variables](#session-variables)
* [OneTouch support](#onetouch-support)
* [Generic authenticator token support](#generic-authenticator-token-support)
* [Rails 5 CSRF protection](#rails-5-csrf-protection)
* [Running Tests](#running-tests)
* [Notice: Twilio Verify API’s Sandbox feature will stop working on Sep 30, 2021](#notice-twilio-verify-apis-sandbox-feature-will-stop-working-on-sep-30-2021)
* [Copyright](#copyright)

## Pre-requisites

To use the Verify API you will need a Twilio Account, [sign up for a free Twilio account here](https://www.twilio.com/try-twilio).

Create an [Verify Application in the Twilio console](https://www.twilio.com/console/verify/applications) and take note of the API key.

## Demo

See [this repo for a full demo of using `verify-devise`](https://github.com/twilio/verify-devise-demo).

## Getting started

First get your Verify API key from [the Twilio console](https://www.twilio.com/console/verify/applications). We recommend you store your API key as an environment variable.

```bash
$ export AUTHY_API_KEY=YOUR_AUTHY_API_KEY
```

Next add the gem to your Gemfile:

```ruby
gem 'devise'
gem 'devise-verify'
```

And then run `bundle install`

Add `Devise Verify` to your App:

    rails g devise_verify:install

    --haml: Generate the views in Haml
    --sass: Generate the stylesheets in Sass

### Configuring Models

You can add devise_verify to your user model in two ways.

#### With the generator

Run the following command:

```bash
rails g devise_verify [MODEL_NAME]
```

To support account locking (recommended), you must add `:verify_lockable` to the `devise :verify_authenticatable, ...` configuration in your model as this is not yet supported by the generator.

#### Manually

Add `:verify_authenticatable` and `:verify_lockable` to the `devise` options in your Devise user model:

```ruby
devise :verify_authenticatable, :verify_lockable, :database_authenticatable, :lockable
```

(Note, `:verify_lockable` is optional but recommended. It should be used with Devise's own `:lockable` module).

Also add a new migration. For example, if you are adding to the `User` model, use this migration:

```ruby
class DeviseVerifyAddToUsers < ActiveRecord::Migration[6.0]
  def self.up
    change_table :users do |t|
      t.string    :verify_id
      t.datetime  :last_sign_in_with_verify
      t.boolean   :verify_enabled, :default => false
    end

    add_index :users, :verify_id
  end

  def self.down
    change_table :users do |t|
      t.remove :verify_id, :last_sign_in_with_verify, :verify_enabled
    end
  end
end
```

#### Final steps

For either method above, run the migrations:

```bash
rake db:migrate
```

**[Optional]** Update the default routes to point to something like:

```ruby
devise_for :users, :path_names => {
	:verify_verify => "/verify-token",
	:enable_verify => "/enable-two-factor",
	:verify_verify_installation => "/verify-installation",
	:verify_onetouch_status => "/onetouch-status"
}
```

Now whenever a user wants to enable two-factor authentication they can go to:

    http://your-app/users/enable-two-factor

And when the user logs in they will be redirected to:

    http://your-app/users/verify-token

## Custom Views

If you want to customise your views, you can modify the files that are located at:

    app/views/devise/devise_verify/enable_verify.html.erb
    app/views/devise/devise_verify/verify_verify.html.erb
    app/views/devise/devise_verify/verify_verify_installation.html.erb

### Request a phone call

The default views come with a button to force a request for an SMS message. You can also add a button that will request a phone call instead. Simply add the helper method to your view:

    <%= verify_request_phone_call_link %>

## Custom Redirect Paths (eg. using modules)

If you want to customise the redirects you can override them within your own controller like this:

```ruby
class MyCustomModule::DeviseVerifyController < Devise::DeviseVerifyController

  protected
    def after_verify_enabled_path_for(resource)
      my_own_path
    end

    def after_verify_verified_path_for(resource)
      my_own_path
    end

    def after_verify_disabled_path_for(resource)
      my_own_path
    end

    def invalid_resource_path
      my_own_path
    end
end
```

And tell the router to use this controller

```ruby
devise_for :users, controllers: {devise_verify: 'my_custom_module/devise_verify'}
```

## I18n

The install generator also copies a `Devise Verify` i18n file which you can find at:

    config/locales/devise.verify.en.yml

## Session variables

If you want to know if the user is signed in using Two-Factor authentication,
you can use the following session variable:

```ruby
session["#{resource_name}_verify_token_checked"]

# Eg.
session["user_verify_token_checked"]
```

## OneTouch support

To enable [Verify push authentication](https://www.twilio.com/verify/features/push), you need to modify the Devise config file `config/initializers/devise.rb` and add configuration:

```
config.verify_enable_onetouch = true
```

## Generic authenticator token support

Verify supports other authenticator apps by providing a QR code that your users can scan.

> **To use this feature, you need to enable it in your [Twilio Console](https://www.twilio.com/console/verify/applications)**

Once you have enabled generic authenticator tokens, you can enable this in devise-verify by modifying the Devise config file `config/initializers/devise.rb` and adding the configuration:

```
config.verify_enable_qr_code = true
```

This will display a QR code on the verification screen (you still need to take a user's phone number and country code). If you have implemented your own views, the QR code URL is available on the verification page as `@verify_qr_code`.

## Rails 5 CSRF protection

In Rails 5 `protect_from_forgery` is no longer prepended to the `before_action` chain. If you call `authenticate_user` before `protect_from_forgery` your request will result in a "Can't verify CSRF token authenticity" error.

To remedy this, add `prepend: true` to your `protect_from_forgery` call, like in this example from the [Verify Devise demo app](https://github.com/twilio/verify-devise-demo):

```ruby
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception, prepend: true
end
```

## Running Tests

Run the following command:

```bash
$ bundle exec rspec
```

## Notice: Twilio Verify API’s Sandbox feature will stop working on Sep 30, 2021
Twilio is discontinuing the Verify API’s Sandbox, a feature that allows customers to run continuous integration tests against a mock Verify API for free. The Sandbox is no longer being maintained, so we will be taking the final deprecation step of shutting it down on September 30, 2021. The rest of the Verify API product will continue working as-is.

This repo previously used the sandbox API as part of the test suite, but that has been since removed.

You will only be affected if you are using the sandbox API in your own application or test suite.

For more information please read this article on [how we are discontinuing the Twilio Verify sandbox API](https://support.verify.com/hc/en-us/articles/1260803396889-Notice-Twilio-Verify-API-s-Sandbox-feature-will-stop-working-on-Sep-30-2021).

## Copyright

Copyright (c) 2012-2021 Verify Inc. See LICENSE.txt for further details.
