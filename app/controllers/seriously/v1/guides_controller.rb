class Seriously::V1::GuidesController < Seriously::V1::BaseController
  # Run many guides and returns global report
  def run_all
    guides = params[:guides] || [:economy]
    global_report = {}
    guides.each do |name|
      report = "Seriously::#{name.to_s.classify}Guide::Base".constantize.run(verbose: false)
      global_report[name] = report
    end
    render json: global_report
  end

  # Run on guide and returns report
  def run
    report = "Seriously::#{params[:id].to_s.classify}Guide::Base".constantize.run(verbose: false)
    render json: report
  end

  def quality
    preference = Preference.get!('contracts_quality.average', 0.0, :decimal)
    preference.value = params[:rating].to_f
    preference.save!
    render json: { status: 'ok' }
  end

  protected

  def humanize_report(report)
    hash = report.slice(:failed, :passed, :started_at, :stopped_at)
    hash[:points] = report[:points].collect do |point|
      item = point[:item]
      p = { name: item.unique_name, label: item.human_name, success: item[:success] }
      p[:subtests] = item[:subtests].collect do |st|
        i = st[:item]
        { name: p.unique_name, label: p.human_name, success: st[:success] }
      end
      p
    end
    if report[:results]
      hash[:results] = report[:results].collect do |r|
        item = r[:item]
        { name: item.unique_name, label: item.human_name, value: r[:value] }
      end
    end
    hash
  end
end
