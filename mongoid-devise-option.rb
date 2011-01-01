# Application Generator Template
# Modifies a Rails app to use Mongoid and Devise
# Usage: rails new app_name -m http://github.com/fortuity/rails3-mongoid-devise/raw/master/template.rb

# More info: http://github.com/fortuity/rails3-mongoid-devise/

# If you are customizing this template, you can use any methods provided by Thor::Actions
# http://rdoc.info/rdoc/wycats/thor/blob/f939a3e8a854616784cac1dcff04ef4f3ee5f7ff/Thor/Actions.html
# and Rails::Generators::Actions
# http://github.com/rails/rails/blob/master/railties/lib/rails/generators/actions.rb

puts "Modifying a new Rails app to use Mongoid and Devise..."
puts "Any problems? See http://github.com/fortuity/rails3-mongoid-devise/issues"

#----------------------------------------------------------------------------
# Configure
#----------------------------------------------------------------------------

project_name = destination_root.split('/').last


if yes?('Would you like to use jQuery instead of Prototype? (yes/no)')
  jquery_flag = true
else
  jquery_flag = false
end

if yes?('Do you want to install the Heroku gem so you can deploy to Heroku? (yes/no)')
  heroku_flag = true
else
  heroku_flag = false
end

if yes?('Will you be needing a user system today? (yes/no)')
  devise_flag = true
else
  devise_flag = false
end

#----------------------------------------------------------------------------
# Set up git
#----------------------------------------------------------------------------
puts "setting up source control with 'git'..."
# specific to Mac OS X
append_file '.gitignore' do
  '.DS_Store'
end
git :init
git :add => '.'
git :commit => "-m 'Initial commit of unmodified new Rails app'"

#----------------------------------------------------------------------------
# Remove the usual cruft
#----------------------------------------------------------------------------
puts "removing unneeded files..."
run 'rm config/database.yml'
run 'rm public/index.html'
run 'rm public/favicon.ico'
run 'rm public/images/rails.png'
run 'rm README'
run 'touch README'

puts "banning spiders from your site by changing robots.txt..."
gsub_file 'public/robots.txt', /# User-Agent/, 'User-Agent'
gsub_file 'public/robots.txt', /# Disallow/, 'Disallow'


#----------------------------------------------------------------------------
# Set up rvmrc
#----------------------------------------------------------------------------
puts "setting up rvmrc & gemset"
create_file '.rvmrc' do
  "rvm --create use default@#{project_name} > /dev/null"
end

#----------------------------------------------------------------------------
# Set up rvmrc
#----------------------------------------------------------------------------
create_file "config/setup_load_paths.rb" do <<-FILE
  
  # BUNDLR - SET UP LOAD PATHS

  if ENV['MY_RUBY_HOME'] && ENV['MY_RUBY_HOME'].include?('rvm')
    begin
      rvm_path     = File.dirname(File.dirname(ENV['MY_RUBY_HOME']))
      rvm_lib_path = File.join(rvm_path, 'lib')
      $LOAD_PATH.unshift rvm_lib_path
      require 'rvm'
      RVM.use_from_path! File.dirname(File.dirname(__FILE__))
    rescue LoadError
      # RVM is unavailable at this point.
      raise "RVM ruby lib is currently unavailable."
    end
  end

  # Select the correct item for which you use below.
  # If you're not using bundler, remove it completely.

  # If we're using a Bundler 1.0 beta
  ENV['BUNDLE_GEMFILE'] = File.expand_path('../Gemfile', File.dirname(__FILE__))
  require 'bundler/setup'

  # Or Bundler 0.9...
  ## if File.exist?(".bundle/environment.rb")
  ##   require '.bundle/environment'
  ## else
  ##   require 'rubygems'
  ##   require 'bundler'
  ##   Bundler.setup
  ## end
  
  FILE
end


#----------------------------------------------------------------------------
# Heroku Option
#----------------------------------------------------------------------------
if heroku_flag
  puts "adding Heroku gem to the Gemfile..."
  gem 'heroku', '1.10.6', :group => :development
end

#----------------------------------------------------------------------------
# jQuery Option
#----------------------------------------------------------------------------
if jquery_flag
  gem 'jquery-rails'
end

