require "rails_helper"

# The test environment turns request forgery protection off, so nothing else exercises the
# login request phase's CSRF check. omniauth-rails_csrf_protection reads its settings from
# ActionController::Base, and Rails 8.1 deprecated the module it used to do that
# (ActiveSupport::Configurable), so pin that the check still works.
RSpec.describe "OmniAuth request-phase CSRF protection", type: :request do
  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    example.run
  ensure
    ActionController::Base.allow_forgery_protection = original
  end

  it "rejects a POST to /auth/google_oauth2 without an authenticity token" do
    post "/auth/google_oauth2"

    expect(response).to have_http_status(:redirect)
    expect(response.location).to include("/auth/failure")
  end

  it "sends a POST carrying the login page's authenticity token on to Google" do
    get new_session_path
    form = Nokogiri::HTML(response.body).at_css("form[action='/auth/google_oauth2']")
    token = form.at_css("input[name=authenticity_token]")["value"]

    post "/auth/google_oauth2", params: { authenticity_token: token }

    expect(response.location).to start_with("https://accounts.google.com/")
  end
end
