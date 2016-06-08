do

	function run(msg, matches)
		local url = 'http://thecatapi.com/api/images/get?format=html&type=jpg&api_key=OTM1NjY'
		local str, res = http.request(url)

		if res ~= 200 then
			reply_msg(msg.id, 'Connection error.', ok_cb, true)
			return
		end

		str = str:match('<img src="(.-)">')

		send_api_msg(msg, get_receiver_api(msg), '<a href="'..str..'">Cat!</a>', false, 'html')
	end

  return {
    description = 'Returns a cat!',
    usage = {
      '<code>!cat</code>',
      'Returns a cat!',
      '',
    },
    patterns = {
      '^!(cat)$',
    },
    run = run
  }

end