#----------------------------------------------------------------------------
# Set up Mongoid
#----------------------------------------------------------------------------
puts "setting up Gemfile for Mongoid..."
gsub_file 'Gemfile', /gem \'sqlite3-ruby/, '# gem \'sqlite3-ruby'
append_file 'Gemfile', "\n# Bundle gems needed for Mongoid\n"
gem "mongoid", "2.0.0.beta.19"
gem "bson_ext", "1.1.1"


run "rvm --create use default@#{project_name} > /dev/null"
puts "installing gems (takes a few minutes!)..."
run 'bundle install'

puts "creating 'config/mongoid.yml' Mongoid configuration file..."
run 'rails generate mongoid:config'

puts "modifying 'config/application.rb' file for Mongoid..."
gsub_file 'config/application.rb', /require 'rails\/all'/ do
<<-RUBY
# If you are deploying to Heroku and MongoHQ,
# you supply connection information here.
require 'uri'
if ENV['MONGOHQ_URL']
  mongo_uri = URI.parse(ENV['MONGOHQ_URL'])
  ENV['MONGOID_HOST'] = mongo_uri.host
  ENV['MONGOID_PORT'] = mongo_uri.port.to_s
  ENV['MONGOID_USERNAME'] = mongo_uri.user
  ENV['MONGOID_PASSWORD'] = mongo_uri.password
  ENV['MONGOID_DATABASE'] = mongo_uri.path.gsub('/', '')
end

require 'mongoid/railtie'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'active_resource/railtie'
require 'rails/test_unit/railtie'
RUBY
end

#----------------------------------------------------------------------------
# Tweak config/application.rb for Mongoid
#----------------------------------------------------------------------------
gsub_file 'config/application.rb', /# Configure the default encoding used in templates for Ruby 1.9./ do
<<-RUBY
config.generators do |g|
      g.orm             :mongoid
    end

    # Configure the default encoding used in templates for Ruby 1.9.
RUBY
end

puts "prevent logging of passwords"
gsub_file 'config/application.rb', /:password/, ':password, :password_confirmation'

#----------------------------------------------------------------------------
# Set up jQuery
#----------------------------------------------------------------------------
if jquery_flag
  run 'rm public/javascripts/rails.js'
  puts "replacing Prototype with jQuery"
  # "--ui" enables optional jQuery UI
  run 'rails generate jquery:install'
end

#----------------------------------------------------------------------------
# Set up Devise
#----------------------------------------------------------------------------
if devise_flag
  puts "setting up Gemfile for Devise..."
  append_file 'Gemfile', "\n# Bundle gem needed for Devise\n"
  gem 'devise'
  
  puts "installing Devise gem (takes a few minutes!)..."
  run 'bundle install'
  
  puts "creating 'config/initializers/devise.rb' Devise configuration file..."
  run 'rails generate devise:install'
  run 'rails generate devise:views'
  
  puts "modifying environment configuration files for Devise..."
  gsub_file 'config/environments/development.rb', /# Don't care if the mailer can't send/, '### ActionMailer Config'
  gsub_file 'config/environments/development.rb', /config.action_mailer.raise_delivery_errors = false/ do
  <<-RUBY
  config.action_mailer.default_url_options = { :host => 'localhost:3000' }
    # A dummy setup for development - no deliveries, but logged
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.perform_deliveries = false
    config.action_mailer.raise_delivery_errors = true
    config.action_mailer.default :charset => "utf-8"
  RUBY
  end
  gsub_file 'config/environments/production.rb', /config.i18n.fallbacks = true/ do
  <<-RUBY
  config.i18n.fallbacks = true
  
    config.action_mailer.default_url_options = { :host => 'yourhost.com' }
    ### ActionMailer Config
    # Setup for production - deliveries, no errors raised
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.perform_deliveries = true
    config.action_mailer.raise_delivery_errors = false
    config.action_mailer.default :charset => "utf-8"
  RUBY
  end
  
  puts "creating a User model and modifying routes for Devise..."
  run 'rails generate devise User'
  
  puts "adding a 'name' attribute to the User model"
  gsub_file 'app/models/user.rb', /end/ do
  <<-RUBY
    field :name
    field :username
    validates_presence_of :name, :username
    validates_uniqueness_of :name, :username, :email, :case_sensitive => false
    attr_accessible :name, :username, :email, :password, :password_confirmation, :remember_me
  end
  RUBY
  end
  
  #----------------------------------------------------------------------------
  # Modify Devise views
  #----------------------------------------------------------------------------
  puts "modifying the default Devise user registration to add 'name'..."
     inject_into_file "app/views/devise/registrations/edit.html.erb", :after => "<%= devise_error_messages! %>\n" do
  <<-RUBY
    <p><%= f.label :name %><br />
    <%= f.text_field :name %></p>
    
    <p><%= f.label :username %><br />
    <%= f.text_field :username %></p>
  RUBY
     end
  
     inject_into_file "app/views/devise/registrations/new.html.erb", :after => "<%= devise_error_messages! %>\n" do
  <<-RUBY
    <p><%= f.label :name %><br />
    <%= f.text_field :name %></p>
    
    <p><%= f.label :username %><br />
    <%= f.text_field :username %></p>
  RUBY
     end

