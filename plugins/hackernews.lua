do

  local function run(msg, matches)

    local jstr, res = https.request('https://hacker-news.firebaseio.com/v0/topstories.json')
    if res ~= 200 then
      reply_msg(msg.id, 'Connection error.', ok_cb, true)
      return
    end

    local jdat = json:decode(jstr)
    local res_count = 8
    local output = '<b>Hacker News</b>\n\n'
    for i = 1, res_count do
      local res_url = 'https://hacker-news.firebaseio.com/v0/item/'..jdat[i]..'.json'
      jstr, res = https.request(res_url)

      if res ~= 200 then
        reply_msg(msg.id, 'Connection error.', ok_cb, true)
        return
      end

      local res_jdat = json:decode(jstr)
      local title = res_jdat.title:gsub('%[.+%]', ''):gsub('%(.+%)', ''):gsub('&amp;', '&')
      if title:len() > 48 then
        title = title:sub(1, 45)..'...'
      end

      local url = res_jdat.url
      if not url then
        reply_msg(msg.id, 'Connection error.', ok_cb, true)
        return
      end
      local title = unescape_html(title)
      output = output..'<b>'..i..'</b>. <a href="'..url..'">'..title..'</a>\n'
    end

    send_api_msg(msg, get_receiver_api(msg), output, true, 'html')
  end

  return {
    description = 'Returns top stories from Hacker News.',
    usage = {
      '<code> !hackernews</code>',
      '<code> !hn</code>',
    },
    patterns = {
      '^!(hackernews)$',
      '^!(hn)$',
    },
    run = run
  }

end
