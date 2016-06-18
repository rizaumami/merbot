do

  function get_last_id(msg)
    local res,code  = https.request('http://xkcd.com/info.0.json')

    if code ~= 200 then
      reply_msg(msg.id, 'HTTP ERROR', ok_cb, true)
    end

    local data = json:decode(res)

    return data.num
  end

  function get_xkcd(msg, id)
    local res,code  = http.request('http://xkcd.com/'..id..'/info.0.json')

    if code ~= 200 then
      reply_msg(msg.id, 'HTTP ERROR', ok_cb, true)
    end

    local data = json:decode(res)
    local link_image = data.img

    if link_image:sub(0,2) == '//' then
      link_image = msg.text:sub(3,-1)
    end

    return link_image, data.num, data.title, data.alt
  end


  function get_xkcd_random(msg)
    local last = get_last_id(msg)
    local i = math.random(1, last)
    return get_xkcd(msg, i)
  end

  function send_title(cb_extra, success, result)
    if success then
      local message = cb_extra[2]..'\n'..cb_extra[3]
      send_msg(cb_extra[1], message, ok_cb, false)
    end
  end

  function run(msg, matches)
    if matches[1] == '!xkcd' then
      url, num, title, alt = get_xkcd_random(msg)
    else
      url, num, title, alt = get_xkcd(msg, matches[1])
    end

    local relevantxkcd = '<a href="' .. url .. '">xkcd #' .. num .. '</a>\n\n'
        .. '<b>' .. title .. '</b>\n' .. alt .. '\n\n'

    send_api_msg(msg, get_receiver_api(msg), relevantxkcd, false, 'html')
  end

  return {
    description = 'Send comic images from xkcd',
    usage = {
      '<code>!xkcd</code>',
      'Send random xkcd image and title.',
      '',
      '<code>!xkcd (id)</code>',
      'Send an xkcd image and title.'
    },
    patterns = {
      '^!xkcd$',
      '^!xkcd (%d+)',
      'xkcd.com/(%d+)'
    },
    run = run
  }

end
