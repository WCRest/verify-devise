# frozen_string_literal: true

RSpec.describe Devise::SessionsController, type: :controller do
  before(:each) { request.env["devise.mapping"] = Devise.mappings[:user] }

  describe "signing in" do
    describe "without an verify enabled user" do
      let(:user) { create(:user) }

      it "should sign the user in" do
        post :create, :params => { user: { email: user.email, password: user.password } }
        expect(subject.current_user).to eq(user)
      end

      it "should redirect" do
        post :create, :params => { user: { email: user.email, password: user.password } }
        expect(response).to redirect_to(root_path)
      end
    end

    describe "with an verify enabled user" do
      let(:verify_user) { create(:verify_user) }

      it "should redirect to verify verify path" do
        post :create, :params => { user: { email: verify_user.email, password: verify_user.password } }
        expect(response).to redirect_to user_verify_verify_path
      end

      it "should store id, password_checked in the session" do
        post :create, :params => { user: { email: verify_user.email, password: verify_user.password } }
        expect(session["user_id"]).to eq(verify_user.id)
        expect(session["user_password_checked"]).to be true
        expect(session["user_remember_me"]).to be false
        expect(session["user_return_to"]).to be nil
      end

      it "should store remember me in session if set" do
        post :create, :params => { user: { email: verify_user.email, password: verify_user.password, remember_me: '1' } }
        expect(session["user_id"]).to eq(verify_user.id)
        expect(session["user_password_checked"]).to be true
        expect(session["user_remember_me"]).to be true
        expect(session["user_return_to"]).to be nil
      end

      it "should keep user_return_to if set" do
        post :create, :params => {
          user: {
            email: verify_user.email,
            password: verify_user.password,
            remember_me: "1"
          }
        }, :session => {
          user_return_to: "/dashboard"
        }
        expect(session["user_id"]).to eq(verify_user.id)
        expect(session["user_password_checked"]).to be true
        expect(session["user_remember_me"]).to be true
        expect(session["user_return_to"]).to be "/dashboard"
      end

      it "should not sign the user in yet" do
        post :create, :params => { user: { email: verify_user.email, password: verify_user.password } }
        expect(subject.current_user).to be nil
      end

      it "should sign the user in and redirect to root if user is remembered" do
        cookies.signed[:remember_device] = {
          :value => {expires: Time.now.to_i, id: verify_user.id}.to_json,
          :secure => false,
          :expires => User.verify_remember_device.from_now
        }
        post :create, :params => { user: { email: verify_user.email, password: verify_user.password } }
        expect(subject.current_user).to eq(verify_user)
        expect(response).to redirect_to(root_path)
      end
    end
  end
end