require "rails_helper"

RSpec.describe "Admin contact messages", type: :request do
  # The app only allows one account to be an admin (see User#admin_email_restriction).
  let(:admin) { create(:user, :confirmed, email_address: "songlistrnet@gmail.com", admin: true) }
  let(:regular_user) { create(:user, :confirmed) }

  # Sign-in is Google/Apple only, so stand in for the session cookie lookup.
  def sign_in_as(user)
    session = create(:session, user: user)
    allow_any_instance_of(ApplicationController).to receive(:find_session_by_cookie).and_return(session)
  end

  def create_message(name: "Jane Doe", message: "Love the station.", delivered: false, created_at: Time.current)
    ContactMessage.create!(
      name: name, email: "#{name.parameterize}@example.com", message: message,
      delivered_at: (created_at if delivered), created_at: created_at
    )
  end

  describe "access" do
    it "sends signed-out visitors to sign in" do
      get admin_contact_messages_path
      expect(response).to redirect_to(new_session_path)
    end

    it "keeps signed-out visitors from reading a single message" do
      message = create_message
      get admin_contact_message_path(message)
      expect(response).to redirect_to(new_session_path)
    end

    it "turns away signed-in users who are not admins" do
      sign_in_as(regular_user)
      get admin_contact_messages_path
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq(I18n.t("authorization.admin_required"))
    end

    it "also turns non-admins away from a single message" do
      message = create_message(message: "private words")
      sign_in_as(regular_user)
      get admin_contact_message_path(message)
      expect(response).to redirect_to(root_path)
      expect(response.body).not_to include("private words")
    end
  end

  describe "GET /admin/contact_messages" do
    before { sign_in_as(admin) }

    it "lists messages newest first" do
      create_message(name: "Older Sender", created_at: 2.days.ago)
      create_message(name: "Newer Sender", created_at: 1.hour.ago)

      get admin_contact_messages_path

      expect(response).to have_http_status(:success)
      expect(response.body.index("Newer Sender")).to be < response.body.index("Older Sender")
    end

    it "marks messages whose email never went out" do
      create_message(name: "Waiting Sender", delivered: false)
      create_message(name: "Sent Sender", delivered: true)

      get admin_contact_messages_path

      expect(response.body).to include("Not sent")
      expect(response.body).to include("Not sent (1)", "All (2)")
    end

    it "can show only the messages that were not sent" do
      create_message(name: "Waiting Sender", delivered: false)
      create_message(name: "Sent Sender", delivered: true)

      get admin_contact_messages_path(filter: "undelivered")

      expect(response.body).to include("Waiting Sender")
      expect(response.body).not_to include("Sent Sender")
    end

    it "says so when there is nothing to show" do
      get admin_contact_messages_path
      expect(response.body).to include("No messages yet.")

      get admin_contact_messages_path(filter: "undelivered")
      expect(response.body).to include("Every message has been sent.")
    end

    it "pages through long lists and tolerates out-of-range pages" do
      30.times { |i| create_message(name: "Sender #{format('%02d', i)}", created_at: i.minutes.ago) }

      get admin_contact_messages_path
      expect(response.body.scan(/Sender \d\d/).uniq.size).to eq(25)
      expect(response.body).to include("Page 1 of 2")

      get admin_contact_messages_path(page: 2)
      expect(response.body.scan(/Sender \d\d/).uniq.size).to eq(5)

      get admin_contact_messages_path(page: 999)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Page 2 of 2")
    end

    it "escapes anything a visitor typed" do
      create_message(name: "<b>Bold</b> Name", message: "<script>alert(1)</script>")

      get admin_contact_messages_path

      expect(response.body).not_to include("<script>alert(1)</script>")
      expect(response.body).not_to include("<b>Bold</b>")
    end
  end

  describe "GET /admin/contact_messages/:id" do
    before { sign_in_as(admin) }

    it "shows the whole message and a way to reply" do
      message = create_message(name: "Jane Doe", message: "Line one.\nLine two.", delivered: true)

      get admin_contact_message_path(message)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Jane Doe", "Line one.", "Line two.", "mailto:jane-doe@example.com")
    end

    it "explains a message that was saved but never sent" do
      message = create_message(delivered: false)

      get admin_contact_message_path(message)

      expect(response.body).to include("Not sent", "hasn't gone out")
    end

    it "escapes the message body" do
      message = create_message(message: "<img src=x onerror=alert(1)>")

      get admin_contact_message_path(message)

      expect(response.body).not_to include("<img src=x")
    end

    it "sends unknown ids to the not-found page" do
      get admin_contact_message_path(id: 0)
      expect(response).to redirect_to("/404")
    end
  end

  describe "navigation" do
    it "shows admins a Messages link in the menu, and nobody else" do
      get root_path
      expect(response.body).not_to include(admin_contact_messages_path)

      sign_in_as(regular_user)
      get root_path
      expect(response.body).not_to include(admin_contact_messages_path)

      sign_in_as(admin)
      get root_path
      expect(response.body).to include(admin_contact_messages_path)
    end
  end
end
