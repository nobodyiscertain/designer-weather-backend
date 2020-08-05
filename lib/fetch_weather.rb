require "redis"
require "faraday"
require "json"

$redis = Redis.new

class FetchWeather
  attr_reader :lat, :lon, :key, :force

  def initialize(lat:, lon:, force:)
    @lat = lat
    @lon = lon
    @key = [@lat, @lon].join(":")
    @force = force
  end

  def call
    {
      data: fetch_data,
      key: key
    }.to_json
  end

  private

  def fetch_data
    if $redis.exists?(key) && force != "true"
      data = $redis.get(key)
    else
      data = fetch_remote_data
      $redis.set(key, data)
    end
    JSON.parse data
  end

  def fetch_remote_data
    url = "https://api.openweathermap.org/data/2.5/onecall"
    params = {
      appid: ENV["OPENWEATHER_API_KEY"],
      exclude: "minutely,daily,current",
      lat: lat,
      lon: lon
    }
    response = Faraday.get(url, params)
    response.body
  end
end
