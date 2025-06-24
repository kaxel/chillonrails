require 'rails/generators'
require 'rails/generators/actions'

class Base < Rails::Generators::Base
  source_root File.expand_path('..', __dir__)

  def rails(command)
    run("rails #{command}")
  end

  def bundle_install
    run 'bundle install'
  end

  def update_database
    # Run database migrations
    rails_command "db:migrate"

    # Keep the test database in sync
    rails_command "db:test:prepare"
  end

  def cops_autofix
    run 'bundle exec rubocop -a'
  end
end

class CommonGems < Base
  def execute
    add_common_development_gems
    run 'bundle outdated' # Check if there are any outdated gems (May want to remove this from template as it requires installation of the gem before running)
    setup_rspec
    setup_rubocop
    setup_guard
    setup_factory_bot
    cops_autofix
  end

  private

  # Add gems for RSpec, Rubocop, FactoryBot, and Guard
  def add_common_development_gems

    # group :test do
    # gem 'shoulda-matchers', '~> 6.0'

    inject_into_file 'Gemfile', after: "group :development, :test do\n" do
      <<-GEMS
  gem 'rspec-rails', '~> 7.0'
  gem 'factory_bot_rails', '~> 6.0'
  gem 'guard', '~> 2.0'
  gem 'guard-rspec', '~> 4.7'
  gem 'rubocop', '~> 1.0', require: false
  gem 'rubocop-rails', '~> 2.0', require: false
      GEMS
    end
  end

  # Set up RSpec by generating the necessary files and configuring RSpec
  def setup_rspec
    generate 'rspec:install'
    append_to_file '.rspec', '--format documentation'

    # Add FactoryBot configuration to RSpec
    inject_into_file 'spec/rails_helper.rb', after: "RSpec.configure do |config|\n" do
      "  config.include FactoryBot::Syntax::Methods\n"
    end
  end

  # Set up Rubocop by creating a basic .rubocop.yml file
  def setup_rubocop
    create_file '.rubocop.yml', force: true do
      <<-YML
# Omakase Ruby styling for Rails
inherit_gem:
  rubocop-rails-omakase: rubocop.yml

require:
  - rubocop-rails

AllCops:
  TargetRubyVersion: 3.0
  Exclude:
    - 'db/schema.rb'
    - 'bin/*'
    - 'node_modules/**/*'
    - 'config/**/*'
    - 'vendor/**/*'

Layout/LineLength:
  Max: 200

Rails:
  Enabled: true
      YML
    end
  end

  # Initialize Guard for automatic test running
  def setup_guard
    run 'bundle exec guard init rspec'
  end

  # Additional setup for FactoryBot (optional, since it is already configured with RSpec)
  def setup_factory_bot
    # FactoryBot is configured with RSpec
  end
end

class HomePage < Base
  def execute
    generate "controller", "home index --skip-routes"
    set_root_to_home
    add_view
  end

  def set_root_to_home
    gsub_file 'config/routes.rb', /# root "posts#index"/, 'root "home#index"'
  end
  
  def add_view
    create_file 'app/views/home/index.html.erb', force: true do
      <<-ERB
<div class="min-h-screen flex flex-col justify-center items-center bg-gradient-to-r from-indigo-100 via-purple-100 to-pink-100 px-4">
  <div class="bg-white p-8 sm:p-12 rounded-lg shadow-xl w-full max-w-screen-lg mx-auto text-center">
    <h1 class="text-4xl sm:text-5xl font-extrabold text-gray-900 mb-6 sm:mb-8">Rails 8 - Basic Auth</h1>
    <p class="text-base sm:text-lg text-gray-600 mb-6 sm:mb-8">
      A platform to explore Rails 8 features. Use the links below to navigate.
    </p>

<!-- Link Pages -->

<!-- Link Letter Opener -->

  </div>
</div>
      ERB
    end
  end
end

class Layout < Base

  def execute
    update_application_layout
    add_menu
  end

  def add_menu
    create_file 'app/views/shared/_menu.html.erb', <<-ERB
