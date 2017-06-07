# coding: utf-8

class Seriously::V1::SalesController < Seriously::V1::BaseController
  # Create a sale, its payment and delivery
  def create
    currency = params[:currency] || Preference[:currency]

    # Create client
    client = find_entity(params[:customer])

    # Find sale nature
    nature = find_sale_nature(currency)

    # Find responsible
    responsible = find_responsible

    # Create sale
    items = params[:items].each_with_index.each_with_object({}) do |(item, index), hash|
      variant = ProductNatureVariant.import_from_nomenclature(item[:variant])
      tax = Tax.import_from_nomenclature(item[:tax])
      hash[index.to_s] = {
        quantity: item[:quantity].to_f,
        unit_pretax_amount: item[:unit_pretax_amount].to_f,
        variant_id: variant.id,
        tax_id: tax.id
      }.stringify_keys
    end
    sale = Sale.create!(
      nature: nature,
      client: client,
      responsible: responsible.person,
      invoiced_at: params[:invoiced_on],
      items_attributes: items
    )
    sale.propose!
    sale.confirm!
    sale.invoice!

    # Find incoming payment mode
    mode = find_incoming_payment_mode(currency)

    # Create incoming_payment
    incoming_payment = IncomingPayment.create!(
      mode: mode,
      payer: client,
      to_bank_at: sale.invoiced_at,
      responsible: responsible,
      amount: sale.amount
    )
    # Attach incoming_payment to sale affair
    sale.deal_with!(incoming_payment.affair)

    # Create parcel
    items = params[:items].map do |item|
      # Get product informations
      attrs = { population: item[:quantity] }
      attrs[:product_id] = item[:product_id]
      attrs
    end
    parcel = Parcel.create!(
      address: find_main_address,
      nature: :outgoing,
      delivery_mode: :indifferent,
      sale: sale,
      recipient: client,
      storage: find_container,
      reference_number: params[:number],
      planned_at: sale.invoiced_at,
      items_attributes: items
    )
    delivery = Parcel.ship([parcel], delivery_mode: :third, started_at: sale.invoiced_at)
    result = {
      sale: {
        id: sale.id,
        number: sale.number
      },
      incoming_payment: {
        id: incoming_payment.id,
        number: incoming_payment.number
      },
      delivery: {
        id: delivery.id,
        number: delivery.number
      },
      parcel: {
        id: parcel.id,
        number: parcel.number
      }
    }
    render json: result.to_json
  end

  protected

  def find_sale_nature(currency)
    unless (nature = SaleNature.actives.where(currency: currency).order(by_default: :desc).first)
      unless (journal = Journal.where(nature: 'sales', currency: currency).order(:id).first)
        journal = Journal.create!(name: 'enumerize.journal.nature.sales'.t, nature: :sales, currency: Preference[:currency])
      end
      catalog = Catalog.find_by(usage: :sale)
      unless catalog
        catalog = Catalog.create!(usage: :sale, name: Catalog.model_name.human)
      end
      nature = SaleNature.create!(name: Sale.model_name.human, currency: Preference[:currency], by_default: true, active: true, with_accounting: true, journal: journal, description: 'Generated by Serious', catalog: catalog)
    end
    nature
  end

  def find_responsible
    user = nil
    user = User.find_by(email: params[:responsible]) if params[:responsible]
    user ||= User.where(locked: false).all.sample
    user
  end

  def find_main_address
    unless (address = Entity.of_company.default_mail_address)
      address = Entity.of_company.addresses.create!(canal: :mail, mail_line_6: '47000 AGEN')
    end
    address
  end

  def find_container
    unless (container = Product.can('store(matter)').first)
      container = Building.create!(name: 'Entrepôt', address: find_main_address, variant: ProductNatureVariant.import_from_nomenclature(:building))
    end
    container
  end

  def find_incoming_payment_mode(currency)
    unless (cash = Cash.find_by(nature: :bank_account, currency: currency))
      nature = :bank_account
      journal = Journal.find_or_initialize_by(nature: :bank, currency: currency)
      journal.name = 'enumerize.journal.nature.bank'.t
      journal.save!
      account = Account.find_or_create_in_chart(:banks)
      cash = Cash.create!(name: "enumerize.cash.nature.#{nature}".t, nature: nature.to_s,
                          account: account, journal: journal)
    end
    mode = IncomingPaymentMode.find_or_initialize_by(cash: cash, with_accounting: true)
    mode.name ||= IncomingPaymentMode.tc('default.transfer.name')
    mode.save!
    mode
  end
end
