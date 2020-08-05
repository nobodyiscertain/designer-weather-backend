require "sinatra"
require "geocoder"
require "jwt"
require "dotenv/load"
require_relative "lib/fetch_weather"

hmac_secret = ENV["HMAC_SECRET"]

get "/weather/:token" do
  coords = JWT.decode(params["token"], hmac_secret, "HS256").first

  response = FetchWeather.new(
    lat: coords["lat"],
    lon: coords["lon"],
    force: params.fetch("force") { "false" }
  ).call

  [200, {}, response]
end

get "/key" do
  address = [
    params.fetch("street", ""),
    params.fetch("city", ""),
    params.fetch("state", ""),
    params.fetch("zip", ""),
  ].uniq.reject(&:empty?).join(", ")

  results = Geocoder.search(address)
  lat, lon = results.first.coordinates

  payload = {
    lat: lat,
    lon: lon
  }

  token = JWT.encode payload, hmac_secret, "HS256"

  [200, {}, { token: token }.to_json]
end

