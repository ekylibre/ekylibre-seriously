namespace :seriously do
  desc 'Prepare a game'
  task prepare: :environment do
    ::GameJob.perform_later('prepare', ENV['GAME_URL'], ENV['TOKEN'])
  end

  desc 'Start a game opening access to players'
  task start: :environment do
    ::GameJob.perform_later('start', ENV['GAME_URL'], ENV['TOKEN'])
  end
  
  desc 'Stop a game and close access to players'
  task stop: :environment do
    ::GameJob.perform_later('stop', ENV['GAME_URL'], ENV['TOKEN'])
  end
end
