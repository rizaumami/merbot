do

  local function run(msg, matches)
    local coords = get_coords(msg, matches[2])
    if coords then
      send_location(get_receiver(msg), coords.lat, coords.lon, ok_cb, true)
    end
  end

  return {
    description = 'Returns a location from Google Maps.',
    usage = {
      '<code>!location [query]</code>',
      'Returns Google Maps of [query]',
    },
    patterns = {
      '^!(location) (.*)$',
      '^!(loc) (.*)$',
    },
    run = run
  }
end
