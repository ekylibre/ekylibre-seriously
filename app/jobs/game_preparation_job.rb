class GamePreparationJob < ActiveJob::Base
  queue_as :default

  def perform(url, token)
    Seriously::Farm.prepare_farms(url, token)
  end
  
end
