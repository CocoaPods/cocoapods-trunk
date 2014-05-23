require "bundler/gem_tasks"

def specs(dir)
  FileList["spec/#{dir}/*_spec.rb"].shuffle.join(' ')
end

desc "Runs all the specs"
task :specs do
  sh "bundle exec bacon #{specs('**')}"
end

desc 'Automatically run specs for updated files'
task :kick do
  exec 'bundle exec kicker -c'
end

task :default => :specs

