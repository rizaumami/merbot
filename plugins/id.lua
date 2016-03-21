--[[

Print user identification/informations by replying their post or by providing
their username or print_name.

!id <text> is the least reliable because it will scan trough all of members
and print all member with <text> in their print_name.

chat_info can be displayed on group, send it into PM, or save as file then send
it into group or PM.

--]]

do

  local function resolve_username_cb(extra, success, result)
    if success == 1 then
      if result.username then
        user_name = ' @'..result.username
      else
        user_name = ''
      end
      local text = '<code>Name      :</code><b>'..(result.first_name or '')..' '..(result.last_name or '')..'</b>\n'
                 ..'<code>First name:</code>'..(result.first_name or '')..'\n'
                 ..'<code>Last name :</code>'..(result.last_name or '')..'\n'
                 ..'<code>User name :</code>'..user_name..'\n'
                 ..'<code>ID        :'..result.peer_id..'</code>'
      send_api_msg(msg, get_receiver_api(extra), text, true, 'html')
    else
      send_api_msg(msg, get_receiver_api(extra), '<b>Failed</b> to resolve '
          ..extra.text:gsub('!id ', '')..' IDs.\n'
          ..'Check if the username is correct.', true, 'html')
    end
  end

  local function scan_name(extra, success, result)
    if extra.to.peer_type == 'channel' then
      member_list = result
    else
      member_list = result.members
    end
    local user = extra.text:gsub('!id.+ ', '')
    local user = user:gsub(' ', '_')
    local founds = {}
    for k,member in pairs(member_list) do
      fields = {'first_name', 'last_name', 'print_name'}
      for k,field in pairs(fields) do
        if member[field] and type(member[field]) == 'string' then
          local gp_member = member[field]:lower()
          if gp_member:match(user:lower()) then
            founds[tostring(member.id)] = member
          end
        end
      end
    end
    if next(founds) == nil then -- Empty table
      send_api_msg(msg, get_receiver_api(extra), user..' <b>not found on this chat</b>', true, 'html')
    else
      local text = ''
      for k,user in pairs(founds) do
        if user.username then
          user_name = ' @'..user.username 
        else
          user_name = ''
        end
        text = '<code>Name      :</code><b>'..(user.first_name or '')..' '..(user.last_name or '')..'</b>\n'
             ..'<code>First name:</code>'..(user.first_name or '')..'\n'
             ..'<code>Last name :</code>'..(user.last_name or '')..'\n'
             ..'<code>User name :</code>'..user_name..'\n'
             ..'<code>ID        :'..user.peer_id..'</code>\n\n'
      end
      send_api_msg(msg, get_receiver_api(extra), text, true, 'html')
    end
  end

  local function action_by_reply(extra, success, result)
    if result.from.username then
      user_name = ' @'..result.from.username
    else
      user_name = ''
    end
    local text = '<code>Name      :</code><b>'..(result.from.first_name or '')..' '..(result.from.last_name or '')..'</b>\n'
               ..'<code>First name:</code>'..(result.from.first_name or '')..'\n'
               ..'<code>Last name :</code>'..(result.from.last_name or '')..'\n'
               ..'<code>User name :</code>'..user_name..'\n'
               ..'<code>ID        :'..result.from.peer_id..'</code>'
    send_api_msg(msg, get_receiver_api(extra), text, true, 'html')
  end

  local function returnids(extra, success, result)
    if extra.to.peer_type == 'channel' then
      chat_id = extra.to.peer_id
      chat_title = extra.to.title
      member_list = result
    else
      chat_id = result.peer_id
      chat_title = result.title
      member_list = result.members
    end
    local match = extra.text:gsub('!id chat ', '')
    local list = '*'..chat_title..' -* `'..chat_id..'`\n\n'
    local text = chat_title..' - '..chat_id..'\n\n'
    i = 0
    for k,v in pairsByKeys(member_list) do
      i = i+1
      if v.username then
        user_name = ' @'..v.username
      else
        user_name = ''
      end
      list = list..'*'..i..'*. `'..v.peer_id..'` -'..user_name..' '..(v.first_name or '')..(v.last_name or '')..'\n'
      text = text..i..'. '..v.peer_id..' -'..user_name..' '..(v.first_name or '')..(v.last_name or '')..'\n'
    end
    if match == 'pm' then
      send_api_msg(msg, extra.from.peer_id, list:gsub('_', '[_]'), true, 'md')
    elseif match == 'txt' or match == 'pmtxt' then
      local textfile = '/tmp/chat_info_'..extra.to.peer_id..'_'..os.date("%y%m%d.%H%M%S")..'.txt'
      local file = io.open(textfile, 'w')
      file:write(text)
      file:flush()
      file:close()
      if match == 'txt' then
        send_document(get_receiver(extra), textfile, rmtmp_cb, {file_path=textfile})
      elseif match == 'pmtxt' then
        send_document('user#id'..extra.from.peer_id, textfile, rmtmp_cb, {file_path=textfile})
      end
    else
      send_api_msg(msg, get_receiver_api(extra), list:gsub('_', '[_]'), true, 'md')
    end
  end

