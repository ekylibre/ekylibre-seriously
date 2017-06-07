# coding: utf-8

class Seriously::V1::ProductsController < Seriously::V1::BaseController
  def index
    @products = Product.where(category_id: ProductNatureCategory.where(saleable: true)).availables
  end
end
