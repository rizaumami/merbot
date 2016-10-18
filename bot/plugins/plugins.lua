do

  local function get_plugins_table(plugins_type)
    if plugins_type == 'sudo' then
      plugins_table = _config.plugins.sudo
    elseif plugins_type == 'user' then
      plugins_table = _config.plugins.user
    end
    return plugins_table
  end

  -- Returns the key (index) in the config.enabled_plugins table
  local function plugin_enabled(name, plugins_type)
    for k,v in pairs(get_plugins_table(plugins_type)) do
      if name == v then
        return k
      end
    end
    -- If not found
    return false
  end

  -- Returns at table of lua files inside plugins
  local function plugins_names(path)
    local files = {}
    for k, v in pairs(scandir(path)) do
      -- Ends with .lua
      if (v:match(".lua$")) then
        table.insert(files, v)
      end
    end
    return files
  end

  -- Returns true if file exists in plugins folder
  local function plugin_exists(name, plugins_dir)
    for k,v in pairs(plugins_names(plugins_dir)) do
      if name .. '.lua' == v then
        return true
      end
    end
    return false
  end

  local function list_plugins(msg, only_enabled, plugins_type)
    local text = ''
    local psum = 0
    for k, v in pairs(plugins_names(plugins_dir)) do
      --  ✅ enabled, ❌ disabled
      local status = '❌'
      psum = psum+1
      pact = 0
      -- Check if is enabled
      for k2, v2 in pairs(get_plugins_table(plugins_type)) do
        if v == v2 .. '.lua' then
          status = '✅'
        end
        pact = pact+1
      end
      if not only_enabled or status == '✅' then
        -- get the name
        v = v:match('(.*)%.lua')
        text = text .. status .. '  ' .. v .. '\n'
      end
    end

    local text = text .. '\n' .. psum .. '  plugins installed.\n'
        .. '✅  ' .. pact .. ' enabled.\n❌  ' .. psum-pact .. ' disabled.'

    reply_msg(msg.id, text, ok_cb, true)
  end

  local function reload_plugins(msg, only_enabled, plugins_type)
    plugins = {}
    load_plugins()
    return list_plugins(msg, true, plugins_type)
  end

