do

  function run(msg, matches)
    local url = 'http://thecatapi.com/api/images/get?format=html&type=jpg&api_key=' .. _config.api_key.thecatapi
    local str, res = http.request(url)

    if res ~= 200 then
      send_message(msg, '<b>Connection error</b>', 'html')
      return
    end

    local str = str:match('<img src="(.-)">')

    bot_sendMessage(get_receiver_api(msg), '<a href="' .. str .. '">Cat!</a>', false, msg.id, 'html')
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