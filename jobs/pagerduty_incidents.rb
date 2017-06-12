require 'faraday'
require 'json'
require_relative '.conf'

#url = ENV['PAGERDUTY_URL']
#api_key = ENV['PAGERDUTY_APIKEY']
#env_services = ENV['PAGERDUTY_SERVICES']

url = $pagerduty_options[:url]
api_key = $pagerduty_options[:apikey]
env_services = $pagerduty_options[:services]

parsed_data = JSON.parse(env_services)

services = {}

parsed_data['services'].each do |key, value|
  services[key] = value
end

triggered = 0
acknowledged = 0

SCHEDULER.every '10s' do
  services.each do |key, value|
    conn = Faraday.new(url: "#{url}") do |faraday|
      faraday.request :url_encoded
      faraday.adapter Faraday.default_adapter
      faraday.headers['Content-type'] = 'application/json'
      faraday.headers['Authorization'] = "Token token=#{api_key}"
    end

    response = conn.get "/api/v1/services/#{value}"
    json = JSON.parse(response.body)

    triggered = json['service']['incident_counts']['triggered']
    acknowledged = json['service']['incident_counts']['acknowledged']

    send_event("#{key}-triggered", value: triggered)
    send_event("#{key}-acknowledged", value: acknowledged)
  end
end
