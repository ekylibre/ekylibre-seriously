class Seriously::V1::SalesController < Seriously::V1::BaseController
  def create
    puts params.inspect
    # Create client
    client = find_entity(params[:customer])

    items = {}
    params[:items].each_with_index { |item, index| items[index] = item }

    # Create sale
    sale = Sale.create!(
      client: client,
      invoiced_at: params[:invoiced_at],
      items_attributes: items
    )

    # Create incoming_payment
    incoming_payment = IncomingPayment.create!(
      amount: params[:amount]
    )

    # Attach incoming_payment to sale affair
    sale.affair.deal_with!(incoming_payment)

    # Create outoging_delivery
    outgoing_delivery = sale.outgoing_deliveries.create!(
      recipient: client,
      reference_number: params[:number],
      sent_at: params[:invoiced_at],
      items: []
    )

    result = {
      sale: {
        id: sale.id,
        number: sale.number
      },
      incoming_payment: {
        id: incoming_payment.id,
        number: incoming_payment.number
      },
      outgoing_delivery: {
        id: outgoing_delivery.id,
        number: outgoing_delivery.number
      }
    }
    render json: result.to_json
  end

  def cancel
  end
end
