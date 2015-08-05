class Seriously::V1::BaseController < ::ApplicationController

  before_action :authenticate!
  hide_action :authenticate!

  def authenticate!
    if request.headers['X-Serious-Auth-Token']
    end
  end

end
