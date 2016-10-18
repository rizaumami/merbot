package.path = package.path .. ';.luarocks/share/lua/5.2/?.lua'
  .. ';.luarocks/share/lua/5.2/?/init.lua'
package.cpath = package.cpath .. ';.luarocks/lib/lua/5.2/?.so'

require('./bot/utilities')

api = dofile('./bot/api-methods.lua')

local config_file = './data/config.lua'
-- bot version
local f = assert(io.popen('/usr/bin/git describe --tags', 'r'))
VERSION = assert(f:read('*a'))
f:close()

--------------------------------------------------------------------------------

local function prterr(text)
  print('\27[33m' .. text .. '\27[39m')
end

function vardump(value)
  print(serpent.block(value, {comment=false}))
end

function ok_cb(extra, success, result)
end

-- Save into file the data serialized for lua.
-- Set uglify true to minify the file.
function save_data(data, file, uglify)
  file = io.open(file, 'w+')
  local serialized
  if not uglify then
    serialized = serpent.block(data, {
      comment = false,
      name = '_'
    })
  else
    serialized = serpent.dump(data)
  end
  file:write(serialized)
  file:close()
end

function save_config()
  save_data(_config, config_file)
end

function pre_process_service_msg(msg)
  if msg.service then
    local action = msg.action or {type=''}
    -- Double ! to discriminate of normal actions
    msg.text = '!!tgservice ' .. action.type

    -- wipe the data to allow the bot to read service messages
    if msg.out then
      msg.out = false
    end
    if msg.from.peer_id == our_id then
      msg.from.peer_id = 0
    end
  end

  local msg = api.process_msg(msg)

  return msg
end

-- Apply plugin.pre_process function
function pre_process_msg(msg)
  for name,plugin in pairs(plugins) do
    if plugin.pre_process and msg then
      print('Preprocess', name)
      msg = plugin.pre_process(msg)
    end
  end
  return msg
end

function msg_valid(msg)
  -- -- Don't process outgoing messages
  -- if msg.out then
  --   prterr('Not valid: msg from us')
  --   return false
  -- end
  -- Before bot was started
  if msg.date < now then
    prterr('Not valid: old msg')
    return false
  end
  if msg.unread == 0 then
    prterr('Not valid: readed')
    return false
  end
  if not msg.to.peer_id then
    prterr('Not valid: To id not provided')
    return false
  end
  if not msg.from.peer_id then
    prterr('Not valid: From id not provided')
    return false
  end
  if msg.from.peer_id == tonumber(_config.api.id) then
    prterr('Not valid: Msg from our companion bot')
    return false
  end
  -- if msg.from.peer_id == our_id then
  --   prterr('Not valid: Msg from our id')
  --   return false
  -- end
  if msg.to.peer_type == 'encr_chat' then
    prterr('Not valid: Encrypted chat')
    return false
  end
  if msg.from.peer_id == 777000 then
    prterr('Not valid: Telegram message')
    return false
  end

  return true
end

-- Create a basic config.lua file and saves it.
function create_config()
  -- A simple config with basic plugins and ourselves as privileged user
  _config = {
    administrators = {},
    api = {
      master = our_id
    },
    autoleave = false,
    chats = {disabled = {}, managed = {}, realm = {}},
    key = {},
    language = 'en',
    plugins = {
      sudo = {
        'administration',
        'plugins',
        'shell',
        'sudo',
      },
      user = {
        "9gag",
        "btc",
        "calculator",
        "currency",
        "dilbert",
        "dogify",
        "gmaps",
        "help",
        "id",
        "imdb",
        "isup",
        "kaskus",
        "kbbi",
        "patterns",
        "reddit",
        "rss",
        "stats",
        "time",
        "urbandictionary",
        "whois",
        "xkcd",
        "yify",
      },
    },
    sudo_users = {[our_id] = our_id}
  }

  save_data(_config, config_file)
end

function api_getme()
  prterr('\n Some functions and plugins using bot API as sender.\n'
      .. ' Please provide bots API token to ensure it\'s works as intended.\n'
      .. ' You can ENTER to skip and then fill the required info into ' .. config_file .. '\n')

  io.write('\27[1m Input your bot API key (token) here: \27[0;39;49m')

  local config = loadfile(config_file)()
  local bot_api_key = io.read()
  api.token = bot_api_key
  local botid = api.getMe().result
  config.api.token = bot_api_key
  config.api.id = botid.id
  config.api.first_name = botid.first_name
  config.api.username = botid.username

  save_data(config, config_file)
end