<ul class="w-64 text-lg font-semibold text-gray-700">
  <li class="border border-gray-300 rounded-lg hover:shadow-lg transition-shadow duration-200">
    <%= link_to 'Home', root_path, class: "block px-6 py-3 text-center hover:bg-blue-500 hover:text-white rounded-lg" %>
  </li>

  <% if Rails.application.routes.url_helpers.respond_to?(:pages_about_path) %>
    <li class="border border-gray-300 rounded-lg hover:shadow-lg transition-shadow duration-200">
      <%= link_to "About Page", pages_about_path, class: "block px-6 py-3 text-center bg-green-100 hover:bg-blue-500 hover:text-white rounded-lg" %>
    </li>
  <% end %>

  <% if Rails.application.routes.url_helpers.respond_to?(:pages_authentification_path) %>
    <li class="border border-gray-300 rounded-lg hover:shadow-lg transition-shadow duration-200">
      <%= link_to "Authentication Page", pages_authentification_path, class: "block px-6 py-3 text-center bg-yellow-100 hover:bg-blue-500 hover:text-white rounded-lg" %>
    </li>
  <% end %>

  <% if Rails.application.routes.url_helpers.respond_to?(:pages_account_path) %>
    <li class="border border-gray-300 rounded-lg hover:shadow-lg transition-shadow duration-200">
      <%= link_to "Account Page", pages_account_path, class: "block px-6 py-3 text-center bg-red-100  hover:bg-blue-500 hover:text-white rounded-lg" %>
    </li>
  <% end %>

  <% if Rails.application.routes.url_helpers.respond_to?(:letter_opener_web_path) && Rails.env.development? %>
    <li class="border border-gray-300 rounded-lg hover:shadow-lg transition-shadow duration-200">
      <%= link_to "Check Email", letter_opener_web_path, target: "_blank", class: "block px-6 py-3 text-center bg-gray-100 hover:bg-blue-500 hover:text-white rounded-lg" %>
    </li>
  <% end %>
</ul>
    ERB
  end

  def update_application_layout
    gsub_file 'app/views/layouts/application.html.erb', /<body[^>]*>(.*?)<\/body>/m do
      <<-ERB
<body>
    <main class="flex justify-center items-center min-h-screen">
      <!-- {Flash} -->
      <%= render 'shared/menu' %>
      <div class="w-full max-w-screen-lg px-4">
        <%= yield %>
      </div>
    </main>
  </body>
      ERB
    end
  end

end

class Flash < Base
  def execute
    add_flash_messages
    add_flash_to_layout
  end

  def add_flash_messages
    create_file 'app/views/shared/_flash.html.erb', <<-ERB
  <% flash.each do |type, message| %>
    <%# Map flash types to corresponding Tailwind CSS classes %>
    <% flash_class = case type
         when "notice" then "bg-green-100 text-green-800 border-green-300"
         when "alert" then "bg-red-100 text-red-800 border-red-300"
         else "bg-gray-100 text-gray-800 border-gray-300"
       end %>
  
    <div class="border-l-4 p-4 mb-4 <%= flash_class %>">
      <p><%= message %></p>
    </div>
  <% end %>
    ERB
  end

  def add_flash_to_layout
    gsub_file 'app/views/layouts/application.html.erb', "<!-- {Flash} -->", "<%= render 'shared/flash' %>"
  end
end

class AppplicationSettings < Base
  def execute
    add_generator_settings
  end

  def add_generator_settings
    gsub_file 'config/application.rb', /config.generators.system_tests = nil/m do
      <<-RUBY
config.generators do |g|
      g.test_framework :rspec,                # Set RSpec as the test framework
                        fixtures: true,       # Generate fixtures (or factories)
                        view_specs: false,    # Generate view specs
                        helper_specs: false,  # Don't generate helper specs
                        routing_specs: false, # Generate routing specs
                        request_specs: true,  # Generate request specs
                        system_tests: nil     # Disable system test generation inside this block

      # Use FactoryBot for generating test data
      g.fixture_replacement :factory_bot, dir: "spec/factories"
      g.helper false                         # Disable helper generation
    end
      RUBY
    end
  end