#----------------------------------------------------------------------------
# Create a Devise home page
#----------------------------------------------------------------------------
puts "create a home controller and view"
generate(:controller, "home index")
gsub_file 'config/routes.rb', /get \"home\/index\"/, 'root :to => "home#index"'

puts "set up a simple demonstration of Devise"
gsub_file 'app/controllers/home_controller.rb', /def index/ do
<<-RUBY
def index
    @users = User.all
RUBY
end

  append_file 'app/views/home/index.html.erb' do <<-FILE
<% @users.each do |user| %>
  <p>User: <%=link_to user.name, user %></p>
<% end %>
  FILE
  end

#----------------------------------------------------------------------------
# Create a users page
#----------------------------------------------------------------------------
generate(:controller, "users show")
gsub_file 'config/routes.rb', /get \"users\/show\"/, '#get \"users\/show\"'
gsub_file 'config/routes.rb', /devise_for :users/ do
<<-RUBY
devise_for :users
  resources :users, :only => :show
RUBY
end

gsub_file 'app/controllers/users_controller.rb', /def show/ do
<<-RUBY
before_filter :authenticate_user!

  def show
    @user = User.find(params[:id])
RUBY
end

  append_file 'app/views/users/show.html.erb' do <<-FILE
<p>User: <%= @user.name %></p>
  FILE
  end

  create_file "app/views/devise/menu/_login_items.html.erb" do <<-FILE
<% if user_signed_in? %>
  <li>
  <%= link_to('Logout', destroy_user_session_path) %>        
  </li>
<% else %>
  <li>
  <%= link_to('Login', new_user_session_path)  %>  
  </li>
<% end %>
  FILE
  end

  create_file "app/views/devise/menu/_registration_items.html.erb" do <<-FILE
<% if user_signed_in? %>
  <li>
  <%= link_to('Edit account', edit_user_registration_path) %>
  </li>
<% else %>
  <li>
  <%= link_to('Sign up', new_user_registration_path)  %>
  </li>
<% end %>
  FILE
  end

#----------------------------------------------------------------------------
# Generate Application Layout
#----------------------------------------------------------------------------

  inject_into_file 'app/views/layouts/application.html.erb', :after => "<body>\n" do
  <<-RUBY
<ul class="hmenu">
  <%= render 'devise/menu/registration_items' %>
  <%= render 'devise/menu/login_items' %>
</ul>
<p style="color: green"><%= notice %></p>
<p style="color: red"><%= alert %></p>
RUBY
  end
end 

#----------------------------------------------------------------------------
# Add Stylesheets
#----------------------------------------------------------------------------
create_file 'public/stylesheets/application.css' do <<-FILE
ul.hmenu {
  list-style: none;	
  margin: 0 0 2em;
  padding: 0;
}

ul.hmenu li {
  display: inline;  
}
FILE
end

#----------------------------------------------------------------------------
# Create a default user
#----------------------------------------------------------------------------
if devise_flag
  puts "creating a default user"
  append_file 'db/seeds.rb' do <<-FILE
  puts 'EMPTY THE MONGODB DATABASE'
  Mongoid.master.collections.reject { |c| c.name == 'system.indexes'}.each(&:drop)
  puts 'SETTING UP DEFAULT USER LOGIN'
  user = User.create! :name => 'Micah Rich', :username => 'moocha', :email => 'micah@micahrich.com', :password => 'russell', :password_confirmation => 'russell'
  puts 'New user created: ' << user.name
  FILE
  end
  run 'rake db:seed'
end

#----------------------------------------------------------------------------
# Finish up
#----------------------------------------------------------------------------
puts "checking everything into git..."
git :add => '.'
git :commit => "-am 'modified Rails app to use Mongoid and Devise'"

puts "Done setting up your Rails app with Mongoid and Devise."
