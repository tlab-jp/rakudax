require 'simplecov'

SimpleCov.start do
      add_filter "/vendor/"
      add_filter "/spec/"
      coverage_dir "spec/reports/coverage"
end

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'rakudax'