end

class TopLevelPages < Base
  def execute
    generate "controller", "pages about authentification account"
    create_page_link_partial
    add_page_links_to_home
  end

  def create_page_link_partial
    create_file 'app/views/shared/_page_links.html.erb', <<-ERB
<div class="flex justify-center space-x-4 sm:space-x-6">
  <!-- Link to About Page -->
  <%= link_to "About Page", pages_about_path, class: "bg-green-500 text-white px-4 py-2 rounded-lg hover:bg-green-600 transition duration-200" %>

  <!-- Link to Authentication Page -->
  <%= link_to "Authentication Page", pages_authentification_path, class: "bg-gray-500 text-white px-4 py-2 rounded-lg hover:bg-gray-600 transition duration-200" %>

  <!-- Link to Account Page -->
  <%= link_to "Account Page", pages_account_path, class: "bg-blue-500 text-white px-4 py-2 rounded-lg hover:bg-blue-600 transition duration-200" %>
</div>
    ERB
  end

  def add_page_links_to_home
    gsub_file 'app/views/home/index.html.erb', /<!-- Link Pages -->/, "<%= render 'shared/page_links' %>"
  end
end

class RailsGenerateAuthentication < Base
  def execute
    # Use rails_command to generate authentication
    rails_command("generate authentication")
    update_database
  end
end

class CursorAI < Base
  def execute
    puts "Use CursorAI for this section"
  end
end

class AuthenticationRelaxRestrictions < Base
  def execute
    home_controller_relax_restrictions
    pages_controller_relax_restrictions
  end

  def home_controller_relax_restrictions
    inject_into_file 'app/controllers/home_controller.rb', after: "class HomeController < ApplicationController\n" do
      <<-RUBY
  allow_unauthenticated_access

      RUBY
    end
  end

  def pages_controller_relax_restrictions
    inject_into_file 'app/controllers/pages_controller.rb', after: "class PagesController < ApplicationController\n" do
      <<-RUBY
  # allow_unauthenticated_access only: [:about,:authentification]
  # before_action :resume_session, only: [:authentification]
      RUBY
    end
  end
end

class AutheticationEnhancement < Base
  def execute
    create_registrations_controller
    add_current_user_method_to_application_controller
    setup_registration_view
    add_register_link_to_session_new
    add_registration_routes
    add_user_validations
  end

  def create_registrations_controller
    create_file 'app/controllers/registrations_controller.rb' do
      <<-RUBY
class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: [:new, :create]

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      start_new_session_for(@user)
      redirect_to root_url, notice: "Registered successfully"
    else
      render :new
    end
  end

  private

  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation)
  end
end
      RUBY
    end
  end

  def add_current_user_method_to_application_controller
    inject_into_file 'app/controllers/application_controller.rb', after: "allow_browser versions: :modern\n" do
      <<-RUBY

  helper_method :current_user

  def current_user
    Current.session&.user
  end
      RUBY
    end
  end

  def setup_registration_view
    create_file 'app/views/registrations/new.html.erb', <<-ERB
