require 'simplecov'
require "codeclimate-test-reporter"

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
  SimpleCov::Formatter::HTMLFormatter,
  CodeClimate::TestReporter::Formatter
])
SimpleCov.start do
      add_filter "/vendor/"
      add_filter "/spec/"
end

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'rakudax'
