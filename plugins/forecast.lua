do

  local function round(val, decimal)
    local exp = decimal and 10^decimal or 1
    return math.ceil(val * exp - 0.5) / exp
  end

  local function wemoji(weather_data)
    if weather_data.icon == 'clear-day' then
    return '☀️'
    elseif weather_data.icon == 'clear-night' then
      return '🌙'
    elseif weather_data.icon == 'rain' then
      return '☔️'
    elseif weather_data.icon == 'snow' then
    return '❄️'
    elseif weather_data.icon == 'sleet' then
      return '🌨'
    elseif weather_data.icon == 'wind' then
      return '💨'
    elseif weather_data.icon == 'fog' then
      return '🌫'
    elseif weather_data.icon == 'cloudy' then
      return '☁️☁️'
    elseif weather_data.icon == 'partly-cloudy-day' then
      return '🌤'
    elseif weather_data.icon == 'partly-cloudy-night' then
      return '🌙☁️'
    else
      return ''
    end
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
    local forecast = forecast .. '<b>Right now</b> ' .. wemoji(jcast.currently) .. '\n'
        .. jcast.currently.summary .. ' - Feels like ' .. round(jcast.currently.apparentTemperature) .. '°C\n\n'
    local forecast = forecast .. '<b>Next 24 hours</b> ' .. wemoji(jcast.hourly) .. '\n' .. jcast.hourly.summary .. '\n\n'
    local forecast = forecast .. '<b>Next 7 days</b> ' .. wemoji(jcast.daily) .. '\n' .. jcast.daily.summary

    bot_sendMessage(get_receiver_api(msg), forecast, true, msg.id, 'html')
  end

  local function run(msg, matches)
    return getforecast(msg, matches[1])
  end

  return {
    description = 'Returns forecast from forecast.io.',
    usage = {
      '<code>!cast [area]</code>',
      '<code>!forecast [area]</code>',
      '<code>!weather [area]</code>',
      'Forecast for that <code>[area]</code>.',
      '<b>Example</b>: <code>!weather dago parung panjang</code>',
    },
    patterns = {
      '^!cast (.*)$',
      '^!forecast (.*)$',
      '^!weather (.*)$'
    },
    run = run
  }

end


