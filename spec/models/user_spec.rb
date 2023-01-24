# frozen_string_literal: true

RSpec.describe User, type: :model do
  describe "with a user with an verify id" do
    let!(:user) { create(:verify_user) }

    describe "User#find_by_verify_id" do
      it "should find the user" do
        expect(User.first).not_to be nil
        expect(User.find_by_verify_id(user.verify_id)).to eq(user)
      end

      it "shouldn't find the user with the wrong id" do
        expect(User.find_by_verify_id('21')).to be nil
      end
    end

    describe "user#with_verify_authentication?" do
      it "should be false when verify isn't enabled" do
        user.verify_enabled = false
        request = double("request")
        expect(user.with_verify_authentication?(request)).to be false
      end
      it "should be true when verify is enabled" do
        user.verify_enabled = true
        request = double("request")
        expect(user.with_verify_authentication?(request)).to be true
      end
    end

  end
  describe "with a user without an verify id" do
    let!(:user) { create(:user) }

    describe "user#with_verify_authentication?" do
      it "should be false regardless of verify_enabled field" do
        request = double("request")
        expect(user.with_verify_authentication?(request)).to be false
        user.verify_enabled = true
        expect(user.with_verify_authentication?(request)).to be false
      end
    end
  end
end