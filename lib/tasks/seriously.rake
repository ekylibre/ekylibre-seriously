# coding: utf-8
require 'open-uri'

namespace :seriously do

  desc "Prepare a game"
  task :prepare => :environment do
    url = ENV["GAME_URL"]
    fail "No GAME_URL" unless url
    token = ENV["TOKEN"]
    fail "No TOKEN" unless token
    puts "Retrieving conf".yellow + "..."
    result = nil
    open(url, "X-Auth-Token" => token) do |f|
      result = f.read
    end
    conf = JSON.parse(result).deep_symbolize_keys
    force = %w(true t 1 yes).include?(ENV["FORCE"]) || conf[:force]
    conf[:farms].each do |farm|
      print ("Configuring #{farm[:name]} farm: ").ljust(30)
      tenant = farm[:tenant]
      if force and  Ekylibre::Tenant.exist?(tenant)
        Ekylibre::Tenant.drop(tenant)
      end
      print "."
      unless Ekylibre::Tenant.exist?(tenant)
        Ekylibre::Tenant.create(tenant)
      end
      print "."
      Ekylibre::Tenant.switch(tenant) do
        Preference.set!(:currency, conf[:currency] || :EUR)
        Preference.set!(:country, conf[:country] || :fr)
        Preference.set!(:language, conf[:language] || :fra)
        Preference.set!(:chart_of_accounts, conf[:chart_of_accounts] || :fr_pcga)
        Preference.set!(:serious_token, farm[:token])
        print "."

        # Configure farm entity
        Entity.create!(of_company: true, last_name: farm[:name])
        print "."

        # Configure default role
        unless role = Role.first
          role = Role.create!(name: "Gérant", reference_name: "manager")
        end
        # TODO: Assign rights to default role
        # disable_right "write-users"
        # disable_right "write-sales"
        # disable_right "write-purchases"
        # disable_right "write-loans"
        # disable_right "write-journal_entries"
        # disable_right "write-equipments"
        # disable_right "write-incoming_payments"
        # disable_right "write-outgoing_payments"
        # disable_right "write-inventories"
        # disable_right "write-issues"
        # disable_right "write-product_nature_categories"
        # disable_right "write-product_natures"
        # disable_right "write-product_nature_variants"
        # disable_right "write-settings"
        # disable_right "write-taxes"
        print "."

        # Add admin account
        if admin = conf[:administrator]
          email = admin[:email] || 'admin@ekylibre.org'
          if u = User.find_by(email: email)
            pass = admin[:password] || Devise.friendly_token
            u = User.create!(administrator: true, first_name: 'Admin', last_name: 'STRATOR', role: role, password: pass, password_confirmation: pass, email: email)
            puts "Admin password: #{pass.red}"
          end
        end
        print "."

        # Configure users
        farm[:users].each do |user|
          pass = user[:password] || Devise.friendly_token
          if u = User.find_by(email: user[:email])
            if user[:password]
              u.password = pass
              u.password_confirmation = pass
              u.save!
            end
          else
            u = User.create!(user.merge(role: role, password: pass, password_confirmation: pass))
          end
          print "."
        end
      end
      puts " " + "✓".green
    end


  end

end
