do

  local function run(msg, matches)

    if not _config.api_key or not _config.api_key.nasa_api or _config.api_key.nasa_api == '' then
      local text = '<b>Missing</b> NASA API key in config.lua.\n\n'
          .. 'Get it from http://api.nasa.gov \n\n'
          .. 'Set the key using <code>!setapi nasa_api [api_key]</code>'

      bot_sendMessage(get_receiver_api(msg), text, true, msg.id, 'html')
      _config.api_key.nasa_api = 'DEMO_KEY'
    end

    local apodate = '<b>' .. os.date("%F") .. '</b>\n\n'
    local url = 'https://api.nasa.gov/planetary/apod?api_key=' .. _config.api_key.nasa_api

    if matches[2] then
      if matches[2]:match('%d%d%d%d%-%d%d%-%d%d$') then
        url = url .. '&date=' .. URL.escape(matches[2])
        apodate = '<b>' .. matches[2] .. '</b>\n\n'
      else
        send_message(msg, '<b>Request must be in following format</b>:\n<code>!' .. matches[1] .. ' YYYY-MM-DD</code>', 'html')
        return
      end
    end

    local str, res = https.request(url)

    if res ~= 200 then
      send_message(msg, '<b>Connection error</b>', 'html')
      return
    end

    local jstr = json:decode(str)

    if jstr.error then
      send_message(msg, '<b>No results found</b>', 'html')
      return
    end

    local img_url = jstr.hdurl or jstr.url
    local apod = apodate .. '<a href="' .. img_url .. '">' .. jstr.title .. '</a>'

    if matches[1] == 'apodtext' then
      apod = apod .. '\n\n' .. jstr.explanation
    end

    if jstr.copyright then
      apod = apod .. '\n\n<i>Copyright: ' .. jstr.copyright .. '</i>'
    end

    bot_sendMessage(get_receiver_api(msg), apod, false, msg.id, 'html')
  end

  return {
    description = "Returns the NASA's Astronomy Picture of the Day.",
    usage = {
      '<code>!apod</code>',
      'Returns the Astronomy Picture of the Day (APOD).',
      '',
      '<code>!apod YYYY-MM-DD</code>',
      'Returns the <code>YYYY-MM-DD</code> APOD.',
      '<b>Example</b>: <code>!apod 2016-08-17</code>',
      '',
      '<code>!apodtext</code>',
      'Returns the explanation of the APOD.',
      '',
      '<code>!apodtext YYYY-MM-DD</code>',
      'Returns the explanation of <code>YYYY-MM-DD</code> APOD.',
      '<b>Example</b>: <code>!apodtext 2016-08-17</code>',
      '',
    },
    patterns = {
      '^!(apod)$',
      '^!(apodtext)$',
      '^!(apod) (%g+)$',
      '^!(apodtext) (%g+)$',
    },
    run = run
  }

end
