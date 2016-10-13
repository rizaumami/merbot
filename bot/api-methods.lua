--[[

Partially taken from https://github.com/cosmonawt/lua-telegram-bot

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

-- Import Libraries
local encode = require 'multipart-post'

local api = {}

function makeRequest(method, request_body)
  local response = {}
  local body, boundary = encode.encode(request_body)

  local success, code, headers, status = https.request{
    url = 'https://api.telegram.org/bot71641016:AAEeV8KUoFJrROUYZVy0HOGe1FBb1kRHT4U/' .. method,
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

function api.getMe()
  makeRequest('getMe', {''})
end

function api.sendMessage(chat_id, text, parse_mode, disable_web_page_preview, disable_notification, reply_to_message_id, reply_markup)
  local allowed_parse_mode = {['markdown'] = true, ['html'] = true}

  if (not allowed_parse_mode[parse_mode:lower()]) then parse_mode = '' end

  makeRequest('sendMessage', {
    chat_id = chat_id,
    text = tostring(text),
    parse_mode = parse_mode:lower(),
    disable_web_page_preview = tostring(disable_web_page_preview),
    disable_notification = tostring(disable_notification),
    reply_to_message_id = tonumber(reply_to_message_id),
    reply_markup = reply_markup or ''
  })
end

function api.forwardMessage(chat_id, from_chat_id, disable_notification, message_id)
  makeRequest('forwardMessage', {
    chat_id = chat_id,
    from_chat_id = from_chat_id,
    disable_notification = tostring(disable_notification),
    message_id = tonumber(message_id),
  })
end

function api.sendPhoto(chat_id, photo, caption, disable_notification, reply_to_message_id, reply_markup)
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
end

function api.sendAudio(chat_id, audio, duration, performer, title, disable_notification, reply_to_message_id, reply_markup)
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

  makeRequest('sendAudio', {
    chat_id = chat_id,
    audio = file_id or audio_data,
    duration = duration,
    performer = performer,
    title = title,
    disable_notification = tostring(disable_notification),
    reply_to_message_id = tonumber(reply_to_message_id),
    reply_markup = reply_markup
  })
end

function api.sendDocument(chat_id, document, caption, disable_notification, reply_to_message_id, reply_markup)
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

  makeRequest('sendDocument', {
    chat_id = chat_id,
    document = file_id or document_data,
    caption = caption,
    disable_notification = tostring(disable_notification),
    reply_to_message_id = tonumber(reply_to_message_id),
    reply_markup = reply_markup
  })
end

function api.sendSticker(chat_id, sticker, disable_notification, reply_to_message_id, reply_markup)
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

  makeRequest('sendSticker', {
    chat_id = chat_id,
    sticker = file_id or sticker_data,
    disable_notification = tostring(disable_notification),
    reply_to_message_id = tonumber(reply_to_message_id),
    reply_markup = reply_markup
  })
end

function api.sendVideo(chat_id, video, duration, caption, disable_notification, reply_to_message_id, reply_markup)
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

  makeRequest('sendVideo', {
    chat_id = chat_id,
    video = file_id or video_data,
    duration = duration,
    caption = caption,
    disable_notification = tostring(disable_notification),
    reply_to_message_id = tonumber(reply_to_message_id),
    reply_markup = reply_markup
  })
end

function api.sendVoice(chat_id, voice, duration, disable_notification, reply_to_message_id, reply_markup)
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

  makeRequest('sendVoice', {
    chat_id = chat_id,
    voice = file_id or voice_data,
    duration = duration,
    disable_notification = tostring(disable_notification),
    reply_to_message_id = tonumber(reply_to_message_id),
    reply_markup = reply_markup
  })
end

function api.sendLocation(chat_id, latitude, longitude, disable_notification, reply_to_message_id, reply_markup)
  chat_id = chat_id
  latitude = tonumber(latitude)
  longitude = tonumber(longitude)
  disable_notification = tostring(disable_notification)
  reply_to_message_id = tonumber(reply_to_message_id)
  reply_markup = reply_markup

  local response = makeRequest('sendLocation',request_body)
end

function api.sendChatAction(chat_id, action)
  -- action = typing|upload_photo|record_video|upload_video|record_audio|upload_audio|upload_document|find_location
  makeRequest('sendChatAction', {chat_id = chat_id, action = action})
end

function api.sendVenue(chat_id, latitude, longitude, title, adress, foursquare_id, disable_notification, reply_to_message_id, reply_markup)
  makeRequest('sendVenue', {
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
end

function api.sendContact(chat_id, phone_number, first_name, last_name, disable_notification, reply_to_message_id, reply_markup)
  makeRequest('sendContact', {
    chat_id = chat_id,
    phone_number = tostring(phone_number),
    first_name = tostring(first_name),
    last_name = tostring(last_name),
    disable_notification = tostring(disable_notification),
    reply_to_message_id = tonumber(reply_to_message_id),
    reply_markup = reply_markup
  })
end

function api.kickChatMember(chat_id, user_id)
  makeRequest('kickChatMember', {
    chat_id = chat_id,
    user_id = tonumber(user_id)
  })
end

function api.unbanChatMember(chat_id, user_id)
  makeRequest('unbanChatMember', {
    chat_id = chat_id,
    user_id = tonumber(user_id)
  })
end

function api.leaveChat(chat_id)
  makeRequest('leaveChat', {chat_id})
end

return api
