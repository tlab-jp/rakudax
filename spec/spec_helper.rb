require 'simplecov'

if ENV['CODECOV_TOKEN']
  require 'codecov'
  SimpleCov.formatter =  SimpleCov::Formatter::Codecov
end

SimpleCov.start do
  add_filter "/vendor/"
  add_filter "/spec/"
end

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'rakudax'
