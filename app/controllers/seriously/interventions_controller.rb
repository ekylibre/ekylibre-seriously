class Seriously::InterventionsController < Backend::BaseController
  
  def index
    @natures = [:tilling, :planting, :fertilizing, :spraying, :irrigating, :pruning, :harvesting]
  end

  def new
    @intervention = Seriously::Intervention.new(params)
  end

  def create
    @intervention = Seriously::Intervention.new(params)
    if @intervention.save
      redirect_to({action: :index})
    end
  end

end
