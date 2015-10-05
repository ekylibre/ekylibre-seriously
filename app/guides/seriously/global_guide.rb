# Guide to test economy
class Seriously::EconomyGuide < ActiveGuide::Base
  group :economic do
    before do
      variables.gross_operating_surplus = 50
    end
    group :sales do
      test :minimal_sales_revenue, proc { Sale.where('invoiced_at >= ?', Time.now - 1.year).sum(:amount) > 10_000 }
      test :positive_balance, proc { Sale.where('invoiced_at >= ?', Time.now - 1.year).sum(:amount) > Purchase.where('invoiced_at >= ?', Time.now - 1.year).sum(:amount) }
    end
    test :gos_greater_than_5,  proc { variables.gross_operating_surplus > 5}
    test :gos_greater_than_10, proc { variables.gross_operating_surplus > 10}
    test :gos_greater_than_15, proc { variables.gross_operating_surplus > 15}
    test :gos_greater_than_20, proc { variables.gross_operating_surplus > 20}
    test :gos_greater_than_25, proc { variables.gross_operating_surplus > 25}
    test :gos_greater_than_30, proc { variables.gross_operating_surplus > 30}
    test :gos_greater_than_35, proc { variables.gross_operating_surplus > 35}
    test :gos_greater_than_40, proc { variables.gross_operating_surplus > 40}
    test :gos_greater_than_45, proc { variables.gross_operating_surplus > 45}
    test :gos_greater_than_50, proc { variables.gross_operating_surplus > 50}
  end

  group :environment do    
  end

  group :social do
  end

  group :legality do
  end

  group :quality do
  end

end