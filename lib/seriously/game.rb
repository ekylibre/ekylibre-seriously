# coding: utf-8
require 'rest-client'

module Seriously

  class Game

    def initialize(url, token)
      @url = url.to_s
      @token = token.to_s
      puts "New game (#{@url.red}##{@token.blue})"
    end

    def prepare
      puts 'Retrieving conf'.yellow + '...'
      conf = configuration
      puts 'Retrieving historic'.yellow + '...'
      historic_file = request_file('/historic')
      conf[:historic] = historic_file if historic_file
      post('/prepare')
      conf[:farms].each do |farm|
        [:historic, :currency, :country, :language, :accounting_system, :administrator].each do |k|
          farm[k] = conf[k] if conf.key?(k)
        end
        tenant = farm.delete(:tenant)
        prepare_farm(tenant, farm)
      end
      post('/confirm')
    end

    def start
      configuration[:farms].each do |farm|
        Ekylibre::Tenant.switch(farm[:tenant]) do
          farm[:users].each do |user|
            resource = User.find_by(email: user[:email])
            puts "Unlock #{resource.inspect.blue}"
            resource.unlock if resource
          end
        end
      end
    end

    def stop
      configuration[:farms].each do |farm|
        Ekylibre::Tenant.switch(farm[:tenant]) do
          farm[:users].each do |user|
            resource = User.find_by(email: user[:email])
            resource.lock if resource
          end
        end
      end
    end

    def pause
      fail :not_implemented
    end

    def resume
      fail :not_implemented
    end

    def configuration
      @configuration ||= get
    end

    def test
      get
      return true
    rescue
      return false
    end

    protected

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
        Preference.set!(:accounting_system, options[:accounting_system] || :fr_pcga)
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

        # Deactivates existing users
        User.find_each(&:lock)

        # Add admin account
        admin = options[:administrator]
        if admin
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
          u.lock
          link = EntityLink.find_or_initialize_by(entity_id: u.person_id, linked_id: org.id, nature: :membership)
          link.post = 'Cogérant'
          link.save!
          print '.'
        end
      end
      print "✓\n".green
    end

    def get(path = '')
      response = RestClient.get(@url + path, accept: :json, Authorization: "g-token #{@token}")
      return JSON.parse(response).deep_symbolize_keys
    end

    def post(path = '', data = nil)
      response = RestClient.post(@url + path, data, accept: :json, Authorization: "g-token #{@token}")
      return JSON.parse(response).deep_symbolize_keys
    end

    def request_data(path = '')
      response = RestClient.get(@url + path, Authorization: "g-token #{@token}")
      return response
    end

    def request_file(path = '', options = {})
      data = request_data(path)
      file = nil
      if data != 'nil'
        file = options[:file] || Rails.root.join('tmp', "#{Time.now.to_i.to_s(36)}-#{rand(999_999).to_s(36)}")
        File.write(file, data, encoding: options[:encoding] || 'ASCII-8BIT')
      end
      return file
    end


  end
end
