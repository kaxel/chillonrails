require 'rails_helper'

RSpec.describe "Errors", type: :request do
  describe "GET /not_found" do
    it "returns http success" do
      get "/errors/not_found"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /internal_server_error" do
    it "returns http success" do
      get "/errors/internal_server_error"
      expect(response).to have_http_status(:success)
    end
  end

  describe "visiting a link that doesn't exist" do
    # No post has this slug. It exercises the real path a dead/typo'd link
    # takes here: the catch-all "/:slug" route sends it to PostsController,
    # which raises ActiveRecord::RecordNotFound; ApplicationController
    # rescues that, stashes the originally-requested URL in the session, and
    # redirects to "/404" — which is where the PageNotFound row gets logged.
    let(:dead_link) { "/this-post-does-not-exist-#{SecureRandom.hex(4)}" }

    it "logs a PageNotFound row for it and renders the 404 page" do
      expect {
        get dead_link
        follow_redirect! while response.redirect?
      }.to change(PageNotFound, :count).by(1)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Page Not Found")
      expect(PageNotFound.last.url).to end_with(dead_link)
    end
  end
end
