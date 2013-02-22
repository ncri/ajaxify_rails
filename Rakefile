#!/usr/bin/env rake
require "bundler/gem_tasks"
# require "rake/testtask"

# Rake::TestTask.new(:test) do |t|
#   t.libs << 'test'
#   t.test_files = FileList['test/**/*_test.rb']
#   t.verbose = true
# end


require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)
task default: :spec