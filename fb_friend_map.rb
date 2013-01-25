require 'koala'
require 'json'
require 'csv'
require 'net/http'
require 'rexml/document'

class FacebookFriendMap
  
  def get_locations
    @graph = Koala::Facebook::API.new("AAACEdEose0cBAPv8zIqi0LUHMz30JoDgaYjM1MKYPytJQcrmyFZBraZBMbQN3qSLahZBE4ifFz65ylNQ7NrxRS2b5vaQDlNe2ESCE8bbuZBOIqjCUpjJ")

    profile = @graph.get_object("me")
    friends = @graph.get_connections("me", "friends")

    # Hash of locations ("location" => [person1, person2, etc])
    location_data = {}
    
    10.times do |i|
      puts i
      f = friends[i]

      # Get user object
      id = f["id"]
      user = @graph.get_object(id)
      
      # If the user has a location, add to hash
      if user["location"]!= nil
        location = user["location"]["name"]
        user_name = user["name"]
        
        # Initialize empty array in hash
        location_data[location] ||= []
        
        location_data[location] << user_name         
      end

    end
    
    # This replaces the location with the latlong pairs
    formatted_data = format(location_data)
    
    save_locations(formatted_data)
  end
  
  
  # This method takes a hash of locations ("location" => [person1, person2, etc]),
  # and makes the keys an JSON file with of lat/long pairs
  def format(location_data)
    formatted_data = {}
    location_data.each do |location, people|
      latlong = geocode(location)
      formatted_data[latlong] = people
    end
    return formatted_data.to_json
  end
  
  # This method takes a location and parses it correctly
  # parseLocation("Chicago, Illinois") => "Chicago, IL"
  # def parseLocation(location)
  #   state = location[/^[\w+ ]+, ([\w ]+)+$/, 1]
  #   abbrev = STATE_ABBR[state]
  #   if abbrev != ""
  #     location.sub!(/(\w[\w ]+)$/, abbrev)
  #   end
  # end
  
  # Takes a location ("Chicago, Illinois") and returns lang/long coordinates [lang, long]
  def geocode(location)
    # First, try World Kit
    latlong = tryWorldKit(location)
    if latlong
      puts "Used worldkit"
      puts latlong
      return latlong
    else
      puts "Used google"
      return tryGoogle(location)
    end
  end
  
  # Uses WorldKit API to return an array: [lat, long]
  def tryWorldKit(location)
    url = getWorldKitURL(location)
    if url
      xml_data = Net::HTTP.get_response(URI.parse(url)).body
      doc = REXML::Document.new(xml_data)
      if doc.elements["*/geo:Point/geo:long"]
        long = doc.elements["*/geo:Point/geo:long"].text
        lat = doc.elements["*/geo:Point/geo:lat"].text
        return [lat, long]
      else
        return nil
      end
    else
      return nil
    end
  end
  
  # Uses Google API to return an array [lat, long]
  def tryGoogle(location)
    url = getGoogleURL(location)
    data = Net::HTTP.get_response(URI.parse(url)).body
    result = JSON.parse(data)
    latlong = result["results"][0]["geometry"]["location"]
    return [latlong["lat"], latlong["lng"]]
  end
  
  
  # This takes a location ("Chicago, Illinois"), and returns the correct URL
  # (http://maps.googleapis.com/maps/api/geocode/json?address=Chicago,IL&sensor=false)
  def getGoogleURL(location)
    url = "http://maps.googleapis.com/maps/api/geocode/json?address="
    city = location[/^([\w ]+), ([\w ]+)+$/, 1]
    state = location[/^([\w ]+), ([\w ]+)+$/, 2]
    city = city.gsub(' ', '+')
    state_abbrev = STATE_ABBR[state]
    
    # State abbrev is either a US state, or a country (Madrid, Spain)
    state_abbrev ||= state
    state_abbrev = state_abbrev.gsub(' ', '+')
    
    url << city <<',' << state_abbrev << "&sensor=false"
    return url
    
  end
  # This takes a location ("Chicago, Illinois"), and returns the correct URL
  # (http://worldkit.org/geocoder/rest/?city=Chicago,IL,US)
  def getWorldKitURL(location)
    url = "http://worldkit.org/geocoder/rest/?city="
    city = location[/^([\w ]+), ([\w ]+)+$/, 1]
    state = location[/^([\w ]+), ([\w ]+)+$/, 2]
    city = city.gsub(' ', '+')
    state = STATE_ABBR[state]
    if state != nil
      url << city << ',' << state << ',' << 'US'
      return url
    else
      return nil
    end
  end

  
  # def convert_locations_to_coords(locations)
  #   locations.each do |city, friends| 
  #     CSV.foreach("cities.csv") do |row|
  #       if row[0] == city
  #         if row[1] 
  #     end
  #   end
  # end
  
  def save_locations(locations)
    File.open('location_data.json', 'w') do |file|
      file.puts locations
    end
  end
  
  STATE_ABBR = {"Alabama"=>"AL", "Alaska"=>"AK", "Arizona"=>"AZ", 
    "Arkansas"=>"AR", "California"=>"CA", "Colorado"=>"CO", 
    "Connecticut"=>"CT", "Delaware"=>"DE", "Florida"=>"FL", 
    "Georgia"=>"GA", "Hawaii"=>"HI", "Idaho"=>"ID", 
    "Illinois"=>"IL", "Indiana"=>"IN", "Iowa"=>"IA", 
    "Kansas"=>"KS", "Kentucky"=>"KY", "Louisiana"=>"LA", 
    "Maine"=>"ME", "Maryland"=>"MD", "Massachusetts"=>"MA", 
    "Michigan"=>"MI", "Minnesota"=>"MN", "Mississippi"=>"MS", 
    "Missouri"=>"MO", "Montana"=>"MT", "Nebraska"=>"NE", "Nevada"=>"NV", 
    "New Hampshire"=>"NH", "New Jersey"=>"NJ", "New Mexico"=>"NM", 
    "New York"=>"NY", "North Carolina"=>"NC", "North Dakota"=>"ND", 
    "Ohio"=>"OH", "Oklahoma"=>"OK", "Oregon"=>"OR", "Pennsylvania"=>"PA", 
    "Rhode Island"=>"RI", "South Carolina"=>"SC", "South Dakota"=>"SD", 
    "Tennessee"=>"TN", "Texas"=>"TX", "Utah"=>"UT", "Vermont"=>"VT", 
    "Virginia"=>"VA", "Washington"=>"WA", "West Virginia"=>"WV", 
    "Wisconsin"=>"WI", "Wyoming"=>"WY"} 
  
  
end

fb = FacebookFriendMap.new
fb.get_locations()
# locations = fb.get_locations
# fb.convert_locations_to_coords(locations)
# json_locations = locations.to_json
# fb.save_locations(json_locations)
