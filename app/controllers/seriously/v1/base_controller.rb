class Seriously::V1::BaseController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate!

  protected
  
  def authenticate!
    authorization = request.headers['Authorization'].to_s.strip.split(/\s+/)
    code = :bad_request
    if authorization.first == "simple-token"
      if authorization.second == Preference["serious.s-token"]
        return true
      end
    else
      code = :unauthorized
    end
    head code
    false
  end


  def find_entity(entity)
    preference = Preference.find_by(name: "serious.entities.#{entity[:code]}")
    if preference
      client = Entity.find(preference.value)
    else
      client = Entity.create!(entity.to_h.slice("last_name"))
      Preference.set!("serious.entities.#{entity[:code]}", client.id, :integer)
    end    
  end
  

end
