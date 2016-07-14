do

  local function round(val, decimal)
    local exp = decimal and 10^decimal or 1
    return math.ceil(val * exp - 0.5) / exp
  end

  -- Use timezone api to get the time in the lat
  local function getforecast(msg, area)
    local coords, code = get_coords(msg, area)
    local lat = coords.lat
    local long = coords.lon
    local address = coords.formatted_address
    local url = 'https://api.forecast.io/forecast/'
    local units = '?units=si'
    local url = url .. _config.api_key.forecast .. '/' .. URL.escape(lat) .. ',' .. URL.escape(long) .. units

    local res, code = https.request(url)
    if code ~= 200 then
      return nil
    end
    local jcast = json:decode(res)
    local todate = os.date('%A, %F', jcast.currently.time)

    local forecast = '<b>Weather for: ' .. address .. '</b>\n' .. todate .. '\n\n'
    local forecast = forecast .. '<b>Right now</b>\n' .. jcast.currently.summary
        .. ' - Feels like ' .. round(jcast.currently.apparentTemperature) .. '°C\n\n'
    local forecast = forecast .. '<b>Next 24 hours</b>\n' .. jcast.hourly.summary .. '\n\n'
    local forecast = forecast .. '<b>Next 7 days</b>\n' .. jcast.daily.summary

    bot_sendMessage(get_receiver_api(msg), forecast, true, msg.id, 'html')
  end

  local function run(msg, matches)
    return getforecast(msg, matches[1])
  end

  return {
    description = 'Returns forecast from forecast.io.',
    usage = {
      '<code>!cast [area]</code>',
      '<code>!weather [area]</code>',
      'Forecast for that [area].',
    },
    patterns = {
      '^!cast (.*)$',
      '^!forecast (.*)$',
      '^!weather (.*)$'
    },
    run = run
  }

end


