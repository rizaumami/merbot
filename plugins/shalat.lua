-- http://aladhan.com/rest-api_key
-- http://api.aladhan.com/timings/<timestamp>?latitude=<lat>&longitude=<long>&timezonestring=<tz>&method=<method>

do

  -- Use timezone api to get the time in the lat,
  -- Note: this needs an API key
  function get_time_zone(msg, lat, lng)
    local api = 'http://maps.googleapis.com/maps/api/timezone/json?'

    -- Get a timestamp (server time is relevant here)
    local timestamp = msg.date
    local parameters = 'location='..URL.escape(lat)..','..URL.escape(lng)
        ..'&timestamp='..URL.escape(timestamp)

    local res,code = https.request(api..parameters)
    if code ~= 200 then
      return nil
    end
    local data = json:decode(res)

    if (data.status == 'ZERO_RESULTS') then
      return nil
    end
    if (data.status == 'OK') then
      -- Construct what we want
      -- The local time in the location is:
      -- timestamp + rawOffset + dstOffset
      local localTime = timestamp + data.rawOffset + data.dstOffset
      return localTime, data.timeZoneId
    end
    return localTime
  end

  function getshalatTime(msg, area)
    local shalat_api = 'http://api.aladhan.com/timings'
    local method = '&method=3' -- Muslim World League (MWL)

    lat, lng, acc = get_latlong(area)
    local localTime, timeZoneId = get_time_zone(msg, lat, lng)
    local coordinates = '?latitude='..URL.escape(lat)..'&longitude='..URL.escape(lng)
    local tzstring = '&timezonestring='..URL.escape(timeZoneId)

    local res, code = http.request(shalat_api..'/'..localTime..coordinates..tzstring..method)

    local jdan = json:decode(res)
    local shalat = jdan.data.timings
    local todate = jdan.data.date.readable

    send_api_msg(msg, get_receiver_api(msg), '<b>Prayer time</b>\n'
        ..'in <b>'..area..'</b> ('..timeZoneId..')\n'
        ..'on <code>'..todate..'</code> is:\n\n'
        ..'<code>Fajr     : '..shalat.Fajr..'\n'
        ..'Sunrise  : '..shalat.Sunrise..'\n'
        ..'Dhuhr    : '..shalat.Dhuhr..'\n'
        ..'Asr      : '..shalat.Asr..'\n'
        ..'Maghrib  : '..shalat.Maghrib..'\n'
        ..'Sunset   : '..shalat.Sunset..'\n'
        ..'Isha     : '..shalat.Isha..'</code>', true, 'html')
  end

  function run(msg, matches)
    return getshalatTime(msg, matches[1])
  end

  return {
    description = 'Returns todays prayer times.',
    usage = {
      '<code> !shalat [area]</code>',
      'Returns todays prayer times for that area',
    },
    patterns = {
      '^!shalat (.*)$',
      '^!sholat (.*)$',
      '^!salah (.*)$',
      '^!salat (.*)$'
    },
    run = run
  }

end


