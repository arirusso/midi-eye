# frozen_string_literal: true

begin
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new(:spec)
  RSpec::Core::RakeTask.new('spec:unit') do |t|
    t.pattern = 'spec/unit/*_spec.rb'
  end
  RSpec::Core::RakeTask.new('spec:integration') do |t|
    t.pattern = 'spec/integration/*_spec.rb'
  end

  task default: :spec
rescue LoadError
  # no rspec available
end
