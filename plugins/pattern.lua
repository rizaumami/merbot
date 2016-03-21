do

  local words = { -- perhaps, maybe, do you, etc...
    'Mungkin maksud',
    'Pasti maksud',
    'Apakah maksud',
    'Mungkinkah maksud',
    'Ane yakin maksud',
    'Mimin yakin maksud',
    'Saya rasa maksud',
  }
  
  local target = { -- you 
    'kamu',
    'ente',
    'Anda',
    'sampeyan',
    'akang',
    'lu',
    'Bapak',
    'Ibu',
    'kakak',
  }

  local function action_by_reply(extra, success, result)
    local output = result.text or ''
    output = output:gsub(extra.text:match('^/s/(.-)/(.-)/?$'))
    output = words[math.random(#words)]..' '..target[math.random(#target)]..':\n"'..output:sub(1, 4000)..'"'
    reply_msg(result.id, output, ok_cb, true)
  end

  local function run(msg, matches)
    if msg.reply_id then
      get_message(msg.reply_id, action_by_reply, msg)
    end
  end

  return {
    description = '',
    usage = {},
    patterns = {
      '^/s/.-/.-/?$'
    },
    run = run
  }

end
