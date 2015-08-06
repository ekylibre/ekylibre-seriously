class Seriously::V1::SalesController < BaseController

  def create
    # Create client
    
    # Create sale
    sale_attributes = {
      client: client
    }
    sale = Sale.create!(sale_attributes)

    # Create incoming_payment
    

    # Create outoging_delivery

    
    result = {
      sale: {id: sale.id, number: sale.number},
      client: {},
      incoming_payment: {},
      outgoing_delivery: {}
    }
    render json: result
  end

  def cancel    
  end

end
