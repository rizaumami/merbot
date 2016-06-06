do

  local function search_kickass(msg, query)
    local url = 'https://kat.cr/json.php?q='..URL.escape(query)

    local resp = {}

    local b,c = https.request {
      url = url,
      protocol = 'tlsv1',
      sink = ltn12.sink.table(resp)
    }

    resp = table.concat(resp)

    local data = json:decode(resp)
    local jresult = data.list

    if next(jresult) == nil then
      reply_msg(msg.id, 'No torrent results for: '..terms, ok_cb, true)
    else
      local katcrlist = {}
      for i = 1, #jresult do
        local torrent = jresult[i]
        local link = torrent.torrentLink:gsub('%?title=.+', '')

        if torrent.size > 1000000000 then
          divider = 1000000000
          unit = 'GB'
        else
          divider = 1000000
          unit = 'MB'
        end

        local size = tostring(torrent.size / divider)

        katcrlist[i] = '<b>'..i..'</b>. <a href="'..link..'">'..torrent.title..'</a>\n'
            ..'Seeds: <code>'..torrent.seeds..'</code> | '
            ..'Leechs: <code>'..torrent.leechs..'</code> | '
            ..'Size: <code>'..string.format("%.2f", size)..'</code>'..unit..'\n\n'
      end
      local torlist = table.concat(katcrlist)
      local header = '<b>'..query..'</b> results: <code>'..data.total_results..'</code> torrents\n\n'
      send_api_msg(msg, get_receiver_api(msg), header..torlist, true, 'html')
    end
  end

  local function run(msg, matches)
    return search_kickass(msg, matches[1])
  end

  return {
    description = 'Search Torrents',
    usage = {
      '<code>!torrent [search term]</code>',
      'Search for torrent',
    },
    patterns = {
      '^!torrent (.+)$'
    },
    run = run
  }

end