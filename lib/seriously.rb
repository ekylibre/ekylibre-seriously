# coding: utf-8
module Seriously

  AUTH_PREF = 'serious.auth.token'

  def self.prepare_farm(farm, conf, historic_file)
    tenant = farm[:tenant]
    print ("Configuring #{tenant.to_s.yellow} farm: ").ljust(40)
    if historic_file
      puts "Restore historic in #{tenant}"      
      Ekylibre::Tenant.restore(historic_file, tenant: tenant)
    else
      if Ekylibre::Tenant.exist?(tenant)
        puts "Drop tenant #{tenant}"
        Ekylibre::Tenant.drop(tenant)
      end
      puts "Create empty tenant #{tenant}"      
      Ekylibre::Tenant.create(tenant)
    end
    print "."
    Ekylibre::Tenant.switch(tenant) do
      puts "Users: #{User.pluck(:email).to_sentence}"      
      Preference.set!(:currency, conf[:currency] || :EUR)
      Preference.set!(:country, conf[:country] || :fr)
      Preference.set!(:language, conf[:language] || :fra)
      Preference.set!(:chart_of_accounts, conf[:chart_of_accounts] || :fr_pcga)
      Preference.set!("serious.s-token", farm[:token])
      print "."

      Account.load_defaults
      print "."
      Sequence.load_defaults
      print "."
      DocumentTemplate.load_defaults
      print "."

      # Configure default role
      role = Role.find_or_initialize_by(name: "Gérant")
      rights = Ekylibre::Access.all_rights
      %w(lock-users write-users write-roles write-sales write-purchases write-loans write-journal_entries write-equipments write-incoming_payments write-outgoing_payments write-inventories write-issues write-product_nature_categories write-product_natures write-product_nature_variants write-sequences write-settings write-taxes).each do |right|
        interaction, resource = right.split('-')[0..1]
        if rights[resource]
          rights[resource].delete(interaction)
        end
      end
      role.rights = rights
      role.save!
      print "."

      # Configure farm entity
      org = Entity.find_or_initialize_by(of_company: true)
      org.last_name = farm[:name]
      org.save!
      print "."

      # Configure default team
      team = Team.find_or_create_by!(name: "Direction")
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
        link.post = "Cogérant"
        link.save!
        print "."
      end
    end
    print "✓\n".green

  end


  module Timescope

    class << self

      def freeze(&block)
        frozen_at = Time.zone.local(1953,3,16)
        pref = Preference.find_by(name: "serious.turns")
        if pref
          now = Time.now
          turns = YAML.load(pref.value)
          active = turns.detect do |turn|
            turn['started_at'] <= now && now < turn['stopped_at']
          end
          if active
            duration = active['stopped_at'] - active['started_at']
            elapsed = now - active['started_at']
            inside_duration = active['inside_stopped_at'] - active['inside_started_at']
            inside_elapsed = inside_duration * elapsed / duration
            inside_elapsed
            frozen_at = active['inside_started_at'] + inside_elapsed
            
            frozen_at = frozen_at.beginning_of_day + 7.hours + (frozen_at - frozen_at.beginning_of_day) * 0.5
            # frozen_at = active['frozen_at']
          end
        else
          puts "Cannot find turns".red
        end
        puts "Time is frozen at #{frozen_at.l(locale: :eng)}".green
        Timecop.freeze(frozen_at, &block)
      end

    end

  end

end
