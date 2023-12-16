require 'rubygems'

begin
  require 'bundler/setup'
rescue LoadError => e
  abort e.message
end

require 'rake'
require 'rubygems/tasks'
Gem::Tasks.new

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new

task :test    => :spec
task :default => :spec

require 'yard'
YARD::Rake::YardocTask.new
task :doc => :yard

namespace :example do
  require 'command_kit/completion/task'
  CommandKit::Completion::Task.new(
    file:        './examples/cli',
    class_name:  'Foo::CLI',
    output_file: 'example-completion.sh'
  )
end
