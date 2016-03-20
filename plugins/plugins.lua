do

  -- Returns the key (index) in the config.enabled_plugins table
  local function plugin_enabled(name)
    for k,v in pairs(_config.enabled_plugins) do
      if name == v then
        return k
      end
    end
    -- If not found
    return false
  end

  -- Returns true if file exists in plugins folder
  local function plugin_exists(name)
    for k,v in pairs(plugins_names()) do
      if name..'.lua' == v then
        return true
      end
    end
    return false
  end

  local function list_plugins(only_enabled, msg)
    local text = ''
    local psum = 0
    for k, v in pairs(plugins_names()) do
      --  ✅ enabled, ❌ disabled
      local status = '❌'
      psum = psum+1
      pact = 0
      -- Check if is enabled
      for k2, v2 in pairs(_config.enabled_plugins) do
        if v == v2..'.lua' then
          status = '✅'
        end
        pact = pact+1
      end
      if not only_enabled or status == '✅' then
        -- get the name
        v = v:match('(.*)%.lua')
        text = text..status..'  '..v..'\n'
      end
    end
    local text = text..'\n'..psum..'  plugins installed.\n✅  '
                 ..pact..' enabled.\n❌  '..psum-pact..' disabled.'
    reply_msg(msg.id, text, ok_cb, true)
  end

  local function reload_plugins(only_enabled, msg)
    plugins = {}
    load_plugins()
    return list_plugins(true, msg)
  end

--------------------------------------------------------------------------------

  local function run(msg, matches)

    if is_sudo(msg.from.peer_id) then
      -- Enable a plugin
      if matches[1] == 'enable' then
        print('enable: '..matches[2])
        print('checking if '..matches[2]..' exists')
        -- Check if plugin is enabled
        if plugin_enabled(matches[2]) then
          reply_msg(msg.id, 'Plugin '..matches[2]..' is enabled', ok_cb, true)
        end
        -- Checks if plugin exists
        if plugin_exists(matches[2]) then
          -- Add to the config table
          table.insert(_config.enabled_plugins, matches[2])
          print(matches[2]..' added to _config table')
          save_config()
          -- Reload the plugins
          return reload_plugins(false, msg)
        else
          reply_msg(msg.id, 'Plugin '..matches[2]..' does not exists', ok_cb, true)
        end
      -- Disable a plugin
      elseif matches[1] == 'disable' then
        print('disable: '..matches[2])
        -- Check if plugins exists
        if not plugin_exists(matches[2]) then
          reply_msg(msg.id, 'Plugin '..matches[2]..' does not exists', ok_cb, true)
        end
        local k = plugin_enabled(matches[2])
        -- Check if plugin is enabled
        if not k then
          reply_msg(msg.id, 'Plugin '..matches[2]..' not enabled', ok_cb, true)
        end
        -- Disable and reload
        table.remove(_config.enabled_plugins, k)
        save_config( )
        return reload_plugins(true, msg)
      -- Reload all the plugins!
      elseif matches[1] == 'reload' then
        return reload_plugins(true, msg)
      end
    end

    if is_mod(msg, msg.to.peer_id, msg.from.peer_id) then
      -- Show the available plugins
      if matches[1] == '!plugins' then
        return list_plugins(false, msg)
      -- Re-enable a plugin for this chat
      elseif matches[1] == 'enable' and matches[3] == 'chat' then
        print('enable '..matches[2]..' on this chat')
        if not _config.disabled_plugin_on_chat then
          reply_msg(msg.id, 'There aren\'t any disabled plugins for this chat.', ok_cb, true)
        end
        if not _config.disabled_plugin_on_chat[get_receiver(msg)] then
          reply_msg(msg.id, 'There aren\'t any disabled plugins for this chat.', ok_cb, true)
        end
        if not _config.disabled_plugin_on_chat[get_receiver(msg)][matches[2]] then
          reply_msg(msg.id, 'Plugin '..matches[2]..' is not disabled for this chat.', ok_cb, true)
        end
        _config.disabled_plugin_on_chat[get_receiver(msg)][matches[2]] = false
        save_config()
        reply_msg(msg.id, 'Plugin '..matches[2]..' is enabled again for this chat.', ok_cb, true)
      -- Disable a plugin on a chat
      elseif matches[1] == 'disable' and matches[3] == 'chat' then
        print('disable '..matches[2]..' on this chat')
        if not plugin_exists(matches[2]) then
          reply_msg(msg.id, 'Plugin '..matches[2]..' doesn\'t exists', ok_cb, true)
        end
        if not _config.disabled_plugin_on_chat then
          _config.disabled_plugin_on_chat = {}
        end
        if not _config.disabled_plugin_on_chat[get_receiver(msg)] then
          _config.disabled_plugin_on_chat[get_receiver(msg)] = {}
        end
        _config.disabled_plugin_on_chat[get_receiver(msg)][matches[2]] = true
        save_config()
        reply_msg(msg.id, 'Plugin '..matches[2]..' disabled for this chat', ok_cb, true)
      end
    end

  end

--------------------------------------------------------------------------------

  return {
    description = 'Plugin to manage other plugins. Enable, disable or reload.',
    usage = {
      sudo = {
        '<code>!plugins enable [plugin]</code>',
        'enable plugin.',
        '<code>!plugins disable [plugin]</code>',
        'disable plugin.',
        '<code>!plugins reload</code>',
        'reloads all plugins.'
      },
      moderator = {
        '<code>!plugins</code>',
        'list all plugins.',
        '<code>!plugins enable [plugin] chat</code>',
        're-enable plugin only this chat.',
        '<code>!plugins disable [plugin] chat</code>',
        'disable plugin only this chat.'
      },
    },
    patterns = {
      '^!plugins$',
      '^!plugins? (enable) ([%w_%.%-]+)$',
      '^!plugins? (disable) ([%w_%.%-]+)$',
      '^!plugins? (enable) ([%w_%.%-]+) (chat)$',
      '^!plugins? (disable) ([%w_%.%-]+) (chat)$',
      '^!plugins? (reload)$'
    },
    run = run
  }

end
