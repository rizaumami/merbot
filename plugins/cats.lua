do

  function run(msg, matches)
    local filetype = '&type=jpg'

    if matches[1] == 'gif' then
      filetype = '&type=gif'
    end

    local url = 'http://thecatapi.com/api/images/get?format=html' .. filetype .. '&api_key=' .. _config.key.cats
    local str, res = http.request(url)

    if res ~= 200 then
      send_message(msg, '<b>Connection error</b>', 'html')
      return
    end

    local str = str:match('<img src="(.-)">')

    api.sendMessage(get_receiver_api(msg), '<a href="' .. str .. '">Cat!</a>', 'html', false, false, msg.id)
  end

  return {
    description = 'Returns a cat!',
    usage = {
      '<code>!cat</code>',
      '<code>!cats</code>',
      'Returns a picture of cat!',
      '',
      '<code>!cat gif</code>',
      '<code>!cats gif</code>',
      'Returns an animated picture of cat!',
    },
    patterns = {
      '^!cats?$',
      '^!cats? (gif)$',
    },
    run = run,
    need_api_key = 'http://thecatapi.com/docs.html'
  }

end