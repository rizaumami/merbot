do

  local function run(msg, matches)
    local url = 'http://www.omdbapi.com/?plot=full&t=' .. URL.escape(matches[1])
    local jstr, res = http.request(url)
    local jdat = json:decode(jstr)

    if res ~= 200 or jdat.Response ~= 'True' then
      reply_msg(msg.id, 'Movie not found!', ok_cb, true)
      return
    end

    local omdb = '<a href="' .. jdat.Poster .. '">' .. jdat.Title .. '</a>\n\n'
        .. '<b>Year</b>: ' .. jdat.Year .. '\n'
        .. '<b>Rated</b>: ' .. jdat.Rated .. '\n'
        .. '<b>Runtime</b>: ' .. jdat.Runtime .. '\n'
        .. '<b>Genre</b>: ' .. jdat.Genre .. '\n'
        .. '<b>Director</b>: ' .. jdat.Director .. '\n'
        .. '<b>Writer</b>: ' .. jdat.Writer .. '\n'
        .. '<b>Actors</b>: ' .. jdat.Actors .. '\n'
        .. '<b>Country</b>: ' .. jdat.Country .. '\n'
        .. '<b>Awards</b>: ' .. jdat.Awards .. '\n'
        .. '<b>Plot</b>: ' .. jdat.Plot .. '\n\n'
        .. '<a href="http://imdb.com/title/' .. jdat.imdbID .. '">IMDB</a>:\n'
        .. '<b>Metascore</b>: ' .. jdat.Metascore .. '\n'
        .. '<b>Rating</b>: ' .. jdat.imdbRating .. '\n'
        .. '<b>Votes</b>: ' .. jdat.imdbVotes .. '\n\n'

    send_api_msg(msg, get_receiver_api(msg), omdb, false, 'html')
  end

  return {
    description = 'The Open Movie Database plugin for Telegram.',
    usage = {
      '<code>!imdb [movie]</code>',
      'Returns IMDb entry for <code>[movie]</code>',
    },
    patterns = {
      '^!imdb (.+)',
      '^!omdb (.+)'
    },
    run = run
  }

end
