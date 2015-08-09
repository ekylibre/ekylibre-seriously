# coding: utf-8
require 'rest-client'
require 'open-uri'

namespace :seriously do

  desc "Prepare a game"
  task :prepare => :environment do
    url = ENV["GAME_URL"]
    fail "No GAME_URL" unless url
    token = ENV["TOKEN"]
    fail "No TOKEN" unless token
    puts "Retrieving conf".yellow + "..."
    response = RestClient.get(url, accept: :json, Authorization: "g-token #{token}")
    conf = JSON.parse(response).deep_symbolize_keys
    puts "Retrieving historic".yellow + "..."
    response = RestClient.get("#{url}/historic", Authorization: "g-token #{token}")
    historic_file = nil
    if response != "nil"
      historic_file = Rails.root.join("tmp", "#{Time.now.to_i.to_s(36)}-#{rand(999_999).to_s(36)}.zip")
      File.write(historic_file, response, encoding: "ASCII-8BIT")
    end
    force = %w(true t 1 yes).include?(ENV["FORCE"]) || conf[:force]
    conf[:farms].each do |farm|
      Seriously.prepare_farm(farm.dup, conf, historic_file)
    end

    # Confirm to serious that farms are ready
    RestClient.post("#{url}/confirm", nil, accept: :json, Authorization: "g-token #{token}")

  end

end
