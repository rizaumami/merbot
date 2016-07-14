URL = require "socket.url"
http = require "socket.http"
https = require "ssl.https"
ltn12 = require "ltn12"
serpent = require "serpent"
feedparser = require "feedparser"
multipart = require 'multipart-post'

json = (loadfile "./libs/JSON.lua")()
mimetype = (loadfile "./libs/mimetype.lua")()
redis = (loadfile "./libs/redis.lua")()

http.TIMEOUT = 10
tgclie = './tg/bin/telegram-cli -k ./tg/tg-server-pub -c ./data/tg-cli.config -p default -De %q'

function get_receiver(msg)
  if msg.to.peer_type == 'user' then
    return 'user#id' .. msg.from.peer_id
  end
  if msg.to.peer_type == 'chat' then
    return 'chat#id' .. msg.to.peer_id
  end
  if msg.to.peer_type == 'encr_chat' then
    return msg.to.print_name
  end
  if msg.to.peer_type == 'channel' then
    return 'channel#id' .. msg.to.peer_id
  end
end

function get_receiver_api(msg)
  if msg.to.peer_type == 'user' or msg.to.peer_type == 'private'  then
    return msg.from.peer_id
  end
  if msg.to.peer_type == 'chat' or msg.to.peer_type == 'group' then
    if not msg.from.api then
      return '-' .. msg.to.peer_id
    else
      return msg.to.peer_id
    end
  end
--TODO testing needed
-- if msg.to.peer_type == 'encr_chat' then
--   return msg.to.print_name
-- end
  if msg.to.peer_type == 'channel' or msg.to.peer_type == 'supergroup' then
    if not msg.from.api then
      return '-100' .. msg.to.peer_id
    else
      return msg.to.peer_id
    end
  end
end

function is_chat_msg(msg)
  if msg.to.peer_type == 'private' or msg.to.peer_type == 'user' then
    return false
  else
    return true
  end
end

function is_realm(msg)
  if msg.to.peer_id == _config.realm.gid then
    return true
  else
    return false
  end
end

function string.random(length)
  local str = '';
  for i = 1, length do
    math.random(97, 122)
    str = str .. string.char(math.random(97, 122));
  end
  return str;
end

