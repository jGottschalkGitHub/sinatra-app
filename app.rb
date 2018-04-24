require 'sinatra'
require 'sequel'
require 'yaml'
require 'mysql2'
require 'pry'
require 'digest'
require 'better_errors'
require_relative 'lib/routes'

class Todo < Sinatra::Application
  set :environment, :development
  register Sinatra::Flash
  enable :sessions

  configure do
    # DB = Sequel.connect("mysql2://root:pass@mysql.getapp.docker/todo")
  end
  env = ENV['RACK_ENV'] || 'development'
  DB = Sequel.connect(YAML.load(File.open('database.yml'))[env])

  Sequel::Model.raise_on_save_failure = false
  # Sequel plugins loaded by ALL models.
  Sequel::Model.plugin :validation_helpers

  Dir[File.join(File.dirname(__FILE__), 'models', '*.rb')].each { |model| require model }
  Dir[File.join(File.dirname(__FILE__), 'lib', '*.rb')].each { |lib| load lib }
end
