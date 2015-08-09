class Seriously::V1::BaseController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate!

  around_action :back_to_future
  respond_to :json

  protected

  def authenticate!
    authorization = request.headers['Authorization'].to_s.strip.split(/\s+/)
    code = :bad_request
    if authorization.first == 'simple-token'
      return true if authorization.second == Preference['serious.s-token']
    else
      code = :unauthorized
    end
    head code
    false
  end

  def find_entity(attributes)
    puts attributes.inspect.red
    preference = Preference.find_by(name: "serious.entities.#{attributes[:code]}")
    if preference
      entity = Entity.find(preference.value)
    else
      entity = Entity.create!(attributes.permit(:last_name))
      Preference.set!("serious.entities.#{attributes[:code]}", entity.id, :integer)
    end
    entity
  end

  def back_to_future
    Seriously::Timescope.freeze do
      yield
    end
  end

end
