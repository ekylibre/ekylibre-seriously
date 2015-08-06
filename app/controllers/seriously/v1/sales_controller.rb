class Seriously::V1::SalesController < BaseController

  def create
    # Create client
    unless Preference.find_by(name: "serious.entities.#{params[:client][:code]}")
      Preference.create!(name: "serious.entities.#{params[:client][:code]}")
      entity_attributes = {
        last_name: params[:client][:name]
      }
      client = Entity.create!(entity_attributes)
    end

    items = Hash.new
    params[:items].each_with_index { |item, index| items[index] = item  }
    
    # Create sale
    sale_attributes = {
      client: client,
      items_attributes: {
        items: items
      }
    }
    sale = Sale.create!(sale_attributes)

    # Create incoming_payment
    incoming_attributes = {
      amount: params[:sale][:amount]
    }
    incoming_payment = IncomingPayment.create!(incoming_attributes)

    # Create outoging_delivery
    # outoging_delivery_attributes = {
    #
    # }
    # OutgoingDelivery

    result = {
      sale: {id: sale.id, number: sale.number},
      client: {},
      incoming_payment: {amount: incoming_payment.amount},
      outgoing_delivery: {}
    }
    render json: result
  end

  def cancel    
  end

end
