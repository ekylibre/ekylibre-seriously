# Guide to test economy
class Seriously::EconomyGuide < ActiveGuide::Base
  group :sales do
    test :minimal_sales_revenue, proc { Sale.where('invoiced_at >= ?', Time.now - 1.year).sum(:amount) > 10_000 }
    test :positive_balance, proc { Sale.where('invoiced_at >= ?', Time.now - 1.year).sum(:amount) > Purchase.where('invoiced_at >= ?', Time.now - 1.year).sum(:amount) }
  end
end
