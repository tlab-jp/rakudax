require 'simplecov'

if ENV['CODECLIMATE_REPO_TOKEN']
  puts "CODECLIMATE_REPO_TOKEN is defined"

if ENV['CODECOV_TOKEN']
  puts "CODECOV_TOKEN is defined"
  require 'codecov'
  SimpleCov.formatter =  SimpleCov::Formatter::Codecov
end

SimpleCov.start do
  add_filter "/vendor/"
  add_filter "/spec/"
end

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'rakudax'
