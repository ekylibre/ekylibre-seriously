namespace :seriously do
  desc 'Prepare a game'
  task prepare: :environment do
    # Seriously::Farm.prepare_farms(ENV['GAME_URL'], ENV['TOKEN'])
    ::GamePreparationJob.perform_later(ENV['GAME_URL'], ENV['TOKEN'])
  end

  desc 'Configure a game'
  task configure: :environment do
    Seriously::Farm.prepare_farms(ENV['GAME_URL'], ENV['TOKEN'], create: false)
  end
end
