do

  local tag_list = {
    ['&#183;'] = '·',
    ['<sup>.-/sup>'] = '',
    ['<br/>'] = '\n',
    ['—'] = '--',
    [' <b>1'] = '\n<b>1',
    [' <b>2'] = '\n<b>2',
    [' <b>3'] = '\n<b>3',
    [' <b>4'] = '\n<b>4',
    [' <b>5'] = '\n<b>5',
    [' <b>6'] = '\n<b>6',
    [' <b>7'] = '\n<b>7',
    [' <b>8'] = '\n<b>8',
    [' <b>9'] = '\n<b>9',
    [' <b>10'] = '\n<b>10'
  }

  local function cleanup_tag(html)
    for k,v in pairs(tag_list) do
      html = html:gsub(k, v)
    end
    return html
  end

  local function get_kbbi(msg, lema)
    local webkbbi = 'http://kbbi.web.id/' .. lema .. '/ajax_0'
    local res, code = http.request(webkbbi)

    if res == '' then
      if msg.from.api then
        bot_sendMessage(get_receiver_api(msg), 'Tidak ada arti kata "<b>' .. lema .. '</b>" di http://kbbi.web.id', true, msg.id, 'html')
      else
        reply_msg(msg.id, 'Tidak ada arti kata "' .. lema .. '" di http://kbbi.web.id', ok_cb, true)
      end
      return
    end

    local grabbedlema = res:match('{"x":1,"w":.-}')
    local jlema = json:decode(grabbedlema)
    local title = '<a href="http://kbbi.web.id/' .. lema .. '">' .. cleanup_tag(jlema.w) .. '</a>\n\n'

    if jlema.d:match('<br/>') then
      local description = jlema.d:match('^.-<br/>')
      kbbi_desc = cleanup_tag(description)
    else
      kbbi_desc = cleanup_tag(jlema.d)
    end

    bot_sendMessage(get_receiver_api(msg), title .. kbbi_desc, true, msg.id, 'html')
  end

  local function run(msg, matches)
    get_kbbi(msg, matches[1])
  end

--------------------------------------------------------------------------------

  return {
    description = 'Kamus Besar Bahasa Indonesia dari http://kbbi.web.id.',
    usage = {
      '<code>!kbbi [lema]</code>',
      'Menampilkan arti dari <code>[lema]</code>'
    },
    patterns = {
      '^!kbbi (%g+)$'
    },
    run = run
  }

end
