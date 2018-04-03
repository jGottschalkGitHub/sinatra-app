require 'sinatra'
require 'bundler/setup'
Bundler.require

ENV["RACK_ENV"] = "development"

require File.join(File.dirname(__FILE__), 'app.rb')

Todo.start!
