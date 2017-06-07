# coding: utf-8

class Seriously::V1::IssuesController < Seriously::V1::BaseController
  def create
    products = Product.availables
    target = params[:target] || {}

    if (variety = target[:variety])
      products = products.of_variety(variety)
    end

    # if (minimal_age = target[:minimal_age])
    #   products = products.where("born_at <= #{minimal_age}")
    # end
    # if (maximal_age = target[:maximal_age])
    #   products = products.where("dead_at >= #{maximal_age}")
    # end

    shape = build_shape(target[:coordinates_nature], target[:coordinates])
    shape_area = shape.area
    params[:damage][:destruction_percentage] ||= 50
    destruction_percentage = params[:damage][:destruction_percentage].to_f / 100

    products.intersect_with(shape).find_each do |product|
      params[:global_destruction_percentage] = destruction_percentage
      description = params[:name] + '. ' + (params[:description] || '')
      if product.shape
        product_shape = Charta::Geometry.new(product.shape)
        destroyed_area = product_shape.intersection(shape).area
        params[:global_destruction_percentage] = (100.0 * destruction_percentage * destroyed_area.to_f(:square_meter) / product_shape.area.to_f(:square_meter)).round
        description << " Détruite à #{params[:global_destruction_percentage]}%."
      end
      next unless params[:global_destruction_percentage] > 0
      issue = Issue.create!(
        name: params[:name],
        nature: :issue, # params[:nature],
        description: description.strip,
        observed_at: params[:observed_at] || Time.zone.now,
        target: product
      )
      pref = Preference.find_or_initialize_by(name: "seriously.issues.#{issue.id}")
      pref.nature = :string
      pref.value = params.to_yaml
      pref.save!
    end

    result = {
      state: {
        message: 'ok'
      }
    }
    render json: result.to_json
  end

  protected

  def build_shape(nature, coordinates)
    if nature == 'geojson'
      Charta::Geometry.new(coordinates)
    else
      raise "Invalid nature of coordinates: #{nature.inspect}"
    end
  end
end
