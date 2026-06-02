require 'rails_helper'

RSpec.describe "Registrations", type: :request do
  describe "GET /registration/new" do
    it "returns http success" do
      get new_registration_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /registration" do
    it "creates a user and sends confirmation instructions" do
      expect {
        post registration_path, params: { user: {
          email_address: "newbie@example.com",
          password: "password123",
          password_confirmation: "password123"
        } }
      }.to change(User, :count).by(1)

      expect(response).to redirect_to(root_url)
      expect(ActionMailer::Base.deliveries.last.to).to eq([ "newbie@example.com" ])
    end

    it "re-renders the form on invalid input" do
      post registration_path, params: { user: { email_address: "bad", password: "" } }
      expect(response).to have_http_status(:unprocessable_entity).or have_http_status(:success)
      expect(User.find_by(email_address: "bad")).to be_nil
    end
  end

  describe "GET /registration/confirm" do
    it "confirms a user with a valid token" do
      user = create(:user)
      get confirm_registration_path(token: user.confirmation_token)
      expect(response).to redirect_to(root_path)
      expect(user.reload).to be_confirmed
    end

    it "rejects an invalid token" do
      get confirm_registration_path(token: "nope")
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq(I18n.t("registrations.invalid_confirmation_token"))
    end
  end
end