<div class="mx-auto md:w-2/3 w-full">
  <h1 class="font-bold text-4xl mb-5">Register</h1>

  <%= form_with(model: @user, url: registration_path, local: true, class: "contents") do |form| %>
    <% if @user.errors.any? %>
      <div class="bg-red-50 text-red-500 font-medium p-4 rounded-lg mb-5">
        <h2 class="font-bold mb-3"><%= pluralize(@user.errors.count, "error") %> prohibited this user from being saved:</h2>
        <ul class="list-disc list-inside">
          <% @user.errors.full_messages.each do |message| %>
            <li><%= message %></li>
          <% end %>
        </ul>
      </div>
    <% end %>

    <div class="my-5">
      <%= form.email_field :email_address, required: true, autofocus: true, autocomplete: "username", placeholder: "Enter your email address", value: params[:email_address], class: "block shadow rounded-md border border-gray-400 outline-none px-3 py-2 mt-2 w-full" %>
    </div>

    <div class="my-5">
      <%= form.password_field :password, required: true, autocomplete: "current-password", placeholder: "Enter your password", maxlength: 72, class: "block shadow rounded-md border border-gray-400 outline-none px-3 py-2 mt-2 w-full" %>
    </div>

    <div class="my-5">
      <%= form.password_field :password_confirmation, required: true, autocomplete: "current-password", placeholder: "Confirm password", maxlength: 72, class: "block shadow rounded-md border border-gray-400 outline-none px-3 py-2 mt-2 w-full" %>
    </div>

    <div class="col-span-6 sm:flex sm:items-center sm:gap-4">
      <div class="inline">
        <%= form.submit "Register", class: "rounded-lg py-3 px-5 bg-blue-600 text-white inline-block font-medium cursor-pointer" %>
      </div>

      <div class="mt-4 text-sm text-gray-500 sm:mt-0">
        <%= link_to "Login", new_session_path, class: "text-gray-700 underline" %>
      </div>
    </div>
  <% end %>
</div>
    ERB
  end

  def add_register_link_to_session_new
    inject_into_file 'app/views/sessions/new.html.erb', before: '        <%= link_to "Forgot password?", new_password_path, class: "text-gray-700 underline" %>' do
      <<-ERB
          <%= link_to "Register", new_registration_path %> <br>
      ERB
    end
  end

  def add_registration_routes
    route('resource :registration, only: [:new,:create]')
  end

  def add_user_validations
    inject_into_file 'app/models/user.rb', after: "normalizes :email_address, with: ->(e) { e.strip.downcase }\n" do
      <<-RUBY
  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  # Email Confirmation
      RUBY
    end
  end
end

class AutheticationInfo < Base
  def execute
    display_authentication_info
  end

  def display_authentication_info
    # need to find the <div>****</div>
    create_file 'app/views/pages/authentification.html.erb', force: true do
      <<-ERB
<div class="min-h-screen bg-gray-50 flex items-center justify-center">
  <div class="bg-white shadow-lg rounded-lg p-8 max-w-lg mx-auto border border-gray-200">
    <h1 class="font-bold text-4xl text-gray-900 text-center mb-6">Authentication Details</h1>
  
    <div class="text-center space-y-4">
      <% if current_user %>
        <p class="text-lg text-gray-800 font-semibold">Welcome, <%= current_user.email_address %>!</p>

        <!-- Show confirmation status -->
        <% if current_user.respond_to?(:confirmed?) && !current_user.confirmed? %>
          <p class="text-lg text-yellow-600 font-semibold">Confirm your email address for full access.</p>
        <% end %>

        <%= link_to "Sign Out", session_path, 
            method: :delete, 
            data: { turbo_method: :delete, confirm: "Are you sure?" }, 
            class: "bg-red-500 hover:bg-red-600 text-white font-bold py-2 px-4 rounded-md shadow-md transition duration-200" %>
      <% else %>
        <p class="text-lg text-gray-800">Please sign in to access more features.</p>
        <%= link_to "Sign In", new_session_path, 
            class: "bg-blue-500 hover:bg-blue-600 text-white font-bold py-2 px-4 rounded-md shadow-md transition duration-200" %>
      <% end %>

      <div class="mt-6 text-left">
        <h2 class="text-2xl font-semibold mb-4">Useful Links for Testing:</h2>
        <ul class="space-y-3">
          
          <% if current_user %>
            <!-- Show links when user is signed in -->
            <li>
              <%= link_to "Sign Out", session_path, method: :delete, data: { turbo_method: :delete, confirm: "Are you sure?" }, class: "text-blue-600 hover:underline" %>
            </li>
          <% else %>
            <!-- Show links when user is signed out -->
            <li>
              <%= link_to "Register New User", new_registration_path, class: "text-blue-600 hover:underline" %>
            </li>
            <li>
              <%= link_to "Sign In", new_session_path, class: "text-blue-600 hover:underline" %>
            </li>
          <% end %>

          <!-- Forgot Password link is available for both signed in and signed out users -->
          <li>
            <%= link_to "Forgot Password", new_password_path, class: "text-blue-600 hover:underline" %>
          </li>
        </ul>
      </div>
    </div>
  </div>
