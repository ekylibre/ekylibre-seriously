class GameJob < ApplicationJob
  queue_as :default

  def perform(task, url, token)
    puts "Perform #{task} on #{url}...".green
    Seriously::Game.new(url, token).send(task)
  end
end