--------------------------------------------------------------------------------

  local function run(msg, matches)
    local plugin = matches[2]
    local receiver = get_receiver(msg)

    if msg.text:match('sysplug') then
      plugins_type = 'sudo'
      plugins_dir = 'bot/plugins/'
    else
      plugins_type = 'user'
      plugins_dir = 'plugins/'
    end

    if is_sudo(msg.from.peer_id) then
      -- Show the available system/admin plugins
      if matches[1] == '!sysplugs' then
        return list_plugins(msg, false, 'sudo')
      end

      -- Enable a plugin
      if not matches[3] then
        if matches[1] == 'enable' then
          print('enable: ' .. plugin)
          print('checking if ' .. plugin .. ' exists')

          -- Check if plugin is enabled
          if plugin_enabled(plugin, plugins_type) then
            reply_msg(msg.id, 'Plugin ' .. plugin .. ' is enabled', ok_cb, true)
          end

          -- Checks if plugin exists
          if plugin_exists(plugin, plugins_dir) then

            -- Ckeck if plugin is need a key
            local plug = loadfile(plugins_dir .. plugin .. '.lua')()
            if plug.need_api_key then
              local keyname = _config.key[plugin]
              if not keyname or keyname == '' then
                reply_msg(msg.id, plugin .. '.lua is missing its api key.\n'
                    .. 'Will not be enabled.\n\n'
                    .. 'Set ' .. plugin .. ' key using these command:\n'
                    .. '!setkey ' .. plugin .. ' <the_key>', ok_cb, false)
                return
              end
            end
            -- Add to the config table
            table.insert(get_plugins_table(plugins_type), plugin)
            print(plugin .. ' added to _config table')
            save_config()
            -- Reload the plugins
            return reload_plugins(msg, false, plugins_type)
          else
            reply_msg(msg.id, 'Plugin ' .. plugin .. ' does not exists', ok_cb, true)
          end
        end

        -- Disable a plugin
        if matches[1] == 'disable' then
          print('disable: ' .. plugin)

          -- Check if plugins exists
          if not plugin_exists(plugin, plugins_dir) then
            reply_msg(msg.id, 'Plugin ' .. plugin .. ' does not exists', ok_cb, true)
          end

          local k = plugin_enabled(plugin, plugins_type)
          -- Check if plugin is enabled
          if not k then
            reply_msg(msg.id, 'Plugin ' .. plugin .. ' not enabled', ok_cb, true)
          end

          -- Disable and reload
          table.remove(get_plugins_table(plugins_type), k)
          save_config()
          return reload_plugins(msg, true, plugins_type)
        end
      end

      -- Reload all the plugins!
      if matches[1] == 'reload' then
        return reload_plugins(msg, false, plugins_type)
      end
    end

    if is_mod(msg, msg.to.peer_id, msg.from.peer_id) then
      -- Show the available plugins
      if matches[1] == '!plugins' then
        return list_plugins(msg, false, 'user')
      end

      -- Re-enable a plugin for this chat
      if matches[3] == 'chat' then
        if matches[1] == 'enable' then
          print('enable ' .. plugin .. ' on this chat')
          if not _config.plugins.disabled_on_chat then
            reply_msg(msg.id, "There aren't any disabled plugins", ok_cb, true)
          end

          if not _config.plugins.disabled_on_chat[receiver] then
            reply_msg(msg.id, "There aren't any disabled plugins for this chat", ok_cb, true)
          end

          if not _config.plugins.disabled_on_chat[receiver][plugin] then
            reply_msg(msg.id, 'This plugin is not disabled', ok_cb, true)
          end

          _config.plugins.disabled_on_chat[receiver][plugin] = false
          save_config()
          reply_msg(msg.id, 'Plugin ' .. plugin .. ' is enabled again', ok_cb, true)
        end

        -- Disable a plugin on a chat
        if matches[1] == 'disable' then
          print('disable ' .. plugin .. ' on this chat')
          if not plugin_exists(plugin, plugins_dir) then
            reply_msg(msg.id, "Plugin doesn't exists", ok_cb, true)
          end

          if not _config.plugins.disabled_on_chat then
            _config.plugins.disabled_on_chat = {}
          end

          if not _config.plugins.disabled_on_chat[receiver] then
            _config.plugins.disabled_on_chat[receiver] = {}
          end

          _config.plugins.disabled_on_chat[receiver][plugin] = true
          save_config()
          reply_msg(msg.id, 'Plugin ' .. plugin .. ' disabled on this chat', ok_cb, true)
        end
      end
    end
  end

--------------------------------------------------------------------------------

  return {
    description = 'Plugin to manage other plugins. Enable, disable or reload.',
    usage = {
      sudo = {
        '<code>!plugins enable [plugin]</code>',
        'Enable plugin.',
        '',
        '<code>!plugins disable [plugin]</code>',
        'Disable plugin.',
        '',
        '<code>!plugins reload</code>',
        'Reloads all plugins.'
      },
      moderator = {
        '<code>!plugins</code>',
        'List all plugins.',
        '',
        '<code>!plugins enable [plugin] chat</code>',
        'Re-enable plugin only this chat.',
        '',
        '<code>!plugins disable [plugin] chat</code>',
        'Disable plugin only this chat.'
      },
    },
    patterns = {
      '^!plugins$',
      '^!plugins? (enable) ([%w_%.%-]+)$',
      '^!plugins? (disable) ([%w_%.%-]+)$',
      '^!plugins? (enable) ([%w_%.%-]+) (chat)$',
      '^!plugins? (disable) ([%w_%.%-]+) (chat)$',
      '^!plugins? (reload)$',
      '^!sysplugs?$',
      '^!sysplugs? (enable) ([%w_%.%-]+)$',
      '^!sysplugs? (disable) ([%w_%.%-]+)$',
    },
    run = run
  }

end
