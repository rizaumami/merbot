do

  local function run(msg, matches)

    if not is_chat_msg(msg) and not is_admin(msg.from.peer_id, msg) then return nil end

    local thread_limit = 5
    local is_nsfw = false

    if not is_chat_msg(msg) then
      thread_limit = 8
    end

    if matches[1] == 'nsfw' then
      is_nsfw = true
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
    local jdata_child = jdat.data.children
    if #jdata_child == 0 then
      return nil
    end
    local subreddit = '<b>'..(matches[2] or 'redd.it')..'</b>\n'
    for k=1, #jdata_child do
      local redd = jdata_child[k].data
      local long_url = '\n'
      if not redd.is_self then
        local link = URL.parse(redd.url)
        long_url = '\nLink: <a href="'..redd.url..'">'..link.scheme..'://'..link.host..'</a>\n'
      end
      local title = unescape_html(redd.title)
      if redd.over_18 and not is_nsfw then
        over_18 = subreddit..'You must be 18+ to view this community'
      elseif redd.over_18 and is_nsfw then
        subreddit = subreddit..'<b>'..k..'. NSFW</b> '..'<a href="redd.it/'..redd.id..'">'..title..'</a>'..long_url
      else
        subreddit = subreddit..'<b>'..k..'. </b>'..'<a href="redd.it/'..redd.id..'">'..title..'</a>'..long_url
      end
    end
    local reddit = over_18 or subreddit
    send_api_msg(msg, get_receiver_api(msg), reddit, true, 'html')
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
