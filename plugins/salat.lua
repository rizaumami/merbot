do

  local base_api = 'http://muslimsalat.com'
  local api_key = '?key=e2de2d3ed5c3b37b9d3bd6faeafa7891'

  function run(msg, matches)
    local url = base_api..'/'..URL.escape(matches[1])..'.json'

    if matches[2] and matches[2]:match('^%d+$') then
      if matches[2] == 0 or matches[2] > 7 then
        reply_msg(msg.id, 'Calculation method is out of range.\n'
            ..'Normally, you don\'t need to set this, it will auto select based on the country where query is located.\n'
            ..'Consult !help salat.', ok_cb, true)
      else
        url = url..'/'..matches[2]
      end
    end

    local res, code = http.request(url..api_key)
    if code ~= 200 then
      reply_msg(msg.id, 'Error: '..code, ok_cb, true)
      return
    end
    local salat = json:decode(res)

    if salat.title == '' then
      salat_area = salat.query..', '..salat.country
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
        ..'Isha     : '..salat.items[1].isha..'</code>', true, 'html')
  end

  return {
    description = 'Returns todays prayer times.',
    usage = {
      '<code> !salat [area]</code>',
      'Returns todays prayer times for that area',
      '<code> !salat [area] [method]</code>',
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
      '^!salat (.+)$',
      '^!salat (.+) (%d+)$',
    },
    run = run
  }

end

