do

  local base_api = 'http://muslimsalat.com'
  local api_key = '?key=e2de2d3ed5c3b37b9d3bd6faeafa7891'
  local calculation = {
    [1] = 'Egyptian General Authority of Survey',
    [2] = 'University Of Islamic Sciences, Karachi (Shafi)',
    [3] = 'University Of Islamic Sciences, Karachi (Hanafi)',
    [4] = 'Islamic Circle of North America',
    [5] = 'Muslim World League',
    [6] = 'Umm Al-Qura',
    [7] = 'Fixed Isha'
  }

  function run(msg, matches)
    local area = matches[1]
    local method = 5
    local notif = ''
    local url = base_api..'/'..URL.escape(area)..'.json'

    if matches[2] and matches[1]:match('%d') then
      local c_method = tonumber(matches[1])
      if c_method == 0 or c_method > 7 then
        reply_msg(msg.id, 'Calculation method is out of range.\n'
            ..'Consult !help salat.', ok_cb, true)
        return
      else
        method = c_method
        url = base_api..'/'..URL.escape(matches[2])..'.json'
        notif = '\n\nMethod: '..calculation[method]
        area = matches[2]
      end
    end

    local res, code = http.request(url..'/'..method..api_key)
    if code ~= 200 then
      reply_msg(msg.id, 'Error: '..code, ok_cb, true)
      return
    end
    local salat = json:decode(res)

    if salat.title == '' then
      salat_area = area..', '..salat.country
    else
      salat_area = salat.title
    end

    send_api_msg(msg, get_receiver_api(msg), '<b>Salat time</b>\n\n'
        ..'<a href="'..salat.link..'">'..salat_area..'</a>\n'
        ..salat.items[1].date_for..'\n\n'
        ..'Qibla : <code>'..salat.qibla_direction..'°\n'
        ..'Fajr     : '..salat.items[1].fajr..'\n'
        ..'Sunrise  : '..salat.items[1].shurooq..'\n'
        ..'Dhuhr    : '..salat.items[1].dhuhr..'\n'
        ..'Asr      : '..salat.items[1].asr..'\n'
        ..'Maghrib  : '..salat.items[1].maghrib..'\n'
        ..'Isha     : '..salat.items[1].isha..'</code>'..notif, true, 'html')
  end

  return {
    description = 'Returns todays prayer times.',
    usage = {
      '<code>!salat [area]</code>',
      'Returns todays prayer times for that area',
      '',
      '<code>!salat [method] [area]</code>',
      'Returns todays prayer times for that area calculated by [method]:',
      '<b>1</b> = Egyptian General Authority of Survey',
      '<b>2</b> = University Of Islamic Sciences, Karachi (Shafi)',
      '<b>3</b> = University Of Islamic Sciences, Karachi (Hanafi)',
      '<b>4</b> = Islamic Circle of North America',
      '<b>5</b> = Muslim World League',
      '<b>6</b> = Umm Al-Qura',
      '<b>7</b> = Fixed Isha'
    },
    patterns = {
      '^!salat (%a.*)$',
      '^!salat (%d) (%a.*)$',
    },
    run = run
  }

end

