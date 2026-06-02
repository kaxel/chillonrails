require 'rails_helper'

RSpec.describe "Pages", type: :request do
  describe "GET /about" do
    it "returns http success" do
      get "/pages/about"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /authentication" do
    it "returns http success" do
      get "/pages/authentication"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /account" do
    it "redirects unauthenticated visitors to sign in" do
      get "/pages/account"
      expect(response).to redirect_to(new_session_path)
    end
  end

  describe "GET /radio" do
    it "returns http success" do
      get "/pages/radio"
      expect(response).to have_http_status(:success)
    end
  end
end
