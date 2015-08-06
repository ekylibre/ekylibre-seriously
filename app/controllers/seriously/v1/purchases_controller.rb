class Seriously::V1::PurchasesController < Seriously::V1::BaseController
  
  def create
    puts params.inspect.green
    # Create client
    supplier = find_entity(params[:supplier])
    puts supplier.inspect

    
    # TODO
    head :unprocessable_entity
  end

end
