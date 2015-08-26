class Seriously::V1::ScenarioIssueController < Seriously::V1::BaseController
  def create
    products = Product.availables
    if (variety = params[:target][:variety])
      products = products.of_variety(variety)
    end

    if (minimal_age = params[:target][:minimal_age])
      products = products.where("born_at <= #{minimal_age}")
    end
    if (maximal_age = params[:target][:maximal_age])
      products = products.where("dead_at >= #{maximal_age}")
    end

    products.find_each do |product|
      issue = Issue.create!(
        name: params[:name],
        nature: params[:nature],
        description: params[:description],
        observed_at: params[:observed_at],
        target: product
      )
      pref = Preference.find_or_initialize_by(name: "seriously.issues.#{issue.id}")
      pref.nature = :string
      pref.value = params.to_yaml
      pref.save!
    end

    result = {
      state:{
          message: 'ok'
      }
    }
    render json: result.to_json
  end
end