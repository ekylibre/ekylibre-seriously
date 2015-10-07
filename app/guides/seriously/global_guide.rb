# Guide to test economy
class Seriously::GlobalGuide < ActiveGuide::Base
  group :economic do
    before do
      # get current financial year
      financial_year = FinancialYear.at
      
      # operating_margin_on_turnover = ( operating_margin / turnover_value) * 100
      product_value = financial_year.sum_entry_items('70 71 72 73 74')
      charge_value = financial_year.sum_entry_items('60 61 62 63 64')
      turnover_value = financial_year.sum_entry_items('70 !707 !7086 !7087 !7088 !7097')
      operating_margin =  ( - product_value - charge_value ) if product_value && charge_value
      variables.operating_margin_on_turnover = 0
      variables.operating_margin_on_turnover = ( operating_margin / - turnover_value) * 100 if operating_margin && turnover_value && turnover_value != 0.0
      
      # debts_on_assets = (debts / assets) * 100
      financial_debt = financial_year.sum_entry_items('1641 1642 1643 4553 4554 519, 512 514 517 C, 5186 161 163 165 166 1675 168 17 426, 451 456 458 C')
      other_debt = financial_year.sum_entry_items('401 4031 4081 4088 402 4032 4082, 445 C, 421 422 424 427 4282 4284 4286 431 437 4382 4386 442, 443 444 C, 446 447 4482 4486 457, 4551 4552 C, 269 279 404 405 4084 4196 4197 4198 4419, 452 453 454 461 C, 464, 467 C, 4686, 478 C, 509')
      advanced_product = financial_year.sum_entry_items('487')
      debts = financial_debt + other_debt + advanced_product if financial_debt && other_debt && advanced_product
      asset = financial_year.sum_entry_items('109 2 !28 !29')
      stock = financial_year.sum_entry_items('3 !39')
      client = financial_year.sum_entry_items('4091 41, 445 4551 4552 D, 4096 4097 4098 425 4287 4387 441 !4419, 443 444 D, 4487, 451 452 453 454 456 458 461 462 D, 465, 467 D, 4687, 487 D')
      portfolio_value = financial_year.sum_entry_items('502 503 504 505 506 507 508')
      bank = financial_year.sum_entry_items('511, 512 514 D, 515 516, 517 D, 5187 53 54')
      advance_charge = financial_year.sum_entry_items('486 481 476')
      assets = asset + stock + client + portfolio_value + bank + advance_charge if asset && stock && client && portfolio_value && bank && advance_charge
      variables.debts_on_assets = 100
      variables.debts_on_assets = (- debts / assets) * 100 if debts && assets && assets != 0.0
      
      # liquid_assets_on_turnover = (liquid_assets / turnover_value) * 100
      variables.liquid_assets_on_turnover = 0.0
      variables.liquid_assets_on_turnover = (-bank / turnover_value) * 100 if bank && turnover_value && turnover_value != 0.0
      
    end
    test :operating_margin_on_turnover_greater_than_5,  proc { variables.operating_margin_on_turnover > 5}
    test :operating_margin_on_turnover_greater_than_10, proc { variables.operating_margin_on_turnover > 10}
    test :operating_margin_on_turnover_greater_than_15, proc { variables.operating_margin_on_turnover > 15}
    test :operating_margin_on_turnover_greater_than_20, proc { variables.operating_margin_on_turnover > 20}
    test :operating_margin_on_turnover_greater_than_25, proc { variables.operating_margin_on_turnover > 25}
    test :operating_margin_on_turnover_greater_than_30, proc { variables.operating_margin_on_turnover > 30}
    test :operating_margin_on_turnover_greater_than_35, proc { variables.operating_margin_on_turnover > 35}
    test :operating_margin_on_turnover_greater_than_40, proc { variables.operating_margin_on_turnover > 40}
    test :operating_margin_on_turnover_greater_than_45, proc { variables.operating_margin_on_turnover > 45}
    test :operating_margin_on_turnover_greater_than_50, proc { variables.operating_margin_on_turnover > 50}
    test :debts_on_assets_less_than_50,  proc { variables.debts_on_assets < 50}
    test :debts_on_assets_less_than_40,  proc { variables.debts_on_assets < 40}
    test :debts_on_assets_less_than_30,  proc { variables.debts_on_assets < 30}
    test :debts_on_assets_less_than_20,  proc { variables.debts_on_assets < 20}
    test :debts_on_assets_less_than_10,  proc { variables.debts_on_assets < 10}
    test :liquid_assets_on_turnover_greater_than_50,  proc { variables.liquid_assets_on_turnover > 50}
    test :liquid_assets_on_turnover_greater_than_70,  proc { variables.liquid_assets_on_turnover > 70}
    test :liquid_assets_on_turnover_greater_than_90,  proc { variables.liquid_assets_on_turnover > 90}
    test :liquid_assets_on_turnover_greater_than_100,  proc { variables.liquid_assets_on_turnover > 100}
    test :liquid_assets_on_turnover_greater_than_110,  proc { variables.liquid_assets_on_turnover > 110}

  end

  group :environment do
    before do
      # get current campaign
      campaign = Campaign.at.first
      # load YML abacus for CO2
      path = Pathname.new(__FILE__).dirname.join('carbon.csv')
      carbon = {}
      if path.exist?
        carbon = CSV.readlines(path).each_with_object({}.with_indifferent_access) do |row, hash|
          hash[row.first] = row.second
          hash
        end
      else
        fail "Where is carbon.csv ?"
      end
      # get all intervention
      interventions = Intervention.of_campaign(campaign).real
      interventions_carbon_impact_per_hectare = []
      # get relative co2 impact of cast for each intervention
      for intervention in interventions
        intervention_carbon_inpact = []
        # for input
        for cast in intervention.casts.of_generic_role(:input)
          c = nil
          c = carbon[cast.variant.reference_name] if cast.variant
          cast_carbon_inpact = cast.population * c if c
          intervention_carbon_inpact << cast_carbon_inpact
        end
        # for tool / equipment
        for cast in intervention.casts.of_generic_role(:tool)
          c = 50
          cast_carbon_inpact = cast.duration.to_d(:hours) * c if cast.duration
          intervention_carbon_inpact << cast_carbon_inpact
        end
        i = intervention_carbon_inpact.compact.sum
        area = intervention.working_area.to_d(:hectare)
        interventions_carbon_impact_per_hectare << (i/area).to_f if area != 0.0
      end
      # sum of interventions_carbon_impact_per_hectare in kg per hectare
      variables.ico_ha = interventions_carbon_impact_per_hectare.compact.sum
    end
    test :carbon_emission_per_hectare_less_than_5000_kg,  proc { variables.ico_ha < 5000}
    test :carbon_emission_per_hectare_less_than_4750_kg,  proc { variables.ico_ha < 4750}
    test :carbon_emission_per_hectare_less_than_4500_kg,  proc { variables.ico_ha < 4500}
    test :carbon_emission_per_hectare_less_than_4250_kg,  proc { variables.ico_ha < 4250}
    test :carbon_emission_per_hectare_less_than_4000_kg,  proc { variables.ico_ha < 4000}
    test :carbon_emission_per_hectare_less_than_3750_kg,  proc { variables.ico_ha < 3750}
    test :carbon_emission_per_hectare_less_than_3500_kg,  proc { variables.ico_ha < 3500}
    test :carbon_emission_per_hectare_less_than_3250_kg,  proc { variables.ico_ha < 3250}
    test :carbon_emission_per_hectare_less_than_3000_kg,  proc { variables.ico_ha < 3000}
    test :carbon_emission_per_hectare_less_than_2750_kg,  proc { variables.ico_ha < 2750}
    test :carbon_emission_per_hectare_less_than_2500_kg,  proc { variables.ico_ha < 2500}
    test :carbon_emission_per_hectare_less_than_2250_kg,  proc { variables.ico_ha < 2250}
    test :carbon_emission_per_hectare_less_than_2000_kg,  proc { variables.ico_ha < 2000}
    test :carbon_emission_per_hectare_less_than_1750_kg,  proc { variables.ico_ha < 1750}
    test :carbon_emission_per_hectare_less_than_1500_kg,  proc { variables.ico_ha < 1500}
    test :carbon_emission_per_hectare_less_than_1250_kg,  proc { variables.ico_ha < 1250}
    test :carbon_emission_per_hectare_less_than_1000_kg,  proc { variables.ico_ha < 1000}
    test :carbon_emission_per_hectare_less_than_750_kg,  proc { variables.ico_ha < 750}
    test :carbon_emission_per_hectare_less_than_500_kg,  proc { variables.ico_ha < 500}
    test :carbon_emission_per_hectare_less_than_250_kg,  proc { variables.ico_ha < 250}
  end

  group :social do
  end

  group :legality do
  end

  group :quality do
  end

end
