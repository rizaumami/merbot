do

--------------------------------------------------------------------------------

  function run(msg, matches)
    if matches[1] == 'setkey' then
      local plugin_found = true
      for k,v in pairs(scandir('plugins')) do
        if (v:match(matches[2])) then
          _config.key[matches[2]] = matches[3]
          save_config()
          reply_msg(msg.id, matches[2] .. ' api key has been saved.', ok_cb, true)
          plugin_found = true
        end
      end
      if not plugin_found then
        reply_msg(msg.id, 'Failed to set ' .. matches[2] .. ' key.\n'
            .. matches[2] .. '.lua doesn\'t exist.', ok_cb, true)
      end
    end
    if matches[1] == 'settoken' then
      api.token = matches[2]
      local botid = api.getMe().result
      _config.api.token = matches[2]
      _config.api.id = botid.id
      _config.api.first_name = botid.first_name
      _config.api.username = botid.username
      save_config()
      reply_msg(msg.id, 'API bots token has been saved.', ok_cb, true)
    end
    if matches[1] == 'setlang' or matches[1] == 'setlocales' then
      _config.locale = matches[2]
      save_config()
      reply_msg(msg.id, 'Bots language has been set to ' .. matches[2], ok_cb, true)
    end
  end

  --------------------------------------------------------------------------------

  return {
    description = 'Set the credentials.',
    usage = {
      sudo = {

      },
    },
    patterns = {
      '^!(setkey) (%a+) (.*)$',
      '^!(settoken) (.*)$',
      '^!(setlang) (%a+)$',
      '^!(setlocales?) (%a+)$',
    },
    run = run,
    privileged = true,
  }

end