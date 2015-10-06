module Seriously
  module Timescope
    class << self
      def freeze(frozen_at = nil, &block)
        pref = Preference.find_by(name: 'serious.turns')
        if frozen_at.nil? && pref
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
          puts 'Cannot find turns'.red
          frozen_at = Time.zone.local(1953, 3, 16)
        end
        puts "Time is frozen at #{frozen_at.l(locale: :eng)}".green
        Timecop.freeze(frozen_at, &block)
        return frozen_at
      end
    end
  end
end
