module Seriously
  class Intervention
    include ActiveModel::Conversion
    include ActiveModel::Naming
    include ActiveModel::Validations

    # area_time_coeff h/ha
    NATURES = {
      tilling: {
        procedures: [:plowing, :raking],
        area_time_coeff: 1,
      },
      planting: {
        procedures: [:sowing],
        input: {
          scope: {availables: true, of_expression: "can grow"},
          units: [:kilogram_per_hectare, :unity_per_square_meter]
        }
        area_time_coeff: 0.5,
      }
      fertilizing: {
        procedures: [:sowing],
        input: {
          scope: {availables: true, of_expression: "can fertilize or can feed(plant)"},
          units: [:kilogram_per_hectare, :ton_per_hectare]
        },
        area_time_coeff: 0.25,
      },
      spraying: {
        area_time_coeff: 0.25,
      },
      irrigating: {
        doer: false,
        duration: 8,
      },
      pruning: {
        area_time_coeff: 8,
        doer: {
          count: 1..10
        }
      },
      harvesting: {
        area_time_coeff: 0.5,
      }
      
    }
    
    TIME_COEFF = {
      
    }

    validates_presence_of :nature, :started_at
    
    attr_accessor :nature, :supports, :doers, :started_at

    def initialize(options = {})
      @nature = options[:nature].to_sym
      @supports = []
      @doers = []
      @started_at ||= Time.zone.now
    end

    def with_inputs?
      [:fertilizing, :spraying, :planting, :irrigating].include? nature
    end

    def input_scope
      {
        fertilizing: {availables: true, of_expression: "can fertilize or can feed(plant)"},
        planting: {availables: true, of_expression: "can grow"},
        spraying: {availables: true, of_expression: "can care(plant)"},
        irrigating: {availables: true, of_variety: "water"},
      }[nature]
    end

    def input_units
      list = {
        fertilizing: [:kilogram_per_hectare, :ton_per_hectare],
        planting: [:kilogram_per_hectare, :unity_per_square_meter],
        spraying: [:liter_per_hectare, :hectoliter_per_hectare],
        irrigating: [:liter_per_hectare, :hectoliter_per_hectare],
      }[nature]
      return list.collect { |u| Nomen::Unit.find!(u) }
    end
    
    def with_outputs?
      [:harvesting].include? nature
    end

    def save
      return false unless valid?
      started_at = @started_at
      @supports.each do |support|
        support.area * 4
      end
      
    end

    def save!
      raise ActiveRecord::RecordInvalid unless valid?
      save
    end
    
  end
end
