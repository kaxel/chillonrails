require 'rails_helper'

RSpec.describe "Pages", type: :request do
  describe "GET /about" do
    it "returns http success" do
      get "/pages/about"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /authentification" do
    it "returns http success" do
      get "/pages/authentification"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /account" do
    it "returns http success" do
      get "/pages/account"
      expect(response).to have_http_status(:success)
    end
  end

end