</div>
      ERB
    end
  end
end

class AutheticationEmail < Base
  def execute
    generate :migration, 'AddConfirmationToUsers', 'confirmation_token:string:index', 'confirmed_at:datetime'

    add_email_confirmation_to_user

    # THIS IS NOT WORKING, NEED TO INVESTIGATE
    # update_authentication_with_email_support

    update_authentication_require_authentication
    update_authentication_add_request_confirmation
    fix_authentication_signout_edge_case
    update_database
  end

  def add_email_confirmation_to_user
    inject_into_file 'app/models/user.rb', after: "has_secure_password\n" do
      "  has_secure_token :confirmation_token\n"
    end

    inject_into_file 'app/models/user.rb', after: "validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }\n" do
      <<-RUBY

  def confirm!
    update!(confirmed_at: Time.current, confirmation_token: nil)
  end

  def confirmed?
    confirmed_at.present?
  end

  def send_confirmation_instructions
    regenerate_confirmation_token
    UserMailer.confirmation_instructions(self).deliver_now
  end
      RUBY
    end
  end

  # THIS IS NOT WORKING, NEED TO INVESTIGATE
  def update_authentication_with_email_support
    gsub_file 'app/controllers/concerns/authentication.rb', /def authenticated\?\n\s+Current\.session\.present\?\n\s+end\n/m do
      <<-RUBY
      def authenticated?
            Current.session.present? && Current.session.user.confirmed?
          end
      RUBY
    end
  end

  def update_authentication_require_authentication
    gsub_file 'app/controllers/concerns/authentication.rb', /def require_authentication\n\s+resume_session \|\| request_authentication\n\s+end\n/m do
      <<-RUBY
def require_authentication
      if resume_session
        request_confirmation unless Current.session.user.confirmed?
      else
        request_authentication
      end
    end
      RUBY
    end
  end

  def update_authentication_add_request_confirmation
    inject_into_file 'app/controllers/concerns/authentication.rb', before: /\n\s*def request_authentication/ do
      <<-RUBY


    def request_confirmation
      redirect_to root_url, alert: "Please confirm your email address to continue."
    end
      RUBY
    end
  end

  def fix_authentication_signout_edge_case
    gsub_file 'app/controllers/concerns/authentication.rb',
      /Current.session.destroy/m,
      'Current.session&.destroy'

    inject_into_file 'app/controllers/sessions_controller.rb', after: "allow_unauthenticated_access only: %i[ new create ]" do
        "\n  allow_unauthenticated_access only: %i[ destroy ] # edgecase to deal with email confirmations"
    end
  end
end

class AutheticationEmailMailer < Base
  def execute
    generate :mailer, 'UserMailer'

    add_confirmation_instructions_to_user_mailer
    add_confirmation_email_view

    route "get 'confirm_registration', to: 'registrations#confirm'"
    create_registrations_controller_with_confirmation
    update_registration_route
    add_letter_opener_gem
    add_letter_opener_route
    add_letter_opener_configuration
  end

  def add_confirmation_instructions_to_user_mailer
    inject_into_file 'app/mailers/user_mailer.rb', after: "class UserMailer < ApplicationMailer\n" do
      <<-RUBY
  def confirmation_instructions(user)
    @user = user
    @confirmation_url = confirm_registration_url(token: @user.confirmation_token)

    mail(to: @user.email_address, subject: "Confirm your account")
  end
      RUBY
    end
  end

  def add_confirmation_email_view
    create_file 'app/views/user_mailer/confirmation_instructions.html.erb', <<-ERB
