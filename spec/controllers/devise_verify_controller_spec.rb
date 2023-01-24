# frozen_string_literal: true

RSpec.describe Devise::DeviseVerifyController, type: :controller do
  let(:user) { create(:verify_user) }
  before(:each) { request.env["devise.mapping"] = Devise.mappings[:user] }

  describe "first step of authentication not complete" do
    describe "with no user details in the session" do
      describe "#GET_verify_verify" do
        it "should redirect to the root_path" do
          get :GET_verify_verify
          expect(response).to redirect_to(root_path)
        end

        it "should not make a OneTouch request" do
          expect(Verify::OneTouch).not_to receive(:send_approval_request)
          get :GET_verify_verify
        end
      end

      describe "#POST_verify_verify" do
        it "should redirect to the root_path" do
          post :POST_verify_verify
          expect(response).to redirect_to(root_path)
        end

        it "should not verify a token" do
          expect(Verify::API).not_to receive(:verify)
          post :POST_verify_verify
        end
      end

      describe "#GET_verify_onetouch_status" do
        it "should redirect to the root_path" do
          get :GET_verify_onetouch_status
          expect(response).to redirect_to(root_path)
        end

        it "should not request the one touch status" do
          expect(Verify::OneTouch).not_to receive(:approval_request_status)
          get :GET_verify_onetouch_status
        end
      end
    end

    describe "without checking the password" do
      before(:each) { request.session["user_id"] = user.id }

      describe "#GET_verify_verify" do
        it "should redirect to the root_path" do
          get :GET_verify_verify
          expect(response).to redirect_to(root_path)
        end

        it "should not make a OneTouch request" do
          expect(Verify::OneTouch).not_to receive(:send_approval_request)
          get :GET_verify_verify
        end
      end

      describe "#POST_verify_verify" do
        it "should redirect to the root_path" do
          post :POST_verify_verify
          expect(response).to redirect_to(root_path)
        end

        it "should not verify a token" do
          expect(Verify::API).not_to receive(:verify)
          post :POST_verify_verify
        end
      end

      describe "#GET_verify_onetouch_status" do
        it "should redirect to the root_path" do
          get :GET_verify_onetouch_status
          expect(response).to redirect_to(root_path)
        end

        it "should not request the one touch status" do
          expect(Verify::OneTouch).not_to receive(:approval_request_status)
          get :GET_verify_onetouch_status
        end
      end
    end
  end

  describe "when the first step of authentication is complete" do
    before do
      request.session["user_id"] = user.id
      request.session["user_password_checked"] = true
    end

    describe "GET #verify_verify" do
      it "Should render the second step of authentication" do
        get :GET_verify_verify
        expect(response).to render_template('verify_verify')
      end

      it "should not make a OneTouch request" do
        expect(Verify::OneTouch).not_to receive(:send_approval_request)
        get :GET_verify_verify
      end

      describe "when OneTouch is enabled" do
        before(:each) do
          Devise.verify_enable_onetouch = true
        end

        after(:each) do
          Devise.verify_enable_onetouch = false
        end

        it "should make a OneTouch request and assign the uuid" do
          expect(Verify::OneTouch).to receive(:send_approval_request)
                                 .with(id: user.verify_id, message: 'Request to Login')
                                 .and_return('approval_request' => { 'uuid' => 'uuid' }).once
          get :GET_verify_verify
          expect(assigns[:onetouch_uuid]).to eq('uuid')
        end
      end
    end

    describe "POST #verify_verify" do
      let(:verify_success) { double("Verify::Response", :ok? => true) }
      let(:verify_failure) { double("Verify::Response", :ok? => false) }
      let(:valid_verify_token) { rand(0..999999).to_s.rjust(6, '0') }
      let(:invalid_verify_token) { rand(0..999999).to_s.rjust(6, '0') }

      describe "with a valid token" do
        before(:each) {
          expect(Verify::API).to receive(:verify).with({
            :id => user.verify_id,
            :token => valid_verify_token,
            :force => true
          }).and_return(verify_success)
        }

        describe "without remembering" do
          before(:each) {
            post :POST_verify_verify, params: { :token => valid_verify_token }
          }

          it "should log the user in" do
            expect(subject.current_user).to eq(user)
            expect(session["user_verify_token_checked"]).to be true
          end

          it "should set the last_sign_in_with_verify field on the user" do
            expect(user.last_sign_in_with_verify).to be_nil
            user.reload
            expect(user.last_sign_in_with_verify).not_to be_nil
            expect(user.last_sign_in_with_verify).to be_within(1).of(Time.zone.now)
          end

          it "should redirect to the root_path and set a flash notice" do
            expect(response).to redirect_to(root_path)
            expect(flash[:notice]).not_to be_nil
            expect(flash[:error]).to be nil
          end

          it "should not set a remember_device cookie" do
            expect(cookies["remember_device"]).to be_nil
          end

          it "should not remember the user" do
            user.reload
            expect(user.remember_created_at).to be nil
          end
        end

        describe "and remember device selected" do
          before(:each) {
            post :POST_verify_verify, params: {
              :token => valid_verify_token,
              :remember_device => '1'
            }
          }

          it "should set a signed remember_device cookie" do
            jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
            cookie = jar.signed["remember_device"]
            expect(cookie).not_to be_nil
            parsed_cookie = JSON.parse(cookie)
            expect(parsed_cookie["id"]).to eq(user.id)
          end
        end

        describe "and remember_me in the session" do
          before(:each) do
            request.session["user_remember_me"] = true
            post :POST_verify_verify, params: { :token => valid_verify_token }
          end

          it "should remember the user" do
            user.reload
            expect(user.remember_created_at).to be_within(1).of(Time.zone.now)
          end
        end
      end

      describe "with an invalid token" do
        before(:each) {
          expect(Verify::API).to receive(:verify).with({
            :id => user.verify_id,
            :token => invalid_verify_token,
            :force => true
          }).and_return(verify_failure)
          post :POST_verify_verify, params: { :token => invalid_verify_token }
        }

        it "Shouldn't log the user in" do
          expect(subject.current_user).to be nil
        end

        it "should redirect to the verification page" do
          expect(response).to render_template('verify_verify')
        end

        it "should set an error message in the flash" do
          expect(flash[:notice]).to be nil
          expect(flash[:error]).not_to be nil
        end
      end

      describe 'with a lockable user' do
        let(:lockable_user) { create(:lockable_verify_user) }
        before(:all) { Devise.lock_strategy = :failed_attempts }

        before(:each) do
          request.session["user_id"] = lockable_user.id
          request.session["user_password_checked"] = true
        end

        it 'locks the account when failed_attempts exceeds maximum' do
          expect(Verify::API).to receive(:verify).exactly(Devise.maximum_attempts).times.with({
            :id => lockable_user.verify_id,
            :token => invalid_verify_token,
            :force => true
          }).and_return(verify_failure)
          (Devise.maximum_attempts).times do
            post :POST_verify_verify, params: { token: invalid_verify_token }
          end

          lockable_user.reload
          expect(lockable_user.access_locked?).to be true
        end
      end

      describe 'with a user that is not lockable' do
        it 'does not lock the account when failed_attempts exceeds maximum' do
          request.session['user_id']               = user.id
          request.session['user_password_checked'] = true

          expect(Verify::API).to receive(:verify).exactly(Devise.maximum_attempts).times.with({
            :id => user.verify_id,
            :token => invalid_verify_token,
            :force => true
          }).and_return(verify_failure)

          Devise.maximum_attempts.times do
            post :POST_verify_verify, params: { token: invalid_verify_token }
          end

          user.reload
          expect(user.locked_at).to be_nil
        end
      end
    end

    describe "GET #verify_onetouch_status" do
      let(:uuid) { SecureRandom.uuid }

      it "should return a 202 status code when pending" do
        allow(Verify::OneTouch).to receive(:approval_request_status)
          .with(:uuid => uuid)
          .and_return({ 'approval_request' => { 'status' => 'pending' }})
        get :GET_verify_onetouch_status, params: { onetouch_uuid: uuid }
        expect(response.code).to eq("202")
      end

      it "should return a 401 status code when denied" do
        allow(Verify::OneTouch).to receive(:approval_request_status)
        .with(:uuid => uuid)
          .and_return({ 'approval_request' => { 'status' => 'denied' }})
        get :GET_verify_onetouch_status, params: { onetouch_uuid: uuid }
        expect(response.code).to eq("401")
      end

      it "should return a 500 status code when something else happens" do
        allow(Verify::OneTouch).to receive(:approval_request_status)
        .with(:uuid => uuid)
          .and_return({})
        get :GET_verify_onetouch_status, params: { onetouch_uuid: uuid }
        expect(response.code).to eq("500")
      end

      describe "when approved" do
        before(:each) do
          allow(Verify::OneTouch).to receive(:approval_request_status)
            .with(:uuid => uuid)
            .and_return({ 'approval_request' => { 'status' => 'approved' }})
          get :GET_verify_onetouch_status, params: { onetouch_uuid: uuid, remember_device: '0' }
        end

        it "should return a 200 status code" do
          expect(response.code).to eq("200")
        end

        it "should render a JSON object with the redirect path" do
          expect(response.body).to eq({ redirect: root_path }.to_json)
        end

        it "should not remember the user" do
          expect(cookies["remember_device"]).to be_nil
        end

        it "should sign the user in" do
          expect(subject.current_user).to eq(user)
          expect(session["user_verify_token_checked"]).to be true
          user.reload
          expect(user.last_sign_in_with_verify).to be_within(1).of(Time.zone.now)
        end
      end

      describe "when approved and 2fa remembered" do
        before(:each) do
          allow(Verify::OneTouch).to receive(:approval_request_status)
            .with(:uuid => uuid)
            .and_return({ 'approval_request' => { 'status' => 'approved' }})
          get :GET_verify_onetouch_status, params: { onetouch_uuid: uuid, remember_device: '1' }
        end

        it "should return a 200 status code" do
          expect(response.code).to eq("200")
        end

        it "should render a JSON object with the redirect path" do
          expect(response.body).to eq({ redirect: root_path }.to_json)
        end

        it "should set a signed remember_device cookie" do
          jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
          cookie = jar.signed["remember_device"]
          expect(cookie).not_to be_nil
          parsed_cookie = JSON.parse(cookie)
          expect(parsed_cookie["id"]).to eq(user.id)
        end

        it "should sign the user in" do
          expect(subject.current_user).to eq(user)
          expect(session["user_verify_token_checked"]).to be true
          user.reload
          expect(user.last_sign_in_with_verify).to be_within(1).of(Time.zone.now)
        end
      end

      describe "when approved and remember_me in the session" do
        before(:each) do
          request.session["user_remember_me"] = true
          allow(Verify::API).to receive(:get_request)
            .with("onetouch/json/approval_requests/#{uuid}")
            .and_return({ 'approval_request' => { 'status' => 'approved' }})
          get :GET_verify_onetouch_status, params: { onetouch_uuid: uuid, remember_device: '0' }
        end

        it "should remember the user" do
          user.reload
          expect(user.remember_created_at).to be_within(1).of(Time.zone.now)
        end
      end
    end
  end

  describe "enabling/disabling verify" do
    describe "with no-one logged in" do
      it "GET #enable_verify should redirect to sign in" do
        get :GET_enable_verify
        expect(response).to redirect_to(new_user_session_path)
      end

      it "POST #enable_verify should redirect to sign in" do
        post :POST_enable_verify
        expect(response).to redirect_to(new_user_session_path)
      end

      it "GET #verify_verify_installation should redirect to sign in" do
        get :GET_verify_verify_installation
        expect(response).to redirect_to(new_user_session_path)
      end

      it "POST #verify_verify_installation should redirect to sign in" do
        post :POST_verify_verify_installation
        expect(response).to redirect_to(new_user_session_path)
      end

      it "POST #disable_verify should redirect to sign in" do
        post :POST_disable_verify
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    describe "with a logged in user" do
      before(:each) { sign_in(user) }

      describe "GET #enable_verify" do
        it "should render enable verify view if user isn't enabled" do
          user.update_attribute(:verify_enabled, false)
          get :GET_enable_verify
          expect(response).to render_template("enable_verify")
        end

        it "should render enable verify view if user doens't have an verify_id" do
          user.update_attribute(:verify_id, nil)
          get :GET_enable_verify
          expect(response).to render_template("enable_verify")
        end

        it "should redirect and set flash if verify is enabled" do
          user.update_attribute(:verify_enabled, true)
          get :GET_enable_verify
          expect(response).to redirect_to(root_path)
          expect(flash[:notice]).not_to be nil
        end
      end

      describe "POST #enable_verify" do
        let(:user) { create(:user) }
        let(:cellphone) { '3010008090' }
        let(:country_code) { '57' }

        describe "with a successful registration to Verify" do
          before(:each) do
            expect(Verify::API).to receive(:register_user).with(
              :email => user.email,
              :cellphone => cellphone,
              :country_code => country_code
            ).and_return(double("Verify::User", :ok? => true, :id => "123"))
            post :POST_enable_verify, :params => { :cellphone => cellphone, :country_code => country_code }
          end

          it "save the verify_id to the user" do
            user.reload
            expect(user.verify_id).to eq("123")
          end

          it "should not enable the user yet" do
            user.reload
            expect(user.verify_enabled).to be(false)
          end

          it "should redirect to the verification page" do
            expect(response).to redirect_to(user_verify_verify_installation_path)
          end
        end

        describe "but a user that can't be saved" do
          before(:each) do
            expect(user).to receive(:save).and_return(false)
            expect(subject).to receive(:current_user).and_return(user)
            expect(Verify::API).to receive(:register_user).with(
              :email => user.email,
              :cellphone => cellphone,
              :country_code => country_code
            ).and_return(double("Verify::User", :ok? => true, :id => "123"))
            post :POST_enable_verify, :params => { :cellphone => cellphone, :country_code => country_code }
          end

          it "should set an error flash" do
            expect(flash[:error]).not_to be nil
          end

          it "should redirect" do
            expect(response).to redirect_to(root_path)
          end
        end

        describe "with an unsuccessful registration to Verify" do
          before(:each) do
            expect(Verify::API).to receive(:register_user).with(
              :email => user.email,
              :cellphone => cellphone,
              :country_code => country_code
            ).and_return(double("Verify::User", :ok? => false))

            post :POST_enable_verify, :params => { :cellphone => cellphone, :country_code => country_code }
          end

          it "does not update the verify_id" do
            old_verify_id = user.verify_id
            user.reload
            expect(user.verify_id).to eq(old_verify_id)
          end

          it "shows an error flash" do
            expect(flash[:error]).to eq("Something went wrong while enabling two factor authentication")
          end

          it "renders enable_verify page again" do
            expect(response).to render_template('enable_verify')
          end
        end
      end

      describe "GET verify_verify_installation" do
        describe "with a user that hasn't enabled verify yet" do
          let(:user) { create(:user) }
          before(:each) { sign_in(user) }

          it "should redirect to enable verify" do
            get :GET_verify_verify_installation
            expect(response).to redirect_to user_enable_verify_path
          end
        end

        describe "with a user that has enabled verify" do
          it "should redirect to after verify verified path" do
            get :GET_verify_verify_installation
            expect(response).to redirect_to root_path
          end
        end

        describe "with a user with an verify id without verify enabled" do
          before(:each) { user.update_attribute(:verify_enabled, false) }

          it "should render the verify verification page" do
            get :GET_verify_verify_installation
            expect(response).to render_template('verify_verify_installation')
          end

          describe "with qr codes turned on" do
            before(:each) do
              Devise.verify_enable_qr_code = true
            end

            after(:each) do
              Devise.verify_enable_qr_code = false
            end

            it "should hit API for a QR code" do
              expect(Verify::API).to receive(:request_qr_code).with(
                :id => user.verify_id
              ).and_return(double("Verify::Request", :qr_code => 'https://example.com/qr.png'))

              get :GET_verify_verify_installation
              expect(response).to render_template('verify_verify_installation')
              expect(assigns[:verify_qr_code]).to eq('https://example.com/qr.png')
            end
          end
        end
      end

      describe "POST verify_verify_installation" do
        let(:token) { "000000" }

        describe "with a user without an verify id" do
          let(:user) { create(:user) }
          it "redirects to enable path" do
            post :POST_verify_verify_installation, :params => { :token => token }
            expect(response).to redirect_to(user_enable_verify_path)
          end
        end

        describe "with a user that has an verify id and is enabled" do
          it "redirects to after verify verified path" do
            post :POST_verify_verify_installation, :params => { :token => token }
            expect(response).to redirect_to(root_path)
          end
        end

        describe "with a user that has an verify id but isn't enabled" do
          before(:each) { user.update_attribute(:verify_enabled, false) }

          describe "successful verification" do
            before(:each) do
              expect(Verify::API).to receive(:verify).with({
                :id => user.verify_id,
                :token => token,
                :force => true
              }).and_return(double("Verify::Response", :ok? => true))
              post :POST_verify_verify_installation, :params => { :token => token, :remember_device => '0' }
            end

            it "should enable verify for user" do
              user.reload
              expect(user.verify_enabled).to be true
            end

            it "should set {resource}_verify_token_checked in the session" do
              expect(session["user_verify_token_checked"]).to be true
            end

            it "should set a flash notice and redirect" do
              expect(response).to redirect_to(root_path)
              expect(flash[:notice]).to eq('Two factor authentication was enabled')
            end

            it "should not set a remember_device cookie" do
              expect(cookies["remember_device"]).to be_nil
            end
          end

          describe "successful verification with remember device" do
            before(:each) do
              expect(Verify::API).to receive(:verify).with({
                :id => user.verify_id,
                :token => token,
                :force => true
              }).and_return(double("Verify::Response", :ok? => true))
              post :POST_verify_verify_installation, :params => { :token => token, :remember_device => '1' }
            end

            it "should enable verify for user" do
              user.reload
              expect(user.verify_enabled).to be true
            end
            it "should set {resource}_verify_token_checked in the session" do
              expect(session["user_verify_token_checked"]).to be true
            end
            it "should set a flash notice and redirect" do
              expect(response).to redirect_to(root_path)
              expect(flash[:notice]).to eq('Two factor authentication was enabled')
            end

            it "should set a signed remember_device cookie" do
              jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
              cookie = jar.signed["remember_device"]
              expect(cookie).not_to be_nil
              parsed_cookie = JSON.parse(cookie)
              expect(parsed_cookie["id"]).to eq(user.id)
            end
          end

          describe "unsuccessful verification" do
            before(:each) do
              expect(Verify::API).to receive(:verify).with({
                :id => user.verify_id,
                :token => token,
                :force => true
              }).and_return(double("Verify::Response", :ok? => false))
              post :POST_verify_verify_installation, :params => { :token => token }
            end

            it "should not enable verify for user" do
              user.reload
              expect(user.verify_enabled).to be false
            end

            it "should set an error flash and render verify_verify_installation" do
              expect(response).to render_template('verify_verify_installation')
              expect(flash[:error]).to eq('Something went wrong while enabling two factor authentication')
            end
          end

          describe "unsuccessful verification with qr codes turned on" do
            before(:each) do
              Devise.verify_enable_qr_code = true
            end

            after(:each) do
              Devise.verify_enable_qr_code = false
            end

            it "should hit API for a QR code" do
              expect(Verify::API).to receive(:verify).with({
                :id => user.verify_id,
                :token => token,
                :force => true
              }).and_return(double("Verify::Response", :ok? => false))
              expect(Verify::API).to receive(:request_qr_code).with(
                :id => user.verify_id
              ).and_return(double("Verify::Request", :qr_code => 'https://example.com/qr.png'))

              post :POST_verify_verify_installation, :params => { :token => token }
              expect(response).to render_template('verify_verify_installation')
              expect(assigns[:verify_qr_code]).to eq('https://example.com/qr.png')
            end
          end
        end
      end

      describe "POST disable_verify" do
        describe "successfully" do
          before(:each) do
            cookies.signed[:remember_device] = {
              :value => {expires: Time.now.to_i, id: user.id}.to_json,
              :secure => false,
              :expires => User.verify_remember_device.from_now
            }
            expect(Verify::API).to receive(:delete_user)
              .with(:id => user.verify_id)
              .and_return(double("Verify::Response", :ok? => true))

            post :POST_disable_verify
          end

          it "should disable 2FA" do
            user.reload
            expect(user.verify_id).to be nil
            expect(user.verify_enabled).to be false
          end

          it "should forget the device cookie" do
            expect(response.cookies[:remember_device]).to be nil
          end

          it "should set a flash notice and redirect" do
            expect(flash.now[:notice]).to eq("Two factor authentication was disabled")
            expect(response).to redirect_to(root_path)
          end
        end

        describe "with more than one user using the same verify_id" do
          # It is valid for more than one user to share an verify_id
          # https://github.com/twilio/verify-devise/issues/143
          before(:each) do
            @other_user = create(:verify_user, :verify_id => user.verify_id)
            cookies.signed[:remember_device] = {
              :value => {expires: Time.now.to_i, id: user.id}.to_json,
              :secure => false,
              :expires => User.verify_remember_device.from_now
            }
            expect(Verify::API).not_to receive(:delete_user)

            post :POST_disable_verify
          end

          it "should disable 2FA" do
            user.reload
            expect(user.verify_id).to be nil
            expect(user.verify_enabled).to be false
          end

          it "should forget the device cookie" do
            expect(response.cookies[:remember_device]).to be nil
          end

          it "should set a flash notice and redirect" do
            expect(flash.now[:notice]).to eq("Two factor authentication was disabled")
            expect(response).to redirect_to(root_path)
          end
        end

        describe "unsuccessfully" do
          before(:each) do
            cookies.signed[:remember_device] = {
              :value => {expires: Time.now.to_i, id: user.id}.to_json,
              :secure => false,
              :expires => User.verify_remember_device.from_now
            }
            expect(Verify::API).to receive(:delete_user)
              .with(:id => user.verify_id)
              .and_return(double("Verify::Response", :ok? => false))

            post :POST_disable_verify
          end

          it "should not disable 2FA" do
            user.reload
            expect(user.verify_id).not_to be nil
            expect(user.verify_enabled).to be true
          end

          it "should not forget the device cookie" do
            expect(cookies[:remember_device]).not_to be_nil
          end

          it "should set a flash error and redirect" do
            expect(flash[:error]).to eq("Something went wrong while disabling two factor authentication")
            expect(response).to redirect_to(root_path)
          end
        end
      end
    end
  end

  describe "requesting authentication tokens" do
    describe "without a user" do
      it "Should not request sms if user couldn't be found" do
        expect(Verify::API).not_to receive(:request_sms)

        post :request_sms

        expect(response.media_type).to eq('application/json')
        body = JSON.parse(response.body)
        expect(body['sent']).to be false
        expect(body['message']).to eq("User couldn't be found.")
      end

      it "Should not request a phone call if user couldn't be found" do
        expect(Verify::API).not_to receive(:request_phone_call)

        post :request_phone_call

        expect(response.media_type).to eq('application/json')
        body = JSON.parse(response.body)
        expect(body['sent']).to be false
        expect(body['message']).to eq("User couldn't be found.")
      end
    end

    describe "#request_sms" do
      before(:each) do
        expect(Verify::API).to receive(:request_sms)
          .with(:id => user.verify_id, :force => true)
          .and_return(
            double("Verify::Response", :ok? => true, :message => "Token was sent.")
          )
      end
      describe "with a logged in user" do
        before(:each) { sign_in user }

        it "should send an SMS and respond with JSON" do
          post :request_sms
          expect(response.media_type).to eq('application/json')
          body = JSON.parse(response.body)

          expect(body['sent']).to be_truthy
          expect(body['message']).to eq("Token was sent.")
        end
      end

      describe "with a user_id in the session" do
        before(:each) { session["user_id"] = user.id }

        it "should send an SMS and respond with JSON" do
          post :request_sms
          expect(response.media_type).to eq('application/json')
          body = JSON.parse(response.body)

          expect(body['sent']).to be_truthy
          expect(body['message']).to eq("Token was sent.")
        end
      end
    end

    describe "#request_phone_call" do
      before(:each) do
        expect(Verify::API).to receive(:request_phone_call)
          .with(:id => user.verify_id, :force => true)
          .and_return(
            double("Verify::Response", :ok? => true, :message => "Token was sent.")
          )
      end
      describe "with a logged in user" do
        before(:each) { sign_in user }

        it "should send an SMS and respond with JSON" do
          post :request_phone_call
          expect(response.media_type).to eq('application/json')
          body = JSON.parse(response.body)

          expect(body['sent']).to be_truthy
          expect(body['message']).to eq("Token was sent.")
        end
      end

      describe "with a user_id in the session" do
        before(:each) { session["user_id"] = user.id }

        it "should send an SMS and respond with JSON" do
          post :request_phone_call
          expect(response.media_type).to eq('application/json')
          body = JSON.parse(response.body)

          expect(body['sent']).to be_truthy
          expect(body['message']).to eq("Token was sent.")
        end
      end
    end
  end
end
