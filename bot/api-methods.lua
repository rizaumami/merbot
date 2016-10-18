--[[

Partially taken from https://github.com/cosmonawt/lua-telegram-bot
Be carefull, no parameters check.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

]]

local encode = require 'multipart-post'
local C = {}

local function result(response)
  if (response.success == 1) then
    return json:decode(response.body)
  else
    return nil, "Request Error"
  end
end

local function makeRequest(method, request_body)
  local token = api.token or _config.api.token
  local response = {}
  local body, boundary = encode.encode(request_body)

  local success, code, headers, status = https.request{
    url = 'https://api.telegram.org/bot' .. token .. '/' .. method,
    method = 'POST',
    headers = {
      ['Content-Type'] =  'multipart/form-data; boundary=' .. boundary,
      ['Content-Length'] = string.len(body),
    },
    source = ltn12.source.string(body),
    sink = ltn12.sink.table(response),
  }

  local r = {
    success = success or 'false',
    code = code or '0',
    headers = table.concat(headers or {'no headers'}),
    status = status or '0',
    body = table.concat(response or {'no response'}),
  }

  return r
end

local function getMe()
  local response = makeRequest('getMe', {''})
  return result(response)
end

C.getMe = getMe

local function sendMessage(chat_id, text, parse_mode, disable_web_page_preview, disable_notification, reply_to_message_id, reply_markup)
  local response = makeRequest('sendMessage', {
    chat_id = chat_id,
    text = tostring(text),
    parse_mode = parse_mode:lower(),
    disable_web_page_preview = tostring(disable_web_page_preview),
    disable_notification = tostring(disable_notification),
    reply_to_message_id = tonumber(reply_to_message_id),
    reply_markup = reply_markup or ''
  })
	result(response)
end

C.sendMessage = sendMessage

local function forwardMessage(chat_id, from_chat_id, disable_notification, message_id)
  local response = makeRequest('forwardMessage', {
    chat_id = chat_id,
    from_chat_id = from_chat_id,
    disable_notification = tostring(disable_notification),
    message_id = tonumber(message_id),
  })
	result(response)
end

C.forwardMessage = forwardMessage

local function sendPhoto(chat_id, photo, caption, disable_notification, reply_to_message_id, reply_markup)
  local file_id = ''
  local photo_data = {}

  if not(string.find(photo, '%.')) then
    file_id = photo
  else
    file_id = nil
    local photo_file = io.open(photo, 'r')

    photo_data.filename = photo
    photo_data.data = photo_file:read('*a')
    photo_data.content_type = 'image'

    photo_file:close()
  end

  local response = makeRequest('sendPhoto', {
    chat_id = chat_id,
    photo = file_id or photo_data,
    caption = caption,
    disable_notification = tostring(disable_notification),
    reply_to_message_id = tonumber(reply_to_message_id),
    reply_markup = reply_markup
  })
	result(response)
end

C.sendPhoto = sendPhoto

local function sendAudio(chat_id, audio, duration, performer, title, disable_notification, reply_to_message_id, reply_markup)
  local file_id = ''
  local audio_data = {}

  if not(string.find(audio, '%.mp3')) then
    file_id = audio
  else
    file_id = nil
    local audio_file = io.open(audio, 'r')

    audio_data.filename = audio
    audio_data.data = audio_file:read('*a')
    audio_data.content_type = 'audio/mpeg'

    audio_file:close()
  end

  local response = makeRequest('sendAudio', {
    chat_id = chat_id,
    audio = file_id or audio_data,
    duration = duration,
    performer = performer,
    title = title,
    disable_notification = tostring(disable_notification),
    reply_to_message_id = tonumber(reply_to_message_id),
    reply_markup = reply_markup
  })
	result(response)
end

C.sendAudio = sendAudio

local function sendDocument(chat_id, document, caption, disable_notification, reply_to_message_id, reply_markup)
  local file_id = ''
  local document_data = {}

  if not(string.find(document, '%.')) then
    file_id = document
  else
    file_id = nil
    local document_file = io.open(document, 'r')

    document_data.filename = document
    document_data.data = document_file:read('*a')

    document_file:close()
  end

  local response = makeRequest('sendDocument', {
    chat_id = chat_id,
    document = file_id or document_data,
    caption = caption,
    disable_notification = tostring(disable_notification),
    reply_to_message_id = tonumber(reply_to_message_id),
    reply_markup = reply_markup
  })
	result(response)
end

C.sendDocument = sendDocument