<h1>Welcome <%= @user.email_address %>!</h1>

<p>You can confirm your account email through the link below:</p>

<p><%= link_to 'Confirm my account', @confirmation_url %></p>
      ERB
  end

  def create_registrations_controller_with_confirmation
    create_file 'app/controllers/registrations_controller.rb' do
      <<-RUBY
class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: [:new, :create, :confirm]

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      @user.send_confirmation_instructions
      redirect_to root_url, notice: "Please check your email to confirm your account."
    else
      render :new
    end
  end

  def confirm
    @user = User.find_by(confirmation_token: params[:token])

    if @user
      @user.confirm!
      redirect_to root_path, notice: "Your account has been confirmed. Welcome!"
    else
      redirect_to root_path, alert: "Invalid confirmation token."
    end
  end

  private

  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation)
  end
end
      RUBY
    end
  end


  def update_registration_route
    gsub_file 'config/routes.rb', /resource :registration, only: [:new, :create]\n/m do
      <<-RUBY
resource :registration, only: [:new, :create] do
  get :confirm, on: :collection
end
      RUBY
    end
  end

  def add_letter_opener_gem
    inject_into_file 'Gemfile', after: /group :development do/ do
      <<-RUBY

  gem 'letter_opener', '~> 1'
  gem 'letter_opener_web', '~> 3'
      RUBY
    end

    run 'bundle install'
  end

  def add_letter_opener_route
    inject_into_file 'config/routes.rb', after: "Rails.application.routes.draw do\n" do
      <<-RUBY
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?
      RUBY
    end
  end

  # config.action_mailer.default_url_options = { host: "localhost", port: 3000 }
  # config.action_mailer.delivery_method = :letter_opener
  # config.action_mailer.perform_deliveries = true

  def add_letter_opener_configuration
    gsub_file 'config/environments/development.rb', /  config.action_mailer.default_url_options = { host: "localhost", port: 3000 }/m do
      <<-RUBY
  config.action_mailer.default_url_options = { host: "localhost", port: 3000 }
  config.action_mailer.delivery_method = :letter_opener
  config.action_mailer.perform_deliveries = true
      RUBY
    end
  end
end

def run_menu(menu)
  puts "Select an action by number:"
  menu.each do |item|
    puts "#{item[:id]}. #{item[:label]}"
  end

  choice = ask "Enter a number: "
  
  menu_item = menu.find { |item| item[:id] == choice.to_i }

  if menu_item
    puts "Running: #{menu_item[:label]}"

    if menu_item[:customizations]
      menu_item[:customizations].new.execute
    else
      exit_program
    end
  else
    puts "Invalid choice. Please enter a valid number."
  end
end

order = 0
menu = [
  { id: (order+=1), label: 'Common Gems', customizations: CommonGems },
  { id: (order+=1), label: 'Home Page', customizations: HomePage },
  { id: (order+=1), label: 'Layout', customizations: Layout },
  { id: (order+=1), label: 'Flash Messages', customizations: Flash },
  { id: (order+=1), label: 'Application Settings', customizations: AppplicationSettings },
  { id: (order+=1), label: 'Top Level Pages', customizations: TopLevelPages },
  { id: (order+=1), label: 'Rails Generate Authentication', customizations: RailsGenerateAuthentication },
  { id: (order+=1), label: 'Authentication Relax Restrictions', customizations: AuthenticationRelaxRestrictions },
  { id: (order+=1), label: 'AuthenticationEnhancement', customizations: AutheticationEnhancement },
  { id: (order+=1), label: 'Authentication Info', customizations: AutheticationInfo },
  { id: (order+=1), label: 'Move Mailer using Cursor AI', customizations: CursorAI },
  { id: (order+=1), label: 'Authetication Email', customizations: AutheticationEmail },
  { id: (order+=1), label: 'Authetication Email Mailer', customizations: AutheticationEmailMailer },
  { id: 0, label: 'Exit', customizations: nil }
]

run_menu(menu)