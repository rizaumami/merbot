do

  local function run(msg, matches)

    local url = 'http://www.omdbapi.com/?t=' .. URL.escape(matches[1])
    local jstr, res = http.request(url)
    if res ~= 200 then
      sendReply(msg, config.errors.connection)
      return
    end

    local jdat = json:decode(jstr)
    if jdat.Response ~= 'True' then
      reply_msg(msg.id, 'Connection error.', ok_cb, true)
      return
    end


    local output = jdat.Title..' ('..jdat.Year..')\n\n'
    output = output..jdat.imdbRating..'/10 | '..jdat.Runtime..' | '..jdat.Genre..'\n'
    output = output..'http://imdb.com/title/'..jdat.imdbID..'\n\n'
    output = output..jdat.Plot

    reply_msg(msg.id, output, ok_cb, true)
  end

  return {
    description = 'IMDB plugin for telegram',
    usage = {
      '<code>!imdb [movie]</code>',
      'Returns IMDb entry for <code>[movie]</code>',
    },
    patterns = {
      '^!imdb (.+)'
    },
    run = run
  }

end