local function sendSticker(chat_id, sticker, disable_notification, reply_to_message_id, reply_markup)
  local file_id = ''
  local sticker_data = {}

  if not(string.find(sticker, '%.webp')) then
    file_id = sticker
  else
    file_id = nil
    local sticker_file = io.open(sticker, 'r')

    sticker_data.filename = sticker
    sticker_data.data = sticker_file:read('*a')
    sticker_data.content_type = 'image/webp'

    sticker_file:close()
  end

  local response = makeRequest('sendSticker', {
    chat_id = chat_id,
    sticker = file_id or sticker_data,
    disable_notification = tostring(disable_notification),
    reply_to_message_id = tonumber(reply_to_message_id),
    reply_markup = reply_markup
  })
	result(response)
end

C.sendSticker = sendSticker

local function sendVideo(chat_id, video, duration, caption, disable_notification, reply_to_message_id, reply_markup)
  local file_id = ''
  local video_data = {}

  if not(string.find(video, '%.')) then
    file_id = video
  else
    file_id = nil
    local video_file = io.open(video, 'r')

    video_data.filename = video
    video_data.data = video_file:read('*a')
    video_data.content_type = 'video'

    video_file:close()
  end

  local response = makeRequest('sendVideo', {
    chat_id = chat_id,
    video = file_id or video_data,
    duration = duration,
    caption = caption,
    disable_notification = tostring(disable_notification),
    reply_to_message_id = tonumber(reply_to_message_id),
    reply_markup = reply_markup
  })
	result(response)
end

C.sendVideo = sendVideo

local function sendVoice(chat_id, voice, duration, disable_notification, reply_to_message_id, reply_markup)
  local file_id = ''
  local voice_data = {}

  if not(string.find(voice, '%.ogg')) then
    file_id = voice
  else
    file_id = nil
    local voice_file = io.open(voice, 'r')

    voice_data.filename = voice
    voice_data.data = voice_file:read('*a')
    voice_data.content_type = 'audio/ogg'

    voice_file:close()
  end

  local response = makeRequest('sendVoice', {
    chat_id = chat_id,
    voice = file_id or voice_data,
    duration = duration,
    disable_notification = tostring(disable_notification),
    reply_to_message_id = tonumber(reply_to_message_id),
    reply_markup = reply_markup
  })
	result(response)
end

C.sendVoice = sendVoice

local function sendLocation(chat_id, latitude, longitude, disable_notification, reply_to_message_id, reply_markup)
  chat_id = chat_id
  latitude = tonumber(latitude)
  longitude = tonumber(longitude)
  disable_notification = tostring(disable_notification)
  reply_to_message_id = tonumber(reply_to_message_id)
  reply_markup = reply_markup

  local response = makeRequest('sendLocation',request_body)
end

C.sendLocation = sendLocation

local function sendChatAction(chat_id, action)
  -- action = typing|upload_photo|record_video|upload_video|record_audio|upload_audio|upload_document|find_location
  local response = makeRequest('sendChatAction', {
    chat_id = chat_id,
    action = action
  })
	result(response)
end

C.sendChatAction = sendChatAction

local function sendVenue(chat_id, latitude, longitude, title, adress, foursquare_id, disable_notification, reply_to_message_id, reply_markup)
  local response = makeRequest('sendVenue', {
    chat_id = chat_id,
    latitude = tonumber(latitude),
    longitude = tonumber(longitude),
    title = title,
    adress = adress,
    foursquare_id = foursquare_id,
    disable_notification = tostring(disable_notification),
    reply_to_message_id = tonumber(reply_to_message_id),
    reply_markup = reply_markup
  })
	result(response)
end

C.sendVenue = sendVenue

local function sendContact(chat_id, phone_number, first_name, last_name, disable_notification, reply_to_message_id, reply_markup)
  local response = makeRequest('sendContact', {
    chat_id = chat_id,
    phone_number = tostring(phone_number),
    first_name = tostring(first_name),
    last_name = tostring(last_name),
    disable_notification = tostring(disable_notification),
    reply_to_message_id = tonumber(reply_to_message_id),
    reply_markup = reply_markup
  })
	result(response)
end

C.sendContact = sendContact

local function kickChatMember(chat_id, user_id)
  local response = makeRequest('kickChatMember', {
    chat_id = chat_id,
    user_id = tonumber(user_id)
  })
	result(response)
end

C.kickChatMember = kickChatMember

local function unbanChatMember(chat_id, user_id)
  local response = makeRequest('unbanChatMember', {
    chat_id = chat_id,
    user_id = tonumber(user_id)
  })
	result(response)
end

local function leaveChat(chat_id)
  local response = makeRequest('leaveChat', {chat_id})
  return result(response)
end

C.leaveChat = leaveChat

local function process_msg(msg)
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

C.process_msg = process_msg

return C
