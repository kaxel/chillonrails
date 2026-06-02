require 'rails_helper'

RSpec.describe "Passwords", type: :request do
  describe "GET /passwords/new" do
    it "returns http success" do
      get new_password_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /passwords" do
    it "enqueues a reset email for a known email user" do
      user = create(:user, email_address: "member@example.com")
      expect {
        post passwords_path, params: { email_address: user.email_address }
      }.to have_enqueued_mail(PasswordsMailer, :reset)
      expect(response).to redirect_to(new_session_path)
    end

    it "redirects oauth users to sign in with their provider" do
      create(:user, :oauth, email_address: "oauth@example.com")
      post passwords_path, params: { email_address: "oauth@example.com" }
      expect(response).to redirect_to(new_session_path)
    end

    it "does not reveal whether an unknown email exists" do
      post passwords_path, params: { email_address: "ghost@example.com" }
      expect(response).to redirect_to(new_session_path)
    end
  end

  describe "GET /passwords/:token/edit" do
    it "renders the form for a valid token" do
      user = create(:user)
      get edit_password_path(user.password_reset_token)
      expect(response).to have_http_status(:success)
    end

    it "redirects to new for an invalid token" do
      get edit_password_path("invalid-token")
      expect(response).to redirect_to(new_password_path)
    end
  end

  describe "PUT /passwords/:token" do
    it "updates the password with a valid token" do
      user = create(:user)
      put password_path(user.password_reset_token), params: {
        password: "newpassword456",
        password_confirmation: "newpassword456"
      }
      expect(response).to redirect_to(new_session_path)
      expect(user.reload.authenticate("newpassword456")).to be_truthy
    end
  end
end
