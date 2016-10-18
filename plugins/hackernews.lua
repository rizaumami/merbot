do
  local topstories_url = 'https://hacker-news.firebaseio.com/v0/topstories.json'
  local res_url = 'https://hacker-news.firebaseio.com/v0/item/%s.json'
  local art_url = 'https://news.ycombinator.com/item?id=%s'

  local function get_hackernews_results(count)
    local results = {}
    local jstr, code = https.request(topstories_url)

    if code ~= 200 then return end

    local data = json:decode(jstr)

    for i = 1, count do
      local ijstr, icode = https.request(res_url:format(data[i]))
      if icode ~= 200 then return end
      local idata = json:decode(ijstr)
      local result
      if idata.url then
        result = string.format(
          '\n<b>' .. i .. '</b>. <code>[</code><a href="%s">%s</a><code>]</code> <a href="%s">%s</a>',
          html_escape(art_url:format(idata.id)),
          idata.id,
          html_escape(idata.url),
          html_escape(idata.title)
        )
      else
        result = string.format(
          '\n<b>' .. i .. '</b>. <code>[</code><a href="%s">%s</a><code>]</code> %s',
          html_escape(art_url:format(idata.id)),
          idata.id,
          html_escape(idata.title)
        )
      end
      table.insert(results, result)
    end

    return results
  end

  local function run(msg, matches)
    -- Four results in a group, eight in private.
    local res_count = msg.to.peer_id == msg.from.peer_id and 8 or 5
    local output = '<b>Top Stories from Hacker News:</b>'

    local hackernews = get_hackernews_results(res_count)

    for i = 1, res_count do
        output = output .. hackernews[i]
    end

    api.sendMessage(get_receiver_api(msg), output, 'html', true, false, msg.id)
  end

  return {
    description = 'Returns top stories from Hacker News.',
    usage = {
      '<code>!hackernews</code>',
      '<code>!hn</code>',
      'Returns top stories from Hacker News.',
    },
    patterns = {
      '^!(hackernews)$',
      '^!(hn)$',
    },
    run = run
  }

end