--------------------------------------------------------------------------------

  local function run(msg, matches)
  
    if not is_chat_msg(msg) and not is_admin(msg.from.peer_id) then return nil end

    if is_mod(msg, msg.to.peer_id, msg.from.peer_id) then
      if msg.reply_id and msg.text == '!id' then
        get_message(msg.reply_id, action_by_reply, msg)
      elseif matches[1] == 'chat' then
        if msg.to.peer_type == 'channel' then
          channel_get_users('channel#id'..msg.to.peer_id, returnids, msg)
        end
        if msg.to.peer_type == 'chat' then
          chat_info('chat#id'..msg.to.peer_id, returnids, msg)
        end
      elseif matches[1] == '@' then
        resolve_username(matches[2], resolve_username_cb, msg)
      elseif matches[1] == 'name' then
        if msg.to.peer_type == 'channel' then
          channel_get_users('channel#id'..msg.to.peer_id, scan_name, msg)
        end
        if msg.to.peer_type == 'chat' then
          chat_info('chat#id'..msg.to.peer_id, scan_name, msg)
        end
      end
    end

    if not msg.reply_id and msg.text == '!id' then
      if msg.from.username then
        user_name = '@'..msg.from.username
      else
        user_name = ''
      end
      local text = '<code>Name      :</code><b>'..(msg.from.first_name or '')..' '..(msg.from.last_name or '')..'</b>\n'
                 ..'<code>First name:</code>'..(msg.from.first_name or '')..'\n'
                 ..'<code>Last name :</code>'..(msg.from.last_name or '')..'\n'
                 ..'<code>User name :</code>'..user_name..'\n'
                 ..'<code>ID        :'..msg.from.peer_id..'</code>'
      if not is_chat_msg(msg) then
        send_api_msg(msg, get_receiver_api(msg), text, true, 'html')
      else
        send_api_msg(msg, get_receiver_api(msg), text..'\n\nYou are in group <b>'..msg.to.title..'</b> [<code>'..msg.to.peer_id..'</code>]', true, 'html')
      end
    end

  end

--------------------------------------------------------------------------------

  return {
    description = 'Know your id or the id of a chat members.',
    usage = {
      moderator = {
        '<code>!id</code>',
        'Return ID of replied user if used by reply.',
        '<code>!id chat</code>',
        'Return the IDs of the current chat members.',
        '<code>!id chat txt</code>',
        'Return the IDs of the current chat members and send it as text file.',
        '<code>!id chat pm</code>',
        'Return the IDs of the current chat members and send it to PM.',
        '<code>!id chat pmtxt</code>',
        'Return the IDs of the current chat members, save it as text file and then send it to PM.',
        '<code>!id [user_id]</code>',
        'Return the IDs of the user_id.',
        '<code>!id @[user_name]</code>',
        'Return the member username ID from the current chat.',
        '<code>!id [name]</code>',
        'Search for users with name on <code>first_name</code>, <code>last_name</code>, or <code>print_name</code> on current chat.'
      },
      user = {
        '<code>!id</code>',
        'Return your ID and the chat id if you are in one.'
      },
    },
    patterns = {
      '^!(id)$',
      '^!id (chat)$',
      '^!id (chat) (.+)$',
      '^!id (name) (.*)$',
      '^!id (@)(.+)$'
    },
    run = run
  }

end
