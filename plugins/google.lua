do

  local function run(msg, matches)
    -- comment this line if you want this plugin to works in private message.
    if not is_chat_msg(msg) and not is_admin(msg.from.peer_id) then return nil end

    local url        = 'https://ajax.googleapis.com/ajax/services/search/web?v=1.0'
    local parameters = '&q='..(URL.escape(matches[2]) or '')

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

    -- Do the request
    local res, code = https.request(url..parameters)
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

--------------------------------------------------------------------------------

  return {
    description = 'Returns 5 (if group) or 8 (if private message) Google results. Safe search is enabled by default, use <code>!gnsfw</code> or <code>!googlensfw</code> to disable it.',
    usage = {
      '<code>!google [terms]</code>',
      '<code>!g [terms]</code>',
      'Safe searches Google',
      '<code>!googlensfw [terms]</code>',
      '<code>!gnsfw [terms]</code>',
      'Searches Google (include NSFW)'
    },
    patterns = {
      '^!(g) (.*)$',
      '^!g(nsfw) (.*)$',
      '^!(google) (.*)$',
      '^!google(nsfw) (.*)$',
      '^%.([g|G]oogle) (.*)$'
    },
    run = run
  }

end
