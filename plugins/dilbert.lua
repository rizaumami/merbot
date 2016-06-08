do

	local function run(msg, matches)
		local input = os.date('%F')

		if matches[2] and matches[2]:match('%d%d%d%d%-%d%d%-%d%d') then
			input = matches[2]
		end

		local url = 'http://dilbert.com/strip/'..URL.escape(input)
		local str, res = http.request(url)
		if res ~= 200 then
			reply_msg(msg.id, 'Connection error.', ok_cb, true)
			return
		end

		local strip_filename = '/tmp/' .. input .. '.gif'
		local strip_file = io.open(strip_filename)
		if strip_file then
			strip_file:close()
			strip_file = strip_filename
		else
			local strip_url = str:match('<meta property="og:image" content="(.-)"/>')
			strip_file = download_to_file(strip_url, input..'.gif')
		end

		local strip_title = str:match('<meta property="og:title" content="(.-)"/>')
		local strip_date = str:match('<meta property="article:publish_date" content="(.-)"/>')
    local cmd = 'send_photo %s %s %s'
    local command = cmd:format(get_receiver(msg), strip_file, strip_date..'. '..strip_title)
    os.execute(tgclie:format(command))
	end

	return {
    description = 'Returns the latest Dilbert strip or that of the provided date.\n'
				..'Dates before the first strip will return the first strip.\n'
				..'Dates after the last trip will return the last strip.\n'
				..'Source: dilbert.com',
    usage = {
    	'<code>!dilbert</code>',
    	'Returns todays Dilbert comic',
    	'',
    	'<code>!dilbert [date]</code>',
    	'Returns <code>[date]</code> Dilbert comic',
    	'',
    },
    patterns = {
      '^!(dilbert)$',
      '^!(dilbert) (%d%d%d%d%-%d%d%-%d%d)$'
    },
    run = run
  }
end