do

  local function lmgtfy(url)
    -- Do the request
    local res, code = https.request(url)
    if code ~=200 then return nil  end
    local data = json:decode(res)

    local stringresults=''
    for key,result in ipairs(data.responseData.results) do
      stringresults = stringresults..'<b>'..key..'</b>. '
                      ..'<a href="'..(result.unescapedUrl or result.url)..'">'
                      ..unescape_html(result.titleNoFormatting)..'</a>\n'
    end
    send_api_msg(msg, receiver, stringresults, true, 'html')
  end

  local function lmgtfy_by_reply(extra, success, result)
    local terms = result.text
    local url = extra.url..'&q='..(URL.escape(terms) or '')
    lmgtfy(url)
  end

  local function run(msg, matches)
    -- comment this line if you want this plugin to works in private message.
    if not is_chat_msg(msg) and not is_admin(msg.from.peer_id) then return nil end

    local url        = 'https://ajax.googleapis.com/ajax/services/search/web?v=1.0'

    if is_chat_msg(msg) then
      url = url..'&rsz=5'
      if msg.to.peer_type == 'channel' then
        receiver = '-100'..msg.to.peer_id
      else
        receiver = '-'..msg.to.peer_id
      end
    else
      url = url..'&rsz=8'
      receiver = msg.from.peer_id
    end

    if not matches[1]:match('nsfw') then
      url = url .. '&safe=active'
    end

    if msg.reply_id then
      get_message(msg.reply_id, lmgtfy_by_reply, {url=url})
    else
      local url = url..'&q='..(URL.escape(matches[2]) or '')
      lmgtfy(url)
    end
  end

--------------------------------------------------------------------------------

  return {
    description = 'Returns 5 (if group) or 8 (if private message) Google results. Safe search is enabled by default, use <code>!gnsfw</code> or <code>!googlensfw</code> to disable it.',
    usage = {
      '<code>!google [terms]</code>',
      '<code>!g [terms]</code>',
      'Safe searches Google',
      '<code>!google</code>',
      '<code>!g</code>',
      'Safe searches Google by reply. The search terms is the replied message text.',
      '<code>!googlensfw [terms]</code>',
      '<code>!gnsfw [terms]</code>',
      'Searches Google (include NSFW)'
      '<code>!googlensfw</code>',
      '<code>!gnsfw</code>',
      'Searches Google (include NSFW). The search terms is the replied message text.'
    },
    patterns = {
      '^!(g)$', '^!(google)$',
      '^!g(nsfw)$', '^!google(nsfw)$',
      '^%.([g|G]oogle)$',
      '^!(g) (.*)$', '^!(google) (.*)$',
      '^!g(nsfw) (.*)$', '^!google(nsfw) (.*)$',
      '^%.([g|G]oogle) (.*)$'
    },
    run = run
  }

end
