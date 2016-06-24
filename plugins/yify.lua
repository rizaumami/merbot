do

  local function search_yify(msg, query)
    local url = 'https://yts.ag/api/v2/list_movies.json?limit=1&query_term='..URL.escape(query)
    local resp = {}

    local b,c = https.request {
      url = url,
      protocol = 'tlsv1',
      sink = ltn12.sink.table(resp)
    }

    resp = table.concat(resp)

    local jresult = json:decode(resp)

    if not jresult.data.movies then
      reply_msg(msg.id, 'No torrent results for: ' .. query, ok_cb, true)
    else
      local yify = jresult.data.movies[1]
      local yts720 = yify.torrents[1]
      local yts1080 = yify.torrents[2]
      local title = '<a href="' .. yify.large_cover_image .. '">' .. yify.title_long .. '</a>'
      local output = title .. '\n\n'
          .. '<code>' .. yify.year .. ' | ' .. yify.rating .. '/10 | ' .. yify.runtime .. '</code> min\n\n'
          .. '<b>720p</b> : <a href="' .. yts720.url .. '">.torrent</a>\n'
          .. 'Seeds: <code>' .. yts720.seeds .. '</code> | ' .. 'Peers: <code>' .. yts720.peers .. '</code> | ' .. 'Size: <code>' .. yts720.size .. '</code>\n\n'
          .. '<b>1080p</b> : <a href="' .. yts1080.url .. '">.torrent</a>\n'
          .. 'Seeds: <code>' .. yts1080.seeds .. '</code> | ' .. 'Peers: <code>' .. yts1080.peers .. '</code> | ' .. 'Size: <code>' .. yts1080.size .. '</code>\n\n'
          .. yify.synopsis .. '<a href="' .. yify.url .. '"> More on yts.ag ...</a>'
      send_api_msg(msg, get_receiver_api(msg), output, false, 'html')
    end
  end

  local function run(msg, matches)
    return search_yify(msg, matches[1])
  end

  return {
    description = 'Search YTS YIFY movies.',
    usage = {
      '<code>!yify [search term]</code>',
      '<code>!yts [search term]</code>',
      'Search YTS YIFY movie torrents from yts.ag',
    },
    patterns = {
      '^!yify (.+)$',
      '^!yts (.+)$'
    },
    run = run
  }

end