-- Returns the config from config.lua file.
-- If file doesn't exist, create it.
function load_config()
  if not file_exists('.telegram-cli/auth') then
    print('\n\27[1;33m You are not logged in.\n'
       .. ' Please log your bot in first, then restart merbot.\27[0;39;49m\n')
    return
  end
  -- If config.lua doesn't exist
  if not file_exists(config_file) then
    print(' Created new config file: ' .. config_file)
    create_config()
    api_getme()
  end

  prterr('\n Please run bot-api.lua in another tmux/multiplexer window.\n')

  local config = loadfile(config_file)()

  if not config.api.token or config.api.token == '' then
    api_getme()
  end

  for v,user in pairs(config.sudo_users) do
    print('Allowed user: ' .. user)
  end

  return config
end

-- Check if plugin is on _config.disabled_plugin_on_chat table
local function is_plugin_disabled_on_chat(plugin_name, receiver)
  local disabled_chats = _config.plugins.disabled_on_chat
  -- Table exists and chat has disabled plugins
  if disabled_chats and disabled_chats[receiver] then
    -- Checks if plugin is disabled on this chat
    for disabled_plugin,disabled in pairs(disabled_chats[receiver]) do
      if disabled_plugin == plugin_name and disabled then
        local warning = 'Plugin ' .. disabled_plugin .. ' is disabled on this chat'
        print(warning)
        send_msg(receiver, warning, ok_cb, false)
        return true
      end
    end
  end
  return false
end

function match_plugin(msg, plugin, plugin_name)
  -- Go over patterns. If one matches it's enough.
  for k, pattern in pairs(plugin.patterns) do
    local matches = match_pattern(pattern, msg.text)
    if matches then
      print('msg matches: ', pattern)

      if is_plugin_disabled_on_chat(plugin_name, get_receiver(msg)) then
        return nil
      end
      -- Function exists
      if plugin.run then
        -- If plugin is for privileged users only
        if not warns_user_not_allowed(plugin, msg) then
          local result = plugin.run(msg, matches)
          if result then
            send_large_msg(get_receiver(msg), result)
          end
        end
      end
      -- One patterns matches
      return
    end
  end
end

-- Go over enabled plugins patterns.
function match_plugins(msg)
  for name, plugin in pairs(plugins) do
    match_plugin(msg, plugin, name)
  end
end

function load_plugins_table(plugins_type)
  local path = 'plugins/'

  if plugins_type == 'sudo' then
    path = 'bot/plugins/'
  end
  if _config then
    for k, v in pairs(_config.plugins[plugins_type]) do
      print('Loading plugin', v)

      local ok, err =  pcall(function()
        plug = loadfile(path .. v .. '.lua')()
        plugins[v] = plug
      end)

      if not ok then
        prterr('Error loading plugin ' .. v .. '\n' .. err)
      else
        if plug.need_api_key then
          local keyname = _config.key[v]
          if not keyname or keyname == '' then
            table.remove(_config.plugins[plugins_type], k)
            save_config()
            prterr(v .. '.lua is missing its api key. Will not be enabled.')
          end
        end
      end
    end
  end
end

function load_plugins()
  load_plugins_table('sudo')
  load_plugins_table('user')
end

function load_data(filename)
  if not filename then
    _data = {}
  else
    _data = loadfile(filename)()
  end
  return _data
end

function file_exists(name)
  local f = io.open(name,'r')
  if f ~= nil then
    io.close(f)
    return true
  else
    return false
  end
end

--------------------------------------------------------------------------------

-- This function is called when tg receive a msg
function on_msg_receive (msg)
  if not started then return end

  vardump(msg)
  msg = pre_process_service_msg(msg)

  if msg_valid(msg) then
    msg = pre_process_msg(msg)
    if msg then
      match_plugins(msg)
      mark_read(get_receiver(msg), ok_cb, false)
    end
  end
end

function on_our_id(id)
  our_id = id
end

function on_user_update(user, what)
  -- vardump(user)
end

function on_chat_update(chat, what)
  -- vardump(chat)
end

function on_secret_chat_update(schat, what)
  -- vardump(schat)
end

function on_get_difference_end()
end

function cron()
  -- do something
  postpone(cron, false, 1.0)
end

-- Call and postpone execution for cron plugins
function cron_plugins()
  for name, plugin in pairs(plugins) do
    -- Only plugins with cron function
    if plugin.cron ~= nil then
      plugin.cron()
    end
  end
  -- Called again in 5 mins
  postpone(cron_plugins, false, 5*60.0)
end

function on_binlog_replay_end ()
  started = true
  postpone(cron, false, 1.0)
  _config = load_config()
  -- load plugins
  plugins = {}
  load_plugins()
end

-- Start and load values
our_id = 0
now = os.time()
math.randomseed(now)
started = false