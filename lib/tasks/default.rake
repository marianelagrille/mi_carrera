if Rails.env.test? || Rails.env.development?
  require 'rubocop/rake_task'
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new(:spec)
  RuboCop::RakeTask.new

  task(:default).clear
  task default: [:rubocop, :test, "test:system", :spec]
end
