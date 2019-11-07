desc "Customized version of the regular stats"
task cf_stats: :environment do
  require 'rails/code_statistics'

  CodeStatistics::TEST_TYPES = [
    'Controller tests',
    'Helper tests',
    'Model tests',
    'Interactor tests',
    'Mailer tests',
    'Job tests',
    'Integration tests',
    'Functional tests (old)',
    'Unit tests (old)',
  ]

  stats_directories = [
    %w(Controllers        app/controllers),
    %w(Helpers            app/helpers),
    %w(Inputs             app/inputs),
    %w(Jobs               app/jobs),
    %w(Models             app/models),
    %w(Interactors        app/interactors),
    %w(View\ models       app/view_models),
    %w(Mailers            app/mailers),
    %w(Javascripts        app/assets/javascripts),
    %w(Libraries          lib/),
    %w(APIs               app/apis),
    %w(Controller\ tests  test/controllers),
    %w(Helper\ tests      test/helpers),
    %w(Model\ tests       test/models),
    %w(Interactor\ tests  test/interactors),
    %w(Mailer\ tests      test/mailers),
    %w(Job\ tests      test/jobs),
    %w(Integration\ tests test/integration),
    %w(Functional\ tests\ (old)  test/functional),
    %w(Unit\ tests \ (old)       test/unit)
  ].collect do |name, dir|
    [ name, "#{File.dirname(Rake.application.rakefile_location)}/#{dir}" ]
  end.select { |name, dir| File.directory?(dir) }

  CodeStatistics.new(*stats_directories).to_s
end