function string:split(sep)
  local sep, fields = sep or ':', {}
  local pattern = string.format("([^%s]+)", sep)
  self:gsub(pattern, function(c) fields[#fields+1] = c end)
  return fields
end

-- Removes spaces
function string:trim()
  return self:gsub("^%s*(.-)%s*$", "%1")
end

function get_http_file_name(url, headers)
  -- Eg: foo.var
  local file_name = url:match("[^%w]+([%.%w]+)$")
  -- Any delimited alphanumeric on the url
  file_name = file_name or url:match("[^%w]+(%w+)[^%w]+$")
  -- Random name, hope content-type works
  file_name = file_name or str:random(5)

  local content_type = headers['content-type']

  local extension = nil
  if content_type then
    extension = mimetype.get_mime_extension(content_type)
  end
  if extension then
    file_name = file_name .. '.' .. extension
  end

  local disposition = headers['content-disposition']
  if disposition then
    -- attachment; filename=CodeCogsEqn.png
    file_name = disposition:match('filename=([^;]+)') or file_name
  end

  return file_name
end

-- Saves file to /tmp/.
-- If file_name isn't provided, will get the text after the last "/" for
-- filename and content-type for extension
function download_to_file(url, file_name)
  print('url to download: ' .. url)

  local respbody = {}
  local options = {
    url = url,
    sink = ltn12.sink.table(respbody),
    redirect = true
  }

  -- nil, code, headers, status
  local response = nil

  if url:starts('https') then
    options.redirect = false
    response = {https.request(options)}
  else
    response = {http.request(options)}
  end

  local code = response[2]
  local headers = response[3]
  local status = response[4]

  if code ~= 200 then return nil end

  file_name = file_name or get_http_file_name(url, headers)

  local file_path = '/tmp/' .. file_name
  print('Saved to: ' .. file_path)

  file = io.open(file_path, "w+")
  file:write(table.concat(respbody))
  file:close()

  return file_path
end

function vardump(value)
  print(serpent.block(value, {comment=false}))
end

-- http://stackoverflow.com/a/11130774/3163199
function scandir(directory)
  local i, t, popen = 0, {}, io.popen
  for filename in popen('ls -a "' .. directory .. '"'):lines() do
    i = i + 1
    t[i] = filename
  end
  return t
end

-- http://www.lua.org/manual/5.2/manual.html#pdf-io.popen
function run_command(str)
  local cmd = io.popen(str)
  local result = cmd:read('*all')
  cmd:close()
  return result
end

function is_administrate(msg, gid)
  local var = true
  if not _config.administration[gid] then
    var = false
    send_message(msg, '<b>I do not administrate this group</b>', 'html')
  end
  return var
end

-- User has privileges
function is_sudo(user_id)
  local var = false
  if _config.sudo_users[user_id] then
    var = true
  end
  return var
end

-- User is a global administrator
function is_admin(user_id)
  local var = false
  if _config.administrators[user_id] then
    var = true
  end
  if _config.sudo_users[user_id] then
    var = true
  end
  return var
end

-- User is a group owner
function is_owner(msg, chat_id, user_id)
  local var = false
  local data = load_data(_config.administration[chat_id])
  if data.owners == nil then
    var = false
  elseif data.owners[user_id] then
    var = true
  end
  if _config.administrators[user_id] then
    var = true
  end
  if _config.sudo_users[user_id] then
    var = true
  end
  return var
end

-- User is a group moderator
function is_mod(msg, chat_id, user_id)
  local var = false
  local data = load_data(_config.administration[chat_id])
  if data.moderators == nil then
    var = false
  elseif data.moderators[user_id] then
    var = true
  end
  if data.owners == nil then
    var = false
  elseif data.owners[user_id] then
    var = true
  end
  if _config.administrators[user_id] then
    var = true
  end
  if _config.sudo_users[user_id] then
    var = true
  end
  return var
end

-- Returns bot api properties (as getMe method)
function api_getme(bot_api_key)
  local response = {}
  local getme  = https.request{
    url = 'https://api.telegram.org/bot' .. bot_api_key .. '/getMe',
    method = "POST",
    sink = ltn12.sink.table(response),
  }
  local body = table.concat(response or {"no response"})
  local jbody = json:decode(body)

  if jbody.ok then
    botid = jbody.result
  else
    print('Error: ' .. jbody.error_code .. ', ' .. jbody.description)
    botid = {id = '', username = ''}
  end

  return botid
end

-- Returns the name of the sender
function get_name(msg)
  local name = msg.from.first_name
  if name == nil then
    name = msg.from.peer_id
  end
  return name
end

-- Returns at table of lua files inside plugins
function plugins_names()
  local files = {}
  for k, v in pairs(scandir('plugins')) do
    -- Ends with .lua
    if (v:match(".lua$")) then
      table.insert(files, v)
    end
  end
  return files
end

-- Function name explains what it does.
function file_exists(name)
  local f = io.open(name,'r')
  if f ~= nil then
    io.close(f)
    return true
  else
    return false
  end
end

-- Save into file the data serialized for lua.
-- Set uglify true to minify the file.
function serialize_to_file(data, file, uglify)
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

-- Returns true if the string is empty
function string:isempty()
  return self == nil or self == ''
end

-- Returns true if the string is blank
function string:isblank()
  self = self:trim()
  return self:isempty()
end

-- Returns true if String starts with Start
function string:starts(text)
  return text == self:sub(1, string.len(text))
end

-- which bot messages sent by
function send_message(msg, text, markdown)
  if msg.from.api then
    if msg.reply_to_message then
      msg.id = msg.reply_to_message
    end
    bot_sendMessage(get_receiver_api(msg), text, true, msg.id, markdown)
  else
    if msg.reply_id then
      msg.id = msg.reply_id
    end
    -- this will strip all html tags
    local text = text:gsub('<.->', '')
    reply_msg(msg.id, text, ok_cb, true)
  end
end

-- Send image to user and delete it when finished.
-- cb_function and cb_extra are optionals callback
function _send_photo(receiver, file_path, cb_function, cb_extra)
  local cb_extra = {
    file_path = file_path,
    cb_function = cb_function,
    cb_extra = cb_extra
  }
  -- Call to remove with optional callback
  send_photo(receiver, file_path, cb_function, cb_extra)
end

-- Download the image and send to receiver, it will be deleted.
-- cb_function and cb_extra are optionals callback
function send_photo_from_url(receiver, url, cb_function, cb_extra)
  -- If callback not provided
  cb_function = cb_function or ok_cb
  cb_extra = cb_extra or false

  local file_path = download_to_file(url, false)
  if not file_path then -- Error
    local text = 'Error downloading the image'
    send_msg(receiver, text, cb_function, cb_extra)
  else
    print('File path: ' .. file_path)
    _send_photo(receiver, file_path, cb_function, cb_extra)
  end
end

-- Same as send_photo_from_url but as callback function
function send_photo_from_url_callback(cb_extra, success, result)
  local receiver = cb_extra.receiver
  local url = cb_extra.url

  local file_path = download_to_file(url, false)
  if not file_path then -- Error
    local text = 'Error downloading the image'
    send_msg(receiver, text, ok_cb, false)
  else
    print('File path: ' .. file_path)
    _send_photo(receiver, file_path, ok_cb, false)
  end
end

-- Send multiple images asynchronous.
-- param urls must be a table.
function send_photos_from_url(receiver, urls)
  local cb_extra = {
    receiver = receiver,
    urls = urls,
    remove_path = nil
  }
  send_photos_from_url_callback(cb_extra)
end

-- Use send_photos_from_url.
-- This function might be difficult to understand.
function send_photos_from_url_callback(cb_extra, success, result)
  -- cb_extra is a table containing receiver, urls and remove_path
  local receiver = cb_extra.receiver
  local urls = cb_extra.urls
  local remove_path = cb_extra.remove_path

  -- The previously image to remove
  if remove_path ~= nil then
    os.remove(remove_path)
    print('Deleted: ' .. remove_path)
  end

  -- Nil or empty, exit case (no more urls)
  if urls == nil or #urls == 0 then
    return false
  end

  -- Take the head and remove from urls table
  local head = table.remove(urls, 1)

  local file_path = download_to_file(head, false)
  local cb_extra = {
    receiver = receiver,
    urls = urls,
    remove_path = file_path
  }

  -- Send first and postpone the others as callback
  send_photo(receiver, file_path, send_photos_from_url_callback, cb_extra)
end

-- Callback to remove a file
function rmtmp_cb(cb_extra, success, result)
  local file_path = cb_extra.file_path
  local cb_function = cb_extra.cb_function or ok_cb
  local cb_extra = cb_extra.cb_extra

  if file_path ~= nil then
    os.remove(file_path)
    print('Deleted: ' .. file_path)
  end
  -- Finally call the callback
  cb_function(cb_extra, success, result)
end

-- Send document to user and delete it when finished.
-- cb_function and cb_extra are optionals callback
function _send_document(receiver, file_path, cb_function, cb_extra)
  local cb_extra = {
    file_path = file_path,
    cb_function = cb_function or ok_cb,
    cb_extra = cb_extra or false
  }
  -- Call to remove with optional callback
  send_document(receiver, file_path, rmtmp_cb, cb_extra)
end

-- Download the image and send to receiver, it will be deleted.
-- cb_function and cb_extra are optionals callback
function send_document_from_url(receiver, url, cb_function, cb_extra)
  local file_path = download_to_file(url, false)
  print('File path: ' .. file_path)
  _send_document(receiver, file_path, cb_function, cb_extra)
end

-- Parameters in ?a=1&b=2 style
function format_http_params(params, is_get)
  local str = ''
  -- If is get add ? to the beginning
  if is_get then str = '?' end
  local first = true -- Frist param
  for k,v in pairs (params) do
    if v then -- nil value
      if first then
        first = false
        str = str .. k .. '=' .. v
      else
        str = str .. '&' .. k .. '=' .. v
      end
    end
  end
  return str
end

-- Check if user can use the plugin and warns user
-- Returns true if user was warned and false if not warned (is allowed)
function warns_user_not_allowed(plugin, msg)
  if not user_allowed(plugin, msg) then
    local text = 'This plugin requires privileged user'
    reply_msg(msg.id, text, ok_cb, true)
    return true
  else
    return false
  end
end

-- Check if user can use the plugin
function user_allowed(plugin, msg)
  if plugin.moderated and not is_mod(msg, msg.to.peer_id, msg.from.peer_id) then
    if plugin.moderated and not is_owner(msg, msg.to.peer_id, msg.from.peer_id) then
      if plugin.moderated and not is_admin(msg.from.peer_id) then
        if plugin.moderated and not is_sudo(msg.from.peer_id) then
          return false
        end
      end
    end
  end
  -- If plugins privileged = true
  if plugin.privileged and not is_sudo(msg.from.peer_id) then
    return false
  end
  return true
end

function send_order_msg(destination, msgs)
  local cb_extra = {
    destination = destination,
    msgs = msgs
  }
  send_order_msg_callback(cb_extra, true)
end

function send_order_msg_callback(cb_extra, success, result)
  local destination = cb_extra.destination
  local msgs = cb_extra.msgs
  local file_path = cb_extra.file_path
  if file_path ~= nil then
    os.remove(file_path)
    print('Deleted: ' .. file_path)
  end
  if type(msgs) == 'string' then
    send_large_msg(destination, msgs)
  elseif type(msgs) ~= 'table' then
    return
  end
  if #msgs < 1 then
    return
  end
  local msg = table.remove(msgs, 1)
  local new_cb_extra = {
    destination = destination,
    msgs = msgs
  }
  if type(msg) == 'string' then
    send_msg(destination, msg, send_order_msg_callback, new_cb_extra)
  elseif type(msg) == 'table' then
    local typ = msg[1]
    local nmsg = msg[2]
    new_cb_extra.file_path = nmsg
    if typ == 'document' then
      send_document(destination, nmsg, send_order_msg_callback, new_cb_extra)
    elseif typ == 'image' or typ == 'photo' then
      send_photo(destination, nmsg, send_order_msg_callback, new_cb_extra)
    elseif typ == 'audio' then
      send_audio(destination, nmsg, send_order_msg_callback, new_cb_extra)
    elseif typ == 'video' then
      send_video(destination, nmsg, send_order_msg_callback, new_cb_extra)
    else
      send_file(destination, nmsg, send_order_msg_callback, new_cb_extra)
    end
  end
end

-- Same as send_large_msg_callback but friendly params
function send_large_msg(destination, text)
  local cb_extra = {
    destination = destination,
    text = text
  }
  send_large_msg_callback(cb_extra, true)
end

-- If text is longer than 4096 chars, send multiple msg.
-- https://core.telegram.org/method/messages.sendMessage
function send_large_msg_callback(cb_extra, success, result)
  local text_max = 4096

  local destination = cb_extra.destination
  local text = cb_extra.text
  local text_len = string.len(text)
  local num_msg = math.ceil(text_len / text_max)

  if num_msg <= 1 then
    send_msg(destination, text, ok_cb, false)
  else

    local my_text = text:sub(1, 4096)
    local rest = text:sub(4096, text_len)

    local cb_extra = {
      destination = destination,
      text = rest
    }

    send_msg(destination, my_text, send_large_msg_callback, cb_extra)
  end
end

-- Returns a table with matches or nil
function match_pattern(pattern, text, lower_case)
  if text then
    local matches = {}
    if lower_case then
      matches = { string.match(text:lower(), pattern) }
    else
      matches = { string.match(text, pattern) }
    end
      if next(matches) then
        return matches
      end
  end
  -- nil
end

-- Function to read data from files
function load_from_file(file, default_data)
  local f = io.open(file, 'r+')
  -- If file doesn't exists
  if f == nil then
    -- Create a new empty table
    default_data = default_data or {}
    serialize_to_file(default_data, file)
    print ('Created file', file)
  else
    print ('Data loaded from file', file)
    f:close()
  end
  return loadfile (file)()
end

-- See http://stackoverflow.com/a/14899740
function unescape_html(str)
  local map = {
    ["lt"]  = "<",
    ["gt"]  = ">",
    ["amp"] = "&",
    ["quot"] = '"',
    ["apos"] = "'"
  }
  new = str:gsub('(&(#?x?)([%d%a]+);)', function(orig, n, s)
    var = map[s] or n == "#" and string.char(s)
    var = var or n == "#x" and string.char(tonumber(s,16))
    var = var or orig
    return var
  end)
  return new
end

function markdown_escape(text)
  text = text:gsub('_', '\\_')
  text = text:gsub('%[', '\\[')
  text = text:gsub('%]', '\\]')
  text = text:gsub('%*', '\\*')
  text = text:gsub('`', '\\`')
  return text
end

function pairsByKeys(t, f)
  local a = {}
  for n in pairs(t) do
    a[#a+1] = n
  end
  table.sort(a, f)
  local i = 0      -- iterator variable
  local iter = function ()   -- iterator function
    i = i + 1
    if a[i] == nil then
      return nil
    else
      return a[i], t[a[i]]
    end
  end
  return iter
end

-- Gets coordinates for a location.
function get_coords(msg, input)
  local url = 'https://maps.googleapis.com/maps/api/geocode/json?address=' .. URL.escape(input)

  local jstr, res = http.request(url)
  if res ~= 200 then
    reply_msg(msg.id, 'Connection error.', ok_cb, true)
    return
  end

  local jdat = json:decode(jstr)
  if jdat.status == 'ZERO_RESULTS' then
    reply_msg(msg.id, 'ZERO_RESULTS', ok_cb, true)
    return
  end

  return {
    lat = jdat.results[1].geometry.location.lat,
    lon = jdat.results[1].geometry.location.lng,
    formatted_address = jdat.results[1].formatted_address
  }
end

-- Text formatting is server side. And (until now) only for API bots.
-- So, here is a simple workaround; send message through Telegram official API.
-- You need to provide your API bots TOKEN in config.lua.
local function bot(method, parameters, file)
  local parameters = parameters or {}
  for k,v in pairs(parameters) do
    parameters[k] = tostring(v)
  end
  if file and next(file) ~= nil then
    local file_type, file_name = next(file)
    local file_file = io.open(file_name, 'r')
    local file_data = {
      filename = file_name,
      data = file_file:read('*a')
    }
    file_file:close()
    parameters[file_type] = file_data
  end
  if next(parameters) == nil then
    parameters = {''}
  end

  if parameters.reply_to_message_id and #parameters.reply_to_message_id > 30 then
    parameters.reply_to_message_id = nil
  end

  local response = {}
  local body, boundary = multipart.encode(parameters)
  local success = https.request{
    url = 'https://api.telegram.org/bot' .. _config.bot_api.key .. '/' .. method,
    method = 'POST',
    headers = {
      ["Content-Type"] =  "multipart/form-data; boundary=" .. boundary,
      ["Content-Length"] = #body,
    },
    source = ltn12.source.string(body),
    sink = ltn12.sink.table(response)
  }
  local data = table.concat(response)
  local jdata = json:decode(data)
  if not jdata.ok then
    vardump(jdata)
  end
end

function bot_sendMessage(chat_id, text, disable_web_page_preview, reply_to_message_id, parse_mode)
  return bot('sendMessage', {
    chat_id = chat_id,
    text = text,
    disable_web_page_preview = disable_web_page_preview,
    reply_to_message_id = reply_to_message_id,
    parse_mode = parse_mode or nil
  } )
end

function bot_sendPhoto(chat_id, photo, caption, disable_notification, reply_to_message_id)
  return bot('sendPhoto', {
    chat_id = chat_id,
    caption = caption,
    disable_notification = disable_notification,
    reply_to_message_id = reply_to_message_id,
  }, {photo = photo} )
end

function bot_sendLocation(chat_id, latitude, longitude, disable_notification, reply_to_message_id)
  return bot('sendLocation', {
    chat_id = chat_id,
    latitude = latitude,
    longitude = longitude,
    disable_notification = disable_notification,
    reply_to_message_id = reply_to_message_id,
  })
end

function bot_sendDocument(chat_id, document, caption, disable_notification, reply_to_message_id)
  return bot('sendDocument', {
    chat_id = chat_id,
    document = document,
    caption = caption,
    disable_notification = disable_notification,
    reply_to_message_id = reply_to_message_id,
  }, {document = document})
end
