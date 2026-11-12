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

    it "embeds the latest episode's Mixcloud player from player-widget.mixcloud.com" do
      create(:post, topic: "radio", tags: "weekly catch", author: "krister-axel", published_on: Date.new(2026, 10, 21),
        video_link: "https://www.mixcloud.com/chillfiltr/weekly-catch-2026-10-21-kskq/")

      get "/pages/radio"

      iframe = Nokogiri::HTML(response.body).at_css('iframe[title="Mixcloud player"]')
      expect(iframe["src"]).to eq("https://player-widget.mixcloud.com/widget/iframe/?hide_cover=1&light=1&feed=%2Fchillfiltr%2Fweekly-catch-2026-10-21-kskq%2F")
    end
  end
end
