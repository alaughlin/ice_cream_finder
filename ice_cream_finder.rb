#!/usr/bin/env ruby
require 'json'
require 'rest-client'
require 'addressable/uri'

class IceCreamFinder
  def initialize
    @api_key = File.read(".api_key").chomp
    @results_arr = {}
    @cur_coords = []
    @dest_coords = []
  end

  def start
    puts "Weclome to Ice Cream Finder!"
    @cur_coords = get_current_coords
    locations = find_nearby_ice_cream(@cur_coords)
    store_results(locations)
    @dest_coords = choose_destination
    directions_url = create_directions_url(@cur_coords, @dest_coords)
    get_directions(directions_url)
  end

  def get_current_coords
    print "Please enter your address to find some tasty ice cream: "
    #current_address = create_address_url(gets.chomp)
    address = "181 Willow Springs, New Milford, CT 06776"
    current_address = create_address_url(address)

    address_lookup = RestClient.get(current_address)
    result = JSON.parse(address_lookup)["results"][0]

    cur_coords = [result["geometry"]["location"]["lat"], result["geometry"]["location"]["lng"]]

    cur_coords
  end

  def create_address_url(address)
    Addressable::URI.new(
      :scheme => "https",
      :host => "maps.googleapis.com",
      :path => "maps/api/geocode/json",
      :query_values => {
        :address => address,
        :key => @api_key
      }
    ).to_s
  end

  def create_search_url(params)
    Addressable::URI.new(
      :scheme => "https",
      :host => "maps.googleapis.com",
      :path => "maps/api/place/nearbysearch/json",
      :query_values => params
    ).to_s
  end

  def create_directions_url(cur, dest)
    Addressable::URI.new(
      :scheme => "https",
      :host => "maps.googleapis.com",
      :path => "maps/api/directions/json",
      :query_values => {
        :origin => "#{cur[0]},#{cur[1]}",
        :destination => "#{dest[0]},#{dest[1]}"
      }
    ).to_s
  end

  def find_nearby_ice_cream(cur_coords)
    params = {
      :key => @api_key,
      :location => "#{cur_coords[0]},#{cur_coords[1]}",
      :radius => 5000,
      :types => "restaurant|food",
      :keyword => "ice cream"
    }

    url = create_search_url(params)
    RestClient.get(url)
  end

  def store_results(locations)
    results = JSON.parse(locations)["results"]
    results.each do |result|
      result_coords = [result["geometry"]["location"]["lat"], result["geometry"]["location"]["lng"]]
      @results_arr[result["name"]] = result_coords
    end
  end

  def choose_destination
    id = 1
    choices = {}
    @results_arr.each do |result|
      choices[id] = result
      id += 1
    end

    p choices

    print "Please choose a location for directions (num): "
    choice = gets.chomp.to_i

    choices[choice][1]
  end

  def get_directions(url)
    p url
    p RestClient.get(url)
  end
end

IceCreamFinder.new.start
