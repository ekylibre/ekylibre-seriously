json.array! @products do |product|
  json.name product.name
  json.variant product.variant.reference_name
  json.id product.id
  json.number product.number
  json.tax 'french_vat_normal_2014'
end
