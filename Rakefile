require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = Dir.glob('spec/**/{[!spec_]}*.rb')
  t.rspec_opts = '--format progress'
end

task default: :spec

# vi:set ts=2 sw=2 et sta:
