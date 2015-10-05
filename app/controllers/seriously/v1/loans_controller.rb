class Seriously::V1::LoansController < Seriously::V1::BaseController
  def create
    currency = params[:currency] || Preference[:currency]

    # Create lender
    lender = find_entity(params[:lender])

    # Create loan
    loan = Loan.create!(
      currency: currency,
      lender: lender,
      insurance_percentage: params[:insurance_percentage],
      interest_percentage: params[:interest_percentage],
      amount: params[:amount],
      repayment_duration: params[:duration],
      name: params[:loan_name],
      started_on: params[:started_on],
      cash: find_cash(currency)
    )

    result = {
      loan:{
        id: loan.id,
        name: loan.name
      }
    }
    render json: result.to_json
  end

  
  protected

  def find_cash(currency)
    cash = Cash.find_by(nature: :bank_account, currency: currency)
    unless cash
      nature = :bank_account
      journal = Journal.find_or_initialize_by(nature: :bank, currency: currency)
      journal.name = 'enumerize.journal.nature.bank'.t
      journal.save!
      account = Account.find_or_import_from_nomenclature(:banks)
      cash = Cash.create!(
        name: "enumerize.cash.nature.#{nature}".t,
        nature: nature.to_s,
        account: account,
        journal: journal
      )
    end
    cash
  end
end
