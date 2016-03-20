do

  local function run(msg, matches)

    if not is_chat_msg(msg) and not is_admin(msg.from.peer_id, msg) then return nil end

    if is_chat_msg(msg) then
      thread_limit = 5
    else
      thread_limit = 8
    end

    if matches[1] == 'nsfw' then
      is_nsfw = true
    else
      is_nsfw = false
    end

    if matches[2] then
      if matches[2]:match('^r/') then
        url = 'https://www.reddit.com/'..matches[2]..'/.json?limit='..thread_limit
      else
        url = 'https://www.reddit.com/search.json?q='..matches[2]..'&limit='..thread_limit
      end
    elseif msg.text == '!reddit' then
      url = 'https://www.reddit.com/.json?limit='..thread_limit
    end

    -- Do the request
    local res, code = https.request(url)
    if code ~=200 then return nil  end

    local jdat = json:decode(res)
    if #jdat.data.children == 0 then
      return nil
    end
    local subreddit = '<b>'..(matches[2] or 'redd.it')..'</b>\n'
    for i,v in ipairs(jdat.data.children) do
      local long_url = '\n'
      if not v.data.is_self then
        local link = URL.parse(v.data.url)
        long_url = '\nLink: <a href="'..v.data.url..'">'..link.scheme..'://'..link.host..'</a>\n'
      end
      local title = unescape_html(v.data.title)
      if v.data.over_18 and not is_nsfw then
        subreddit = ''
      elseif v.data.over_18 and is_nsfw then
        subreddit = subreddit..'<b>'..i..'. NSFW</b> '..'<a href="redd.it/'..v.data.id..'">'..title..'</a>'..long_url
      else
        subreddit = subreddit..'<b>'..i..'. </b>'..'<a href="redd.it/'..v.data.id..'">'..title..'</a>'..long_url
      end
    end
    send_api_msg(get_receiver_api(msg), subreddit, true, 'html')
  end

--------------------------------------------------------------------------------

  return {
    description = 'Returns the five (if group) or eight (if private message) top posts for the given subreddit or query, or from the frontpage.',
    usage = {
      '<code>!reddit</code>',
      'Reddit frontpage.',
      '<code>!reddit r/[query]</code>',
      '<code>!r r/[query]</code>',
      'Subreddit',
      '<code>!redditnsfw [query]</code>',
      '<code>!rnsfw [query]</code>',
      'Subreddit (include NSFW).',
      '<code>!reddit [query]</code>',
      '<code>!r [query]</code>',
      'Search subreddit.',
      '<code>!redditnsfw [query]</code>',
      '<code>!rnsfw [query]</code>',
      'Search subreddit (include NSFW).'
    },
    patterns = {
      '^!reddit$',
      '^!(r) (.*)$',
      '^!(reddit) (.*)$',
      '^!r(nsfw) (.*)$',
      '^!reddit(nsfw) (.*)$'
    },
    run = run
  }

end
