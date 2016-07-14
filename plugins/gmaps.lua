do

  local function run(msg, matches)
    local coords = get_coords(msg, matches[1])

    if coords then
      if msg.from.api then
        bot_sendLocation(get_receiver_api(msg), coords.lat, coords.lon, true, msg.id)
      else
        send_location(get_receiver(msg), coords.lat, coords.lon, ok_cb, true)
      end
    end
  end

  return {
    description = 'Returns a location from Google Maps.',
    usage = {
      '<code>!location [query]</code>',
      'Returns Google Maps of [query]',
    },
    patterns = {
      '^!gmaps (.*)$',
      '^!location (.*)$',
      '^!loc (.*)$',
    },
    run = run
  }

end
