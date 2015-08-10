# coding: utf-8
require 'rest-client'

module Seriously
  module Farm
    class << self
      def prepare_farms(game_url, token, options = {})
        puts 'Retrieving conf'.yellow + '...'
        response = RestClient.get(game_url, accept: :json, Authorization: "g-token #{token}")
        conf = JSON.parse(response).deep_symbolize_keys
        unless options[:create].is_a?(FalseClass)
          puts 'Retrieving historic'.yellow + '...'
          response = RestClient.get("#{game_url}/historic", Authorization: "g-token #{token}")
          historic_file = nil
          if response != 'nil'
            historic_file = Rails.root.join('tmp', "#{Time.now.to_i.to_s(36)}-#{rand(999_999).to_s(36)}.zip")
            File.write(historic_file, response, encoding: 'ASCII-8BIT')
          end
          conf[:historic] = historic_file if historic_file
        end
        conf[:farms].each do |farm|
          [:historic, :currency, :country, :language, :chart_of_accounts, :administrator].each do |k|
            farm[k] = conf[k] if conf.key?(k)
          end
          tenant = farm.delete(:tenant)
          prepare_farm(tenant, farm.merge(options.slice(:create)))
        end
        unless options[:confirm].is_a?(FalseClass)
          # Confirm to serious that farms are ready
          RestClient.post("#{game_url}/confirm", nil, accept: :json, Authorization: "g-token #{token}")
        end
      end

      # Prepare given farm
      def prepare_farm(tenant, options = {})
        print ("Configuring #{tenant.to_s.yellow} farm: ").ljust(40)
        if options[:create].is_a?(FalseClass)
          if Ekylibre::Tenant.exist?(tenant)
            puts "Use existing #{tenant}"
          else
            fail "#{tenant} doesnt exist"
          end
        else
          if options[:historic]
            puts "Restore historic in #{tenant}"
            Ekylibre::Tenant.restore(options[:historic], tenant: tenant)
          else
            if Ekylibre::Tenant.exist?(tenant)
              puts "Drop tenant #{tenant}"
              Ekylibre::Tenant.drop(tenant)
            end
            puts "Create empty tenant #{tenant}"
            Ekylibre::Tenant.create(tenant)
          end
        end
        print '.'
        Ekylibre::Tenant.switch(tenant) do
          # puts "Users: #{User.pluck(:email).to_sentence}"
          Preference.set!(:currency, options[:currency] || :EUR)
          Preference.set!(:country, options[:country] || :fr)
          Preference.set!(:language, options[:language] || :fra)
          Preference.set!(:chart_of_accounts, options[:chart_of_accounts] || :fr_pcga)
          Preference.set!('serious.s-token', options[:token])
          print '.'

          Account.load_defaults
          print '.'
          Sequence.load_defaults
          print '.'
          DocumentTemplate.load_defaults
          print '.'

          # Configure default role
          role = Role.find_or_initialize_by(name: 'Gérant')
          rights = Ekylibre::Access.all_rights
          %w(lock-users write-users write-roles write-sales write-purchases write-loans write-journal_entries write-equipments write-incoming_payments write-outgoing_payments write-inventories write-issues write-product_nature_categories write-product_natures write-product_nature_variants write-sequences write-settings write-taxes).each do |right|
            interaction, resource = right.split('-')[0..1]
            rights[resource].delete(interaction) if rights[resource]
          end
          role.rights = rights
          role.save!
          print '.'

          # Configure farm entity
          org = Entity.find_or_initialize_by(of_company: true)
          org.last_name = options[:name]
          org.save!
          print '.'

          # Configure default team
          team = Team.find_or_create_by!(name: 'Direction')
          print '.'

          # Add admin account
          if admin = options[:administrator]
            email = admin[:email] || 'admin@ekylibre.org'
            if u = User.find_by(email: email)
              pass = admin[:password] || Devise.friendly_token
              u = User.create!(administrator: true, first_name: 'Admin', last_name: 'STRATOR', role: role, password: pass, password_confirmation: pass, email: email)
              puts "Admin password: #{pass.red}"
            end
          end
          print '.'

          # Configure users
          options[:users].each do |user|
            pass = user[:password] || (Rails.env.development? ? '12345678' : Devise.friendly_token)
            u = User.find_or_initialize_by(email: user[:email])
            # puts "#{user[:email]}: #{pass}"
            u.attributes = user.slice(:first_name, :last_name)
            u.role = role
            u.password = pass
            u.password_confirmation = pass
            u.administrator = false
            u.team = team
            u.save!
            link = EntityLink.find_or_initialize_by(entity_id: u.person_id, linked_id: org.id, nature: :membership)
            link.post = 'Cogérant'
            link.save!
            print '.'
          end
        end
        print "✓\n".green
      end
    end
  end
end
