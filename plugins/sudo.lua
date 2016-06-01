do

  local function cb_getdialog(extra, success, result)
    vardump(extra)
    vardump(result)
  end

  local function parsed_url(link)
    local parsed_link = URL.parse(link)
    local parsed_path = URL.parse_path(parsed_link.path)
    for k,segment in pairs(parsed_path) do
      if segment == 'joinchat' then
        invite_link = parsed_path[k+1]:gsub('[ %c].+$', '')
        break
      end
    end
    return invite_link
  end

  local function action_by_reply(extra, success, result)
    local hash = parsed_url(result.text)
    join = import_chat_link(hash, ok_cb, false)
  end

--------------------------------------------------------------------------------

  function run(msg, matches)

    if not is_sudo(msg.from.peer_id) then
      return
    end

    if matches[1] == 'bin' then
      local input = matches[2]:gsub('—', '--')
      local header = '<b>$</b> <code>'..input..'</code>\n'
      local stdout = io.popen(input):read('*all')
      send_api_msg(msg, get_receiver_api(msg), header..'<code>'..stdout..'</code>', true, 'html')
    end

    if matches[1] == 'bot' then
      if matches[2] == 'token' then
        if not _config.bot_api then
          _config.bot_api = {key = '', uid = '', uname = ''}
        end
        _config.bot_api.key = matches[3]
        _config.bot_api.uid = matches[3]:match('^%d+')
        save_config()
        reply_msg(msg.id, 'Bot API key has been saved.', ok_cb, true)
      end
      if matches[2] == 'apiname' then
        _config.bot_api.uname = matches[3]:gsub('@', '')
        save_config()
        reply_msg(msg.id, 'Bot API username has been saved.', ok_cb, true)
      end
    end
    if matches[1] == "block" then
      block_user("user#id"..matches[2], ok_cb, false)

      if is_mod(matches[2], msg.to.peer_id) then
        return "You can't block moderators."
      end
      if is_admin(matches[2]) then
        return "You can't block administrators."
      end
      block_user("user#id"..matches[2], ok_cb, false)
      return "User blocked"
    end

    if matches[1] == "unblock" then
      unblock_user("user#id"..matches[2], ok_cb, false)
      return "User unblocked"
    end

    if matches[1] == "join" then
      if msg.reply_id then
        get_message(msg.reply_id, action_by_reply, msg)
      elseif matches[2] then
        local hash = parsed_url(matches[2])
        join = import_channel_link(hash, ok_cb, false)
      end
    end

    if matches[1] == 'api set' or matches[1] == 'apiset' or matches[1] == 'setapi' and matches[3] then
      if not _config.api_key then
        _config.api_key = {
          -- https://datamarket.azure.com/dataset/bing/search
          bing = '',
          -- http://console.developers.google.com
          google = '',
          -- https://cse.google.com/cse
          google_cse = '',
          -- http://openweathermap.org/appid
          owm = '',
          -- http://last.fm/api
          lastfm = '',
          -- http://api.biblia.com
          biblia = '',
          -- http://thecatapi.com/docs.html
          thecatapi = '',
          -- http://api.nasa.gov
          nasa_api = '',
          -- http://tech.yandex.com/keys/get
          yandex = '',
          -- http://developer.simsimi.com/signUp
          simsimi = '',
          simsimi_trial = true,
        }
      end
      if matches[2] == 'bing' then
        _config.api_key.bing = matches[3]
      elseif matches[2] == 'google' then
        _config.api_key.google = matches[3]
      elseif matches[2] == 'google_cse' then
        _config.api_key.google_cse = matches[3]
      elseif matches[2] == 'owm' then
        _config.api_key.owm = matches[3]
      elseif matches[2] == 'lastfm' then
        _config.api_key.lastfm = matches[3]
      elseif matches[2] == 'biblia' then
        _config.api_key.biblia = matches[3]
      elseif matches[2] == 'thecatapi' then
        _config.api_key.thecatapi = matches[3]
      elseif matches[2] == 'nasa_api' then
        _config.api_key.nasa_api = matches[3]
      elseif matches[2] == 'yandex' then
        _config.api_key.yandex = matches[3]
      elseif matches[2] == 'simsimi' then
        _config.api_key.simsimi = matches[3]
      elseif matches[2] == 'simsimi_trial' then
        _config.api_key.simsimi_trial = matches[3]
      end
      save_config()
      reply_msg(msg.id, matches[2]..' API key has been saved.', ok_cb, true)
    end
  end

  --------------------------------------------------------------------------------

  return {
    description = 'Various sudo commands.',
    usage = {
      sudo = {
        '<code>!bin [command]</code>',
        'Run a system command.',
        '',
        '<code>!block [user_id]</code>',
        'Block user_id to PM.',
        '',
        '<code>!unblock [user_id]</code>',
        'Allowed user_id to PM.',
        '',
        '<code>!bot restart</code>',
        'Restart bot.',
        '',
        '<code>!bot status</code>',
        'Print bot status.',
        '',
        '<code>!bot token [bot_api_key]</code>',
        'Input bot API key.',
        '',
        '<code>!join</code>',
        'Join a group by replying a message containing invite link.',
        '',
        '<code>!join [invite_link]</code>',
        'Join into a group by providing their [invite_link].',
        '',
        '<code>!api set [service] [api_key]</code>',
        '<code>!apiset [service] [api_key]</code>',
        '<code>!setapi [service] [api_key]</code>',
        'Set services (Bing, Google, etc) API key.',
        '',
        '<code>!version</code>',
        'Shows bot version',
      },
    },
    patterns = {
      '^!(bin) (.*)$',
      '^!(block) (.*)$',
      '^!(unblock) (.*)$',
      '^!(block) (%d+)$',
      '^!(unblock) (%d+)$',
      '^!(bot) (%g+) (.*)$',
      '^!(join)$',
      '^!(join) (.*)$',
      '^!(api set) (%g+) (.*)$','!^(apiset) (%g+) (.*)$', '^!(setapi) (%g+) (.*)$',
    },
    run = run
  }

end

