do

	local function run(msg, matches)

		if not _config.api_key or not _config.api_key.nasa_api or _config.api_key.nasa_api == '' then
      local text = '<b>Missing</b> NASA API key in config.lua.\n\n'
          ..'Get it from http://api.nasa.gov \n\n'
          ..'Set the key using <code>setapi nasa_api [api_key]</code>'
      send_api_msg(msg, get_receiver_api(msg), text, true, 'html')
      _config.api_key.nasa_api = 'DEMO_KEY'
    end

		local date = '<b>'..os.date("%F")..'</b>\n'
		local url = 'https://api.nasa.gov/planetary/apod?api_key='.._config.api_key.nasa_api

		if matches[2] then
			if matches[2]:match('%d%d%d%d%-%d%d%-%d%d$') then
				url = url..'&date='..URL.escape(matches[2])
				date = '<b>'..matches[2]..'</b>\n'
			else
				reply_msg(msg.id, 'Request must be in following format:\n!'..matches[1]..' YYYY-MM-DD', ok_cb, true)
				return
			end
		end

		local str, res = https.request(url)
		if res ~= 200 then
			reply_msg(msg.id, 'Connection error.', ok_cb, true)
			return
		end

		local jstr = json:decode(str)
		if jstr.error then
			reply_msg(msg.id, 'No results found.', ok_cb, true)
			return
		end

		if matches[1] =='apod' then
			img_url = jstr.url
		end

		if matches[1] =='apodhd' then
			img_url = jstr.hdurl or jstr.url
		end

		local output = date..'<a href="'..img_url..'">'..jstr.title..'</a>'

		if matches[1] == 'apodtext' then
			output = output..'\n'..jstr.explanation
		end

		if jstr.copyright then
			output = output..'\nCopyright: '..jstr.copyright
		end

		send_api_msg(msg, get_receiver_api(msg), output, false, 'html')
	end

	return {
    description = "Returns the NASA's Astronomy Picture of the Day.",
    usage = {
      '<code>!apod [query]</code>',
      'Returns the Astronomy Picture of the Day.',
      'If the query is a date, in the format YYYY-MM-DD, the APOD of that day is returned.',
      '',
      '<code>!apodhd [query]</code>',
      'Returns the image in HD, if available.',
      '',
      '<code>!apodtext [query]</code>',
      'Returns the explanation of the APOD.'
    },
    patterns = {
      '^!(apod)$',
      '^!(apodhd)$',
      '^!(apodtext)$',
      '^!(apod) (.*)$',
      '^!(apodhd) (.*)$',
      '^!(apodtext) (.*)$',
    },
    run = run
  }

end
