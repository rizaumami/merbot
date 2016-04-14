do

  -- Gets coordinates for a location.
  local function get_coords(msg, input)

    local url = 'http://maps.googleapis.com/maps/api/geocode/json?address='..URL.escape(input)

    local jstr, res = http.request(url)
    if res ~= 200 then
      reply_msg(msg.id, 'Connection error.', ok_cb, true)
      return
    end

    local jdat = json:decode(jstr)
    if jdat.status == 'ZERO_RESULTS' then
      reply_msg(msg.id, 'ZERO_RESULTS', ok_cb, true)
      return
    end

    return {
      lat = jdat.results[1].geometry.location.lat,
      lon = jdat.results[1].geometry.location.lng
    }
  end

  local function run(msg, matches)
    local coords = get_coords(msg, matches[2])
    if coords then
      send_location(get_receiver(msg), coords.lat, coords.lon, ok_cb, true)
    end
  end

  return {
    description = 'Returns a location from Google Maps.',
    usage = {
      '<code> !location [query]</code>',
      'Returns Google Maps of [query]',
    },
    patterns = {
      '^!(location) (.*)$',
      '^!(loc) (.*)$',
    },
    run = run
  }
end
