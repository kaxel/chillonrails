require 'rails_helper'

RSpec.describe "Playlists", type: :request do
  describe "GET /playlist/:slug" do
    it "returns http success for an existing playlist" do
      playlist = create(:playlist, slug: "summer-mix")
      get playlist_path(playlist.slug)
      expect(response).to have_http_status(:success)
    end

    it "redirects to the 404 page for an unknown playlist" do
      get playlist_path("does-not-exist")
      expect(response).to redirect_to("/404")
    end
  end
end
