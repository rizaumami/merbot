package.path = package.path .. ';.luarocks/share/lua/5.2/?.lua'
  .. ';.luarocks/share/lua/5.2/?/init.lua'
package.cpath = package.cpath .. ';.luarocks/lib/lua/5.2/?.so'

require('./bot/utils')

local f = assert(io.popen('/usr/bin/git describe --tags', 'r'))
VERSION = assert(f:read('*a'))
f:close()

-- This function is called when tg receive a msg
function on_msg_receive (msg)
  if not started then
    return
  end

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

function ok_cb(extra, success, result)
end

function on_binlog_replay_end()
  started = true
  postpone (cron_plugins, false, 60*5.0)
  -- See plugins/isup.lua as an example for cron

  _config = load_config()

  -- load plugins
  plugins = {}
  load_plugins()
end

function msg_valid(msg)
  -- Don't process outgoing messages
--  if msg.out then
--    print('\27[36mNot valid: msg from us\27[39m')
--    return false
--  end

  -- Before bot was started
  if msg.date < now then
    print('\27[36mNot valid: old msg\27[39m')
    return false
  end

  if msg.unread == 0 then
    print('\27[36mNot valid: readed\27[39m')
    return false
  end

  if not msg.to.peer_id then
    print('\27[36mNot valid: To id not provided\27[39m')
    return false
  end

  if not msg.from.peer_id then
    print('\27[36mNot valid: From id not provided\27[39m')
    return false
  end

  if msg.from.peer_id == tonumber(_config.bot_api.uid) then
    print('\27[36mNot valid: Msg from our companion bot\27[39m')
    return false
  end

--  if msg.from.peer_id == our_id then
--    print('\27[36mNot valid: Msg from our id\27[39m')
--    return false
--  end

  if msg.to.peer_type == 'encr_chat' then
    print('\27[36mNot valid: Encrypted chat\27[39m')
    return false
  end

  if msg.from.peer_id == 777000 then
    print('\27[36mNot valid: Telegram message\27[39m')
    return false
  end

  return true
end

local function process_api_msg(msg)
  if not is_chat_msg(msg) and msg.from.peer_id == _config.bot_api.uid then
    local loadapimsg = loadstring(msg.text)
    local apimsg = loadapimsg().message
    local target = tostring(apimsg.chat.id):gsub('-', '')

    if apimsg.chat.type == 'supergroup' or apimsg.chat.type == 'channel' then
      target = tostring(apimsg.chat.id):gsub('-100', '')
    end

    if not _config.administration[tonumber(target)] or apimsg.chat.type == 'supergroup' then
      msg.from.api = true
      msg.from.first_name = apimsg.from.first_name
      msg.from.peer_id = apimsg.from.id
      msg.from.username = apimsg.from.username
      msg.to.peer_id = apimsg.chat.id
      msg.to.peer_type = apimsg.chat.type
      msg.id = apimsg.message_id
      msg.text = apimsg.text

      if apimsg.chat.type == 'group' or apimsg.chat.type == 'supergroup' or apimsg.chat.type == 'channel' then
        msg.to.title = apimsg.chat.title
        msg.to.username = apimsg.chat.username
      end

      if apimsg.chat.type == 'private' then
        msg.to.first_name = apimsg.chat.first_name
        msg.to.username = apimsg.chat.username
      end

      if apimsg.reply_to_message then
        msg.reply_to_message = apimsg.reply_to_message
      end

      if apimsg.new_chat_title then
        msg.action = { title = apimsg.new_chat_title, type = 'chat_rename' }
      end

      if apimsg.new_chat_participant then
        msg.action.type = 'chat_add_user'
        msg.action.user.first_name = apimsg.new_chat_participant.first_name
        msg.action.user.peer_id = apimsg.new_chat_participant.id
        msg.action.user.username = apimsg.new_chat_participant.username
      end

      if apimsg.left_chat_participant then
        msg.action.type = 'chat_del_user'
        msg.action.user.first_name = apimsg.new_chat_participant.first_name
        msg.action.user.peer_id = apimsg.new_chat_participant.id
        msg.action.user.username = apimsg.new_chat_participant.username
      end

      if apimsg.new_chat_photo then
        msg.action.type = 'chat_change_photo'
      end

      if apimsg.delete_chat_photo then
        msg.action.type = 'chat_delete_photo'
      end

      -- if apimsg.group_chat_created then
      --   msg.action = { title = apimsg.group_chat_created, type = 'chat_created' }
      -- end
      -- if apimsg.supergroup_chat_created    then
      --   msg.action = { title = apimsg.supergroup_chat_created   , type = '' }
      -- end
      -- if apimsg.channel_chat_created then
      --   msg.action = { title = apimsg.channel_chat_created, type = '' }
      -- end
      -- if apimsg.migrate_to_chat_id then
      --   msg.action = { title = apimsg.migrate_to_chat_id, type = '' }
      -- end
      -- if apimsg.migrate_from_chat_id then
      --   msg.action = { title = apimsg.migrate_from_chat_id, type = 'migrated_from' }
      -- end
    end
  end
  return msg
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

  -- if is_chat_msg(msg) then
  --   msg.is_processed_by_tgcli = true
  -- end

  -- if not msg.is_processed_by_tgcli then
  --   msg = process_api_msg(msg)
  -- end

  local msg = process_api_msg(msg)

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

