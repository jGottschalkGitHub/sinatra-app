
#This is the file that config.ru loads when the application is executed. 
#This file, in turn, loads all the other files that help it understand the available routes and underlying model:

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
    enable :sessions
   
    configure do
        env = ENV['RACK_ENV'] || 'development'
        #DB = Sequel.connect("mysql2://root:pass@mysql.getapp.docker/todo")
        DB = Sequel.connect(YAML.load(File.open('database.yml'))[env])

        Dir[File.join(File.dirname(__FILE__), 'models', '*.rb')].each { |model| require model }
        Dir[File.join(File.dirname(__FILE__), 'lib', '*.rb')].each { |lib| load lib }
        
    end
end
