class Seriously::V1::GamesController < Seriously::V1::BaseController
  def update
    turns = params[:turns].collect do |turn|
      hash = {
        number: turn[:number],
        started_at: Time.zone.parse(turn[:started_at]),
        stopped_at: Time.zone.parse(turn[:stopped_at]),
        inside_started_at: Time.zone.parse(turn[:inside][:started_at]),
        inside_stopped_at: Time.zone.parse(turn[:inside][:stopped_at])
      }
      hash[:frozen_at] = turn[:frozen_at] ? Time.zone.parse(turn[:frozen_at]) : hash[:stopped_at]
      hash.stringify_keys
    end
    pref = Preference.find_or_initialize_by(name: 'serious.turns')
    pref.nature = :string
    pref.value = turns.to_yaml
    pref.save!
    head :ok
  end
end