-- Go over enabled plugins patterns.
function match_plugins(msg)
  for name, plugin in pairs(plugins) do
    match_plugin(plugin, name, msg)
  end
end

-- Check if plugin is on _config.disabled_plugin_on_chat table
local function is_plugin_disabled_on_chat(plugin_name, receiver)
  local disabled_chats = _config.disabled_plugin_on_chat
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

function match_plugin(plugin, plugin_name, msg)
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

-- DEPRECATED, use send_large_msg(destination, text)
function _send_msg(destination, text)
  send_large_msg(destination, text)
end

-- Create a basic config.lua file and saves it.
function create_config()
  print('\n\27[1;33m Some functions and plugins using bot API as sender.\n'
      .. ' Please provide bots API token to ensure it\'s works as intended.\n'
      .. ' You can ENTER to skip and then fill the required info into data/config.lua.\27[0;39;49m\n')

  io.write('\27[1m Input your bot API key (token) here: \27[0;39;49m')

  local bot_api_key = io.read()
  local response = {}

  local botid = api_getme(bot_api_key)

  -- A simple config with basic plugins and ourselves as privileged user
  _config = {
    administration = {},
    administrators = {},
    api_key = {
      bing_url = 'https://datamarket.azure.com/dataset/bing/search',
      bing = '',
      forecast_url = 'https://developer.forecast.io/',
      forecast = '',
      globalquran_url = 'http://globalquran.com/contribute/signup.php',
      globalquran = '',
      muslimsalat_url = 'http://muslimsalat.com/panel/signup.php',
      muslimsalat = '',
      nasa_api_url = 'http://api.nasa.gov',
      nasa_api = '',
      thecatapi_url = 'http://thecatapi.com/docs.html',
      thecatapi = '',
      yandex_url = 'http://tech.yandex.com/keys/get',
      yandex = '',
    },
    autoleave = false,
    bot_api = {
      key = bot_api_key,
      master = our_id,
      uid = botid.id,
      uname = botid.username
    },
    disabled_channels = {},
    disabled_plugin_on_chat = {},
    enabled_plugins = {
      '9gag',
      'administration',
      'bing',
      'calculator',
      'cats',
      'currency',
      'dilbert',
      'dogify',
      'forecast',
      'gmaps',
      'hackernews',
      'help',
      'id',
      'imdb',
      'isup',
      'patterns',
      'plugins',
      'reddit',
      'rss',
      'salat',
      'stats',
      'sudo',
      'time',
      'urbandictionary',
      'webshot',
      'whois',
      'xkcd',
    },
    globally_banned = {},
    mkgroup = {founded = '', founder = '', title = '', gtype = '', uid = ''},
    realm = {},
    sudo_users = {[our_id] = our_id}
  }
  save_config()
end

-- Save the content of _config to config.lua
function save_config()
  serialize_to_file(_config, './data/config.lua')
  print ('Saved config into ./data/config.lua')
end

-- Returns the config from config.lua file.
-- If file doesn't exist, create it.
function load_config()
  local exist = os.execute('test -s .telegram-cli/auth')
  if not exist then
    print('\n\27[1;33m You are not logged in.\n'
       .. ' Please log your bot in first, then restart merbot.\27[0;39;49m\n')
    return
  end
  local f = io.open('./data/config.lua', 'r')
  -- If config.lua doesn't exist
  if not f then
    print ('Created new config file: data/config.lua')
    create_config()
    print('\27[1;33m \n'
      .. ' Required datas has been saved to ./data/config.lua.\n'
      .. ' Please run bot-api.lua in another tmux/multiplexer window.\27[0;39;49m\n')
  else
    f:close()
  end
  local config = loadfile('./data/config.lua')()
  for v,user in pairs(config.sudo_users) do
    print('Allowed user: ' .. user)
  end
  return config
end

function on_our_id (id)
  our_id = id
end

function on_user_update (user, what)
  --vardump (user)
end

function on_chat_update (chat, what)
  --vardump(chat)
end

function on_secret_chat_update (schat, what)
  --vardump(schat)
end

function on_get_difference_end ()
end

-- Enable plugins in config.json
function load_plugins()
  if _config then
    for k, v in pairs(_config.enabled_plugins) do
      print('Loading plugin', v)

      local ok, err =  pcall(function()
        plug = loadfile('plugins/' .. v .. '.lua')()
        plugins[v] = plug
      end)

      if not ok then
        print('\27[31mError loading plugin ' .. v .. '\27[39m')
        print('\27[31m' .. err .. '\27[39m')
      else
        if plug.is_need_api_key then
          local keyname = _config.api_key[plug.is_need_api_key[1]]
          if not keyname or keyname == '' then
            table.remove(_config.enabled_plugins, k)
            save_config()
        		print('\27[33mMissing ' .. v .. ' api key\27[39m')
        		print('\27[33m' .. v .. '.lua will not be enabled.\27[39m')
        	end
        end
      end
    end
  end
end

function load_data(filename)
  if not filename then
    _groups_data = {}
  else
    _groups_data = loadfile(filename)()
  end
  return _groups_data
end

function save_data(data, file)
  file = io.open(file, 'w+')
  local serialized = serpent.block(data, {comment = false, name = '_'})
  file:write(serialized)
  file:close()
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
  postpone (cron_plugins, false, 5*60.0)
end

-- Start and load values
our_id = 0
now = os.time()
math.randomseed(now)
started = false
