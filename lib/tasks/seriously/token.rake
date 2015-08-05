namespace :seriously do

  namespace :token do
    desc "Force token regeneration"
    task :generate => :environment do
      puts "tokens:"
      Ekylibre::Tenant.switch_each do |tenant|
        token = Devise.friendly_token
        Preference.set!(Seriously::AUTH_PREF, token)
        puts "  #{tenant}: #{token}"
      end
    end

    task :fix => :environment do
      puts "tokens:"
      Ekylibre::Tenant.switch_each do |tenant|
        token = Devise.friendly_token
        unless preference = Preference.find_by(name: Seriously::AUTH_PREF)
          preference = Preference.set!(Seriously::AUTH_PREF, token)
        end
        puts "  #{tenant}: #{preference.value}"
      end
    end

  end

  desc "Display control tokens and generate it if necessary"
  task :token => "token:fix"

end
