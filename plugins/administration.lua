do

  local tgexec = "./tg/bin/telegram-cli -c ./data/tg-cli.config -p default -De "
  local NUM_MSG_MAX = 4  -- Max number of messages per TIME_CHECK seconds
  local TIME_CHECK = 4
  local new_group_table = {}



  local function is_banned(chat_id, user_id)
    local hash = 'banned:'..chat_id
    local banned = redis:sismember(hash, user_id)
    return banned or false
  end

  local function is_globally_banned(user_id)
    local hash = 'globanned'
    local banned = redis:sismember(hash, user_id)
    return banned or false
  end

  local function get_sudolist(msg)
    local sudoers = 'List of sudoers:\n\n'
    for k,v in pairs(_config.sudo_users) do
      sudoers = sudoers..'- '..v..' - '..k..'\n'
    end
    reply_msg(msg.id, sudoers, ok_cb, true)
  end

  local function get_adminlist(msg, chat_id)
    local group = msg.to.title or chat_id
    if not _config.administration[tonumber(chat_id)] then
      reply_msg(msg.id, 'I do not administrate this group.', ok_cb, true)
    elseif next(_config.administrators) == nil then
      reply_msg(msg.id, 'There are currently no listed administrators.', ok_cb, true)
    else
      local message = 'Administrators for '..group..':\n\n'
      for k,v in pairs(_config.administrators) do
        message = message..'- '..v..' - '..k..'\n'
      end
      reply_msg(msg.id, message, ok_cb, true)
    end
  end

  local function get_ownerlist(msg, chat_id)
    local gid = tonumber(chat_id)
    local group = msg.to.title or gid
    local data = load_data(_config.administration[gid])
    if not _config.administration[gid] then
      reply_msg(msg.id, 'I do not administrate this group.', ok_cb, true)
    elseif next(data.owners) == nil then
      reply_msg(msg.id, 'There are currently no listed owners.', ok_cb, true)
    else
      local message = group..' owner(s):\n\n'
      for k,v in pairs(data.owners) do
        message = message..'- '..v..' - '..k..'\n'
      end
      reply_msg(msg.id, message, ok_cb, true)
    end
  end

  local function get_members_list(extra, success, result)
    if extra.to.peer_type == 'channel' then
      chat_id = extra.to.peer_id
      member_list = result
    else
      chat_id = result.peer_id
      member_list = result.members
    end
    local gid = tonumber(chat_id)
    local data = load_data(_config.administration[gid])
    for k,v in pairsByKeys(member_list) do
      data.members[v.peer_id] = '@'..v.username or v.first_name
    end
    save_data(data, 'data/'..gid..'/'..gid..'.lua')
  end

  -- kick user
  local function kick_user(msg, chat_id, user_id)
    local gid = tonumber(chat_id)
    local uid = tonumber(user_id)
    -- check if user was kicked in the last TIME_CHECK seconds
    if not redis:get('kicked:'..gid..':'..uid) or false then
      if is_mod(msg, gid, uid) or uid == our_id then
        reply_msg(msg.id, uid..' is too privileged to be kicked.', ok_cb, true)
      else
        if msg.to.peer_type == 'channel' then
          channel_kick_user('channel#id'..gid, 'user#id'..uid, ok_cb, true)
        else
          chat_del_user('chat#id'..gid, 'user#id'..uid, ok_cb, true)
        end
      end
    end
    -- set for TIME_CHECK seconds that user have been kicked
    redis:setex('kicked:'..gid..':'..uid, TIME_CHECK, 'true')
  end

  local function invite_user(msg, chat_id, user_id)
    local gid = tonumber(chat_id)
    local uid = tonumber(user_id)
    if is_globally_banned(uid) then
      reply_msg(msg.id, 'Invitation canceled.\nID '..uid..' is globally banned.', ok_cb, true)
    elseif is_banned(gid, uid) then
      reply_msg(msg.id, 'Invitation canceled.\nID '..uid..' is banned.', ok_cb, true)
    else
      if msg.to.peer_type == 'channel' then
        channel_invite_user('channel#id'..gid, 'user#id'..uid, ok_cb, false)
      else
        chat_add_user('chat#id'..gid, 'user#id'..uid, ok_cb, true)
      end
    end
  end

  local function ban_user(extra, chat_id, user_id)
    local gid = tonumber(chat_id)
    local uid = tonumber(user_id)
    if uid == tonumber(our_id) or is_mod(extra.msg, gid, uid) then
      reply_msg(extra.msg.id, extra.usr..' is too privileged to be banned.', ok_cb, true)
    end
    if is_banned(gid, uid) then
      reply_msg(extra.msg.id, extra.usr..' is already banned.', ok_cb, true)
    else
      local hash = 'banned:'..gid
      redis:sadd(hash, uid)
      --kick_user(extra.msg, gid, uid)
      reply_msg(extra.msg.id, extra.usr..' has been banned.', ok_cb, true)
    end
  end

  local function global_ban_user(extra, user_id)
    local gid = tonumber(chat_id)
    local uid = tonumber(user_id)
    if uid == tonumber(our_id) or is_admin(uid) then
      reply_msg(extra.msg.id, uid..' is too privileged to be globally banned.', ok_cb, true)
    end
    if is_globally_banned(uid) then
      reply_msg(extra.msg.id, extra.usr..' is already globally banned.', ok_cb, true)
    else
      local hash = 'globanned'
      redis:sadd(hash, uid)
      kick_user(msg, gid, uid)
      reply_msg(extra.msg.id, extra.usr..' has been globally banned.', ok_cb, true)
    end
  end

  local function unban_user(extra, chat_id, user_id)
    local hash = 'banned:'..chat_id
    redis:srem(hash, user_id)
    reply_msg(extra.msg.id, extra.usr..' has been unbanned.', ok_cb, true)
  end

  local function global_unban_user(extra, user_id)
    local hash = 'globanned'
    redis:srem(hash, user_id)
    reply_msg(extra.msg.id, extra.usr..' has been globally unbanned.', ok_cb, true)
  end

  local function whitelisting(extra, chat_id, user_id)
    local hash = 'whitelist'
    local is_whitelisted = redis:sismember(hash, user_id)
    if is_whitelisted then
      reply_msg(extra.msg.id, extra.usr..' is already whitelisted.', ok_cb, true)
    else
      redis:sadd(hash, user_id)
      reply_msg(extra.msg.id, extra.usr..' added to whitelist.', ok_cb, true)
    end
  end

  local function unwhitelisting(extra, chat_id, user_id)
    local hash = 'whitelist'
    local is_whitelisted = redis:sismember('whitelist', user_id)
    if not is_whitelisted then
      reply_msg(extra.msg.id, extra.usr..' is not whitelisted.', ok_cb, true)
    else
      redis:srem(hash, user_id)
      reply_msg(extra.msg.id, extra.usr..' removed from whitelist', ok_cb, true)
    end
  end

  local function promote(extra, chat_id, user_id)
    local gid = tonumber(chat_id)
    local uid = tonumber(user_id)
    local data = load_data(_config.administration[gid])
    if data.moderators ~= nil and data.moderators[uid] then
      reply_msg(extra.msg.id, uid..' is already a moderator.', ok_cb, true)
    else
      data.moderators[uid] = extra.usr
      save_data(data, 'data/'..gid..'/'..gid..'.lua')
      reply_msg(extra.msg.id, extra.usr..' is now a moderator.', ok_cb, true)
    end
  end

  local function demote(extra, chat_id, user_id)
    local gid = tonumber(chat_id)
    local uid = tonumber(user_id)
    local data = load_data(_config.administration[gid])
    if not data.moderators[uid] then
      reply_msg(extra.msg.id, uid..' is not a moderator.', ok_cb, true)
    elseif uid == extra.msg.from.peer_id then
      reply_msg(extra.msg.id, 'You can\'t demote yourself.', ok_cb, true)
    else
      data.moderators[uid] = nil
      save_data(data, 'data/'..gid..'/'..gid..'.lua')
      reply_msg(extra.msg.id, extra.usr..' is no longer a moderator.', ok_cb, true)
    end
  end

  local function promote_owner(extra, chat_id, user_id)
    local gid = tonumber(chat_id)
    local uid = tonumber(user_id)
    local data = load_data(_config.administration[gid])
    if data.owners[uid] then
      reply_msg(extra.msg.id, uid..' is already the group owner.', ok_cb, true)
    else
      data.owners[uid] = extra.usr
      save_data(data, 'data/'..gid..'/'..gid..'.lua')
      reply_msg(extra.msg.id, extra.usr..' is now the group owner.', ok_cb, true)
    end
  end

  local function demote_owner(extra, chat_id, user_id)
    local gid = tonumber(chat_id)
    local uid = tonumber(user_id)
    local data = load_data(_config.administration[gid])
    if not data.owners[uid] then
      reply_msg(extra.msg.id, uid..' is not the group owner.', ok_cb, true)
    elseif uid == extra.msg.from.peer_id then
      reply_msg(extra.msg.id, 'You can\'t demote yourself.', ok_cb, true)
    else
      data.owners[uid] = nil
      save_data(data, 'data/'..gid..'/'..gid..'.lua')
      reply_msg(extra.msg.id, extra.usr..' is no longer the group owner.', ok_cb, true)
    end
  end

  local function promote_admin(extra, user_id)
    local uid = tonumber(user_id)
    if _config.administrators[uid] then
      reply_msg(extra.msg.id, extra.usr..' is already an administrator.', ok_cb, true)
    else
      channel_set_admin(get_receiver(extra.msg), 'user#id'..uid, ok_cb, true)
      _config.administrators[uid] = extra.usr
      save_config()
      reply_msg(extra.msg.id, extra.usr..' is now an administrator.', ok_cb, true)
    end
  end

  local function demote_admin(extra, user_id)
    local uid = tonumber(user_id)
    if not _config.administrators[uid] then
      reply_msg(extra.msg.id, extra.usr..' is not an administrator.', ok_cb, true)
    elseif uid == extra.msg.from.peer_id then
      reply_msg(extra.msg.id, 'You can\'t demote yourself.', ok_cb, true)
    else
      channel_del_admin(get_receiver(extra.msg), 'user#id'..uid, ok_cb, true)
      _config.administrators[uid] = nil
      save_config()
      reply_msg(extra.msg.id, extra.usr..' is no longer an administrator.', ok_cb, true)
    end
  end

  local function visudo(extra, user_id)
    local uid = tonumber(user_id)
    if _config.sudo_users[uid] then
      reply_msg(extra.msg.id, extra.usr..' is already a sudoer.', ok_cb, true)
    else
      _config.sudo_users[uid] = extra.usr
      save_config()
      reply_msg(extra.msg.id, extra.usr..' is now a sudoer.', ok_cb, true)
    end
  end

  local function desudo(extra, user_id)
    local uid = tonumber(user_id)
    if not _config.sudo_users[uid] then
      reply_msg(extra.msg.id, extra.usr..' is not a sudoer.', ok_cb, true)
    elseif uid == extra.msg.from.peer_id then
      reply_msg(extra.msg.id, 'You can\'t demote yourself.', ok_cb, true)
    else
      _config.sudo_users[uid] = nil
      save_config()
      reply_msg(extra.msg.id, extra.usr..' is no longer a sudoer.', ok_cb, true)
    end
  end

  local function create_group_data(msg, chat_id, user_id)
    local l_name = '@'..msg.from.username or msg.from.first_name
    if msg.action then
      t_name = new_group_table[msg.action.title].uname
    end
    gpdata = {
        antispam = 'ban',
        founded = os.time(),
        founder = '',
        link = '',
        lock = {
          bot = 'no',
          member = 'no',
          name = 'yes',
          photo = 'yes',
        },
        members = {},
        moderators = {},
        name = msg.to.title,
        owners = {[user_id] = t_name or l_name},
        set = {
          name = msg.to.title,
          photo = 'data/'..chat_id..'/'..chat_id..'.jpg',
        },
        sticker = 'ok',
        type = msg.to.peer_type,
        username = msg.to.username or '',
        welcome = {
          msg = '',
          to = 'group',
        },
    }
    save_data(gpdata, 'data/'..chat_id..'/'..chat_id..'.lua')
  end

  -- [pro|de]mote|admin[prom|dem]|[global|un]ban|kick by user id
  local function action_by_id(extra, success, result)
    if success == 1 then
      if extra.msg.to.peer_type == 'channel' then
        members_list = result
      else
        members_list = result.members
      end
      local msg = extra.msg
      local chat_id = msg.to.peer_id
      local cmd = extra.matches[1]
      local is_group_member = false
      for k,v in pairs(members_list) do
        if extra.matches[3] == tostring(v.peer_id) then
          usr_in_lst = '@'..v.username or v.first_name
          is_group_member = true
          if cmd == 'promote' or cmd == 'mod' then
            promote({msg=msg, usr=usr}, chat_id, v.peer_id)
          end
          if cmd == 'demote' or cmd == 'demod' then
            demote({msg=msg, usr=usr}, chat_id, v.peer_id)
          end
          if cmd == 'kick' then
            kick_user(msg, chat_id, v.peer_id)
          end
          if cmd == 'whitelist' then
            whitelisting({msg=msg, usr=usr}, chat_id, v.peer_id)
          end
          if cmd == 'unwhitelist' then
            unwhitelisting({msg=msg, usr=usr}, chat_id, v.peer_id)
          end
        end
      end
      if cmd == 'visudo' or cmd == 'sudo' then
        visudo({msg=msg, usr=usr_in_lst}, extra.matches[3])
      end
      if cmd == 'desudo' then
        desudo({msg=msg, usr=usr_in_lst}, extra.matches[3])
      end
      if cmd == 'adminprom' or cmd == 'admin' then
        promote_admin({msg=msg, usr=usr_in_lst}, extra.matches[3])
      end
      if cmd == 'admindem' or cmd == 'deadmin' then
        demote_admin({msg=msg, usr=usr_in_lst}, extra.matches[3])
      end
      if cmd == 'setowner' or cmd == 'gov' then
        promote_owner({msg=msg, usr=usr_in_lst}, chat_id, extra.matches[3])
      end
      if cmd == 'remowner' or cmd == 'degov' then
        demote_owner({msg=msg, usr=usr_in_lst}, chat_id, extra.matches[3])
      end
      if cmd == 'ban' then
        ban_user({msg=msg, usr=usr_in_lst}, chat_id, extra.matches[3])
      end
      if cmd == 'superban' or cmd == 'gban' or cmd == 'hammer' then
        global_ban_user({msg=msg, usr=usr_in_lst}, extra.matches[3])
      end
      if cmd == 'unban' then
        unban_user({msg=msg, usr=usr_in_lst}, chat_id, extra.matches[3])
      end
      if cmd == 'superunban' or cmd == 'gunban' or cmd == 'unhammer' then
        global_unban_user({msg=msg, usr=usr_in_lst}, extra.matches[3])
      end
      if not is_group_member then
        reply_msg(msg.id, extra.matches[3]..' is not member of this group.', ok_cb, true)
      end
    end
  end

  -- [pro|de]mote|admin[prom|dem]|[global|un]ban|kick|[un]whitelist by reply
  local function action_by_reply(extra, success, result)
    local chat_id = extra.to.peer_id
    local user_id = result.from.peer_id
    local usr = '@'..result.from.username or result.from.first_name
    local cmd = extra.text
    if is_chat_msg(extra) then
      if cmd == '!kick' then
        kick_user(extra, chat_id, user_id)
      end
      if cmd == '!visudo' or cmd == '!sudo' then
        visudo({msg=extra, usr=usr}, user_id)
      end
      if cmd == '!desudo' then
        desudo({msg=extra, usr=usr}, user_id)
      end
      if cmd == '!adminprom' or cmd == '!admin' then
        promote_admin({msg=extra, usr=usr}, user_id)
      end
      if cmd == '!admindem' or cmd == '!deadmin' then
        demote_admin({msg=extra, usr=usr}, user_id)
      end
      if cmd == '!setowner' or cmd == '!gov' then
        promote_owner({msg=extra, usr=usr}, chat_id, user_id)
      end
      if cmd == '!remowner' or cmd == '!degov' then
        demote_owner({msg=extra, usr=usr}, chat_id, user_id)
      end
      if cmd == '!promote' or cmd == '!mod' then
        promote({msg=extra, usr=usr}, chat_id, user_id)
      end
      if cmd == '!demote' or cmd == '!demod' then
        demote({msg=extra, usr=usr}, chat_id, user_id)
      end
      if cmd == '!invite' then
        invite_user(extra, chat_id, user_id)
      end
      if cmd == '!ban' then
        ban_user({msg=extra, usr=usr}, chat_id, user_id)
      end
      if cmd == '!superban' or cmd == '!gban' or cmd == '!hammer' then
        global_ban_user({msg=extra, usr=usr}, user_id)
      end
      if cmd == '!unban' then
        unban_user({msg=extra, usr=usr}, chat_id, user_id)
      end
      if cmd == '!superunban' or cmd == '!gunban' or cmd == '!unhammer' then
        global_unban_user({msg=extra, usr=usr}, user_id)
      end
      if cmd == '!whitelist' then
        whitelisting({msg=extra, usr=usr}, chat_id, user_id)
      end
      if cmd == '!unwhitelist' then
        unwhitelisting({msg=extra, usr=usr}, chat_id, user_id)
      end
    end
  end

  -- [global|un]ban|kick by username
  local function resolve_username_cb(extra, success, result)
    if result ~= false then
      local msg = extra.msg
      local uid = result.peer_id
      local cmd = extra.matches[1]
      local usr = '@'..result.username or result.first_name
      if is_chat_msg(msg) then
        gid = msg.to.peer_id
      else
        gid = extra.matches[4]
      end
      if cmd == 'kick' then
        kick_user(msg, gid, uid)
      end
      if cmd == 'invite' or cmd == 'gadd' then
        invite_user(msg, gid, uid)
      end
      if cmd == 'ban' then
        ban_user({msg=msg, usr=usr}, gid, uid)
      end
      if cmd == 'superban' or cmd == 'gban' or cmd == 'hammer' then
        global_ban_user({msg=msg, usr=usr}, uid)
      end
      if cmd == 'unban' then
        unban_user({msg=msg, usr=usr}, uid)
      end
      if cmd == 'superunban' or cmd == 'gunban' or cmd == 'unhammer' then
        global_unban_user({msg=msg, usr=usr}, uid)
      end
      if cmd == 'visudo' or cmd == 'sudo' then
        visudo({msg=msg, usr=usr}, uid)
      end
      if cmd == 'desudo' then
        desudo({msg=msg, usr=usr}, uid)
      end
      if cmd == 'admin' or cmd == 'adminprom' then
        promote_admin({msg=msg, usr=usr}, uid)
      end
      if cmd == 'deadmin' or cmd == 'admindem' then
        demote_admin({msg=msg, usr=usr}, uid)
      end
      if cmd == 'setowner' or cmd == 'gov' then
        promote_owner({msg=msg, usr=usr}, gid, uid)
      end
      if cmd == 'remowner' or cmd == 'degov' then
        demote_owner({msg=msg, usr=usr}, gid, uid)
      end
      if cmd == 'promote' or cmd == 'mod' then
        promote({msg=msg, usr=usr}, chat_id, uid)
      end
      if cmd == 'demote' or cmd == 'demod' then
        demote({msg=msg, usr=usr}, gid, uid)
      end
      if cmd == 'whitelist' then
        whitelisting({msg=msg, usr=usr}, gid, uid)
      end
      if cmd == 'unwhitelist' then
        unwhitelisting({msg=msg, usr=usr}, gid, uid)
      end
    else
      reply_msg(extra.msg.id, '@'..extra.matches[3]..' is not member of this group.', ok_cb, true)
    end
    if success == 0 then
      reply_msg(extra.msg.id, 'Failed to invite @'..extra.matches[3]..' into this group.\nCheck if the username is correct.', ok_cb, true)
    end
  end

  -- trigger anti spam and anti flood
  local function trigger_anti_spam(extra, chat_id, user_id)
    local data = load_data(_config.administration[chat_id])
    if data.antispam == 'kick' then
      kick_user(extra.msg, chat_id, user_id)
      reply_msg(extr.msg.id, extra.usr..' is '..splooder)
    elseif data.antispam == 'ban' then
      ban_user({msg=extra.msg, usr=extra.usr}, chat_id, user_id)
      reply_msg(extr.msg.id, extra.usr..' is '..splooder..'. Banned')
    end
    msg = nil
  end

  -- callback for invite link
  local function set_group_link_cb(extra, success, result)
    local data = load_data(extra.file)
    data.link = result
    save_data(data, extra.file)
    if extra.mute == 'revoke' then
      data.link = 'revoked'
      save_data(data, extra.file)
    elseif extra.mute ~= true then
      reply_msg(extra.msg.id, result, ok_cb, true)
    end
  end

  -- set chat|channel invite link
  local function set_group_link(extra, file, mute)
    if extra.msg.to.peer_type == 'channel' then
      export_channel_link('channel#id'..extra.gid, set_group_link_cb, {msg=extra.msg, file=file, mute=mute})
    else
      export_chat_link('chat#id'..extra.gid, set_group_link_cb, {msg=extra.msg, file=file, mute=mute})
    end
  end

  -- set chat|group photo
  local function set_group_photo(extra, success, result)
    local data = extra.data
    local msg = extra.msg
    if success then
      local filepath = 'data/'..msg.to.peer_id..'/'..msg.to.peer_id
      print('File downloaded to:', result)
      os.rename(result, filepath..'.jpg')
      print('File moved to:', filepath..'.jpg')
      if msg.to.peer_type == 'channel' then
        channel_set_photo(get_receiver(msg), filepath..'.jpg', ok_cb, false)
      else
        chat_set_photo(get_receiver(msg), filepath..'.jpg', ok_cb, false)
      end
      data.set.photo = filepath..'.jpg'
      save_data(data, filepath..'.lua')
      data.lock.photo = 'yes'
      save_data(data, filepath..'.lua')
      reply_msg(msg.id, 'Photo saved!', ok_cb, false)
    else
      print('Error downloading: '..msg.id)
      reply_msg(msg.id, 'Error downloading this photo, please try again.', ok_cb, false)
    end
  end

  local function group_info_by_id(extra, chat_id, user_id)
    if extra.msg.to.peer_type == 'channel' then
      channel_get_users(get_receiver(extra.msg), action_by_id, extra)
    else
      chat_info(get_receiver(extra.msg), action_by_id, extra)
    end
  end

  local function load_group_photo(msg, chat_id)
    local dl_dir = '.telegram-cli/downloads'
    os.execute('mv '..dl_dir..' '..dl_dir..'-bak && mkdir '..dl_dir)
    if msg.to.peer_type == 'channel' then
      os.execute(tgexec.."\'load_channel_photo channel#id"..chat_id.."\'")
    else
      os.execute(tgexec.."\'load_chat_photo chat#id"..chat_id.."\'")
    end
    local g_photo = scandir(dl_dir)
    os.rename(dl_dir..'/'..g_photo[3], 'data/'..chat_id..'/'..chat_id..'.jpg')
    os.execute('rm -r '..dl_dir..' && mv '..dl_dir..'-bak '..dl_dir)
  end

  local function add_group(msg, chat_id, user_id)
    local gid = tonumber(chat_id)
    local group = msg.to.title or gid
    local cfg = 'data/'..gid..'/'..gid..'.lua'
    if _config.administration[gid] then
      reply_msg(msg.id, 'I am already administrating '..group, ok_cb, true)
    else
      os.execute('mkdir -p data/'..gid)
      _config.administration[gid] = cfg
      save_config()
      create_group_data(msg, gid, user_id)
      set_group_link({msg=msg, gid=gid}, cfg, true)
      if msg.to.peer_type == 'channel' then
        channel_get_users('channel#id'..gid, get_members_list, msg)
      else
        chat_info('chat#id'..gid, get_members_list, msg)
      end
      load_group_photo(msg, gid)
      reply_msg(msg.id, 'I am now administrating '..group, ok_cb, true)
    end
  end

  local function remove_group(msg, chat_id)
    local gid = tonumber(chat_id)
    local group = msg.to.title or gid
    if not _config.administration[gid] then
      reply_msg(msg.id, 'I do not administrate '..group, ok_cb, true)
    else
      _config.administration[gid] = nil
      save_config()
      os.execute('rm -r data/'..gid)
      reply_msg(msg.id, 'I am no longer administrating '..group, ok_cb, true)
    end
  end



  local function pre_process(msg)

    local user_id = msg.from.peer_id
    local chat_id = msg.to.peer_id
    local receiver = get_receiver(msg)

    if msg.action then
      if _config.administration[chat_id] then
        local data = load_data(_config.administration[chat_id])
        -- service message
        if msg.action.type == 'chat_add_user' or msg.action.type == 'chat_add_user_link' then
          if msg.action.link_issuer then
            user_id = user_id
            new_member = (msg.from.first_name or '')..' '..(msg.from.last_name or '')
            uname = '@'..msg.from.username or ''
          else
            user_id = msg.action.user.peer_id
            new_member = (msg.action.user.first_name or '')..' '..(msg.action.user.last_name or '')
            uname = '@'..msg.action.user.username or ''
          end
          local username = uname..' AKA ' or ''
          if is_globally_banned(user_id) or is_banned(chat_id, user_id) then
            kick_user(msg, chat_id, user_id)
          end
          if user_id ~= 0 and not is_mod(msg, chat_id, user_id) then
            if data.lock.member == 'yes' then
              kick_user(msg, chat_id, user_id)
            end
            -- is it an API bot?
            if msg.flags == 8450 and data.lock.bot == 'yes' then
              kick_user(msg, chat_id, user_id)
            end
          end
          -- welcome message
          if data.welcome.to ~= 'no' then
            -- do not greet (globally) banned users.
            if is_globally_banned(user_id) or is_banned(chat_id, user_id) then
              return nil
            end
            -- do not greet when group members are locked
            if data.lock.member == 'yes' then
              return nil
            end
            local about = ''
            local rules = ''
            if data.description then
              about = '\n<b>Description</b>:\n'..data.description..'\n'
            end
            if data.rules then
              rules = '\n<b>Rules</b>:\n'..data.rules..'\n'
            end
            local welcomes = data.welcome.msg..'\n' or 'Welcome '..username..'<b>'..new_member..'</b> <code>['..user_id..']</code>\nYou are in group <b>'..msg.to.title..'</b>\n'
            if data.welcome.to == 'group' then
              receiver_api = get_receiver_api(msg)
            elseif data.welcome.to == 'private' then
              receiver_api = 'user#id'..user_id
            end
            send_api_msg(msg, receiver_api, welcomes..about..rules..'\n', true, 'html')
          end
          -- add user to members table
          data.members[user_id] = uname or new_member
          save_data(data, 'data/'..chat_id..'/'..chat_id..'.lua')
        end
        -- if group photo is deleted
        if msg.action.type == 'chat_delete_photo' then
          if data.lock.photo == 'yes' then
            chat_set_photo (receiver, data.set.photo, ok_cb, false)
          elseif data.lock.photo == 'no' then
            return nil
          end
        end
        -- if group photo is changed
        if msg.action.type == 'chat_change_photo' and user_id ~= 0 then
          if data.lock.photo == 'yes' then
            chat_set_photo (receiver, data.set.photo, ok_cb, false)
          elseif data.lock.photo == 'no' then
            return nil
          end
        end
        -- if group name is renamed
        if msg.action.type == 'chat_rename' then
          if data.lock.name == 'yes' then
            if data.set.name ~= tostring(msg.to.print_name) then
              rename_chat(receiver, data.set.name, ok_cb, false)
            end
          end
          if data.lock.name == 'no' then
            return nil
          end
          -- if user leave, remove from members table
          if msg.action.type == 'chat_del_user' then
            data.members[user_id] = nil
            save_data(data, 'data/'..gid..'/'..gid..'.lua')
            --return 'Bye '..new_member..'!'
          end
        end
      end
      -- autoleave
      if msg.action.type == 'chat_add_user' and not is_sudo(user_id) then
        if _config.autoleave == true and not _config.administration[chat_id] then
          if msg.to.peer_type == 'channel' then
            channel_leave(receiver, ok_cb, false)
          else
            chat_del_user(receiver, 'user#id'..our_id, ok_cb, true)
          end
        end
      end
      --TODO See mkgroup or mksupergroup functions
      -- create group config when the group is just created
      if msg.action.type == 'chat_created' then
        local group = msg.action.title
        local uid = new_group_table[group].uid
        local g_type = new_group_table[group].gtype
        local r_name = new_group_table[group].uname
        add_group(msg, chat_id, uid)
        if g_type then
          chat_upgrade('chat#id'..chat_id, ok_cb, false)
        else
          new_group_table[group] = nil
        end
      end
      -- create group config when the group is just created
      if msg.action.type == 'migrated_from' then
        local group = msg.to.title
        local uid = new_group_table[group].uid
        local title = new_group_table[group].title
        if msg.to.title == title then
          channel_set_admin(get_receiver(msg), 'user#id'..uid, ok_cb, true)
          new_group_table[group] = nil
        end
      end
    end

    -- anti spam
    if msg.from.peer_type == 'user' and msg.text and not is_mod(msg, chat_id, user_id) then
      local _nl, ctrl_chars = msg.text:gsub('%c', '')
      -- if string length more than 2048 or control characters is more than 50
      if string.len(msg.text) > 2048 or ctrl_chars > 50 then
        local _c, chars = msg.text:gsub('%a', '')
        local _nc, non_chars = msg.text:gsub('%A', '')
        -- if non characters is bigger than characters
        if non_chars > chars then
          local username = '@'..msg.from.username or msg.from.first_name
          trigger_anti_spam({msg=msg, stype='spamming', usr=username}, chat_id, user_id)
        end
      end
    end

    -- anti flood
    local post_count = 'floodc:'..user_id..':'..chat_id
    redis:incr(post_count)
    if msg.from.peer_type == 'user' and not is_mod(msg, chat_id, user_id) then
      local post_count = 'user:'..user_id..':floodc'
      local msgs = tonumber(redis:get(post_count) or 0)
      if msgs > NUM_MSG_MAX then
        local username = '@'..msg.from.username or msg.from.first_name
        trigger_anti_spam({msg=msg, stype='flooding', usr=username}, chat_id, user_id)
      end
      redis:setex(post_count, TIME_CHECK, msgs+1)
    end

    -- banned user talking
    if is_chat_msg(msg) then
      if is_globally_banned(user_id) then
        print('>>> SuperBanned user talking!')
        kick_user(msg, chat_id, user_id)
        msg.text = ''
      elseif is_banned(chat_id, user_id) then
        print('>>> Banned user talking!')
        kick_user(msg, chat_id, user_id)
        msg.text = ''
      end
    end

    -- whitelist
    -- Allow all sudo users even if whitelist is allowed
    if redis:get('whitelist:enabled') and not is_sudo(user_id) then
      print('>>> Whitelist enabled and not sudo')
      -- Check if user or chat is whitelisted
      local allowed = redis:sismember('whitelist', user_id) or false
      if not allowed then
        print('>>> User '..user_id..' not whitelisted')
        if is_chat_msg(msg) then
          allowed = redis:sismember('whitelist', chat_id) or false
          if not allowed then
            print('>>> Chat '..chat_id..' not whitelisted')
          else
            print('>>> Chat '..chat_id..' whitelisted :)')
          end
        end
      else
        print('>>> User '..user_id..' allowed :)')
      end

      if not allowed then
        msg.text = ''
      end
    end

    if msg.media and _config.administration[chat_id] then
      local data = load_data(_config.administration[chat_id])
      if not msg.text then
        msg.text = '['..msg.media.type..']'
      end
      if is_mod(msg, chat_id, user_id) and msg.media.type == 'photo' then
        if data.set.photo == 'waiting' then
          load_photo(msg.id, set_group_photo, {msg=msg, data=data})
        end
      end
      -- if sticker is sent
      if msg.media.caption == 'sticker.webp' then
        local sticker_hash = 'mer_sticker:'..chat_id..':'..user_id
        local is_sticker_offender = redis:get(sticker_hash)
        if data.sticker == 'warn' then
          if is_sticker_offender then
            kick_user(msg, chat_id, user_id)
            redis:del(sticker_hash)
          end
          if not is_sticker_offender then
            redis:set(sticker_hash, true)
            reply_msg(msg.id, 'DO NOT send sticker into this group!\nThis is a WARNING, next time you will be kicked!', ok_cb, true)
          end
        end
        if data.sticker == 'kick' then
          kick_user(msg, chat_id, user_id)
          reply_msg(msg.id, 'DO NOT send sticker into this group!', ok_cb, true)
        end
      end
    end
    -- No further checks
    return msg
  end



  local function run(msg, matches)

    local chat_id = msg.to.peer_id
    local user_id = msg.from.peer_id
    local chat_db = 'data/'..chat_id..'/'..chat_id..'.lua'
    local receiver = get_receiver(msg)

    if is_chat_msg(msg) then
      if is_sudo(user_id) then
        -- add a user to sudoer
        if matches[1] == 'visudo' then
          if matches[2] == 'add' then
            local uid = tonumber(matches[3])
            _config.sudo_users[uid] =
            save_config()
            reply_msg(msg.id, uid..' added to sudo users list.', ok_cb, true)
          end
          if matches[2] == 'del' then
            local uid = tonumber(matches[3])
            _config.sudo_users[uid] = nil
            save_config()
            reply_msg(msg.id, uid..' deleted from sudo users list.', ok_cb, true)
          end
          if matches[2] == 'list' then
            local sudoers = 'Sudo users for this bot are:\n\n'
            n=1
            for k,v in pairs(_config.sudo_users) do
              sudoers = sudoers..n..'. '..k..' - '..v..'\n'
              n=n+1
            end
            reply_msg(msg.id, sudoers, ok_cb, true)
          end
        end
        -- add a group to be moderated
        if matches[1] == 'addgroup' or matches[1] == 'gadd' then
          add_group(msg, chat_id, user_id)
          resolve_username(_config.bot_api.uname, resolve_username_cb, {msg=msg, matches=matches})
        end

        if matches[1] == 'autoleave' then
          if matches[2] == 'enable' then
            _config.autoleave = true
            if not _config.autoleave then
              _config.autoleave = true
            end
            if _config.autoleave == true then
              reply_msg(msg.id, 'Autoleave is not disabled.', ok_cb, true)
            end
            save_config()
            reply_msg(msg.id, 'Autoleave re-enabled.', ok_cb, true)
          end
          if matches[2] == 'disable' then
            if not _config.autoleave then
              _config.autoleave = false
            end
            _config.autoleave = false
            save_config()
            reply_msg(msg.id, 'Autoleave disabled.', ok_cb, true)
          end
        end

        -- remove group from administration
        if matches[1] == 'remgroup' or matches[1] == 'grem' or matches[1] == 'gremove' then
          remove_group(msg, chat_id)
        end

        if matches[1] == 'visudo' or matches[1] == 'sudo' then
          if msg.reply_id then
            get_message(msg.reply_id, action_by_reply, msg)
          elseif matches[2] == '@' then
            resolve_username(matches[3], resolve_username_cb, {msg=msg, matches=matches})
          elseif matches[3]:match('^%d+$') then
            group_info_by_id({msg=msg, matches=matches}, chat_id, matches[3])
          end
        end

        if matches[1] == 'desudo' then
          if msg.reply_id then
            get_message(msg.reply_id, action_by_reply, msg)
          elseif matches[2] == '@' then
            resolve_username(matches[3], resolve_username_cb, {msg=msg, matches=matches})
          elseif matches[3]:match('^%d+$') then
            group_info_by_id({msg=msg, matches=matches}, chat_id, matches[3])
          end
        end

        if matches[1] == 'sudolist' then
          get_sudolist(msg)
        end

        if matches[1] == 'adminprom' or matches[1] == 'admin' then
          if msg.reply_id then
            get_message(msg.reply_id, action_by_reply, msg)
          elseif matches[2] == '@' then
            resolve_username(matches[3], resolve_username_cb, {msg=msg, matches=matches})
          elseif matches[3]:match('^%d+$') then
            group_info_by_id({msg=msg, matches=matches}, chat_id, matches[3])
          end
        end

        if matches[1] == 'admindem' or matches[1] == 'deadmin' then
          if msg.reply_id then
            get_message(msg.reply_id, action_by_reply, msg)
          elseif matches[2] == '@' then
            resolve_username(matches[3], resolve_username_cb, {msg=msg, matches=matches})
          elseif matches[3]:match('^%d+$') then
            group_info_by_id({msg=msg, matches=matches}, chat_id, matches[3])
          end
        end
      end

      if is_admin(user_id) then
        --[[
        TODO Not yet tested, because unfortunatelly, Telegram restrict how
        much you can create create a group in a period of time.
        If this limit is reached, than you have to wait for a days or weeks.
        So, I have diffculty to test it right in one shot.
        --]]
--        if matches[1] == 'mksupergroup' and matches[2] then
--          local uname = '@'..msg.from.username or msg.from.first_name
--          new_group_table[matches[2]] = {uid = tostring(user_id), title = matches[2], uname = uname, gtype = 'supergroup'}
--          create_group_chat(msg.from.print_name, matches[2], ok_cb, false)
--          reply_msg(msg.id, 'Supergroup '..matches[2]..' has been created.', ok_cb, true)
--        end
--
--        if matches[1] == 'mkgroup' and matches[2] then
--          local uname = '@'..msg.from.username or msg.from.first_name
--          new_group_table[user_id] = {uid = user_id, title = matches[2], uname = uname}
--          create_group_chat(msg.from.print_name, matches[2], ok_cb, false)
--          reply_msg(msg.id, 'Group '..matches[2]..' has been created.', ok_cb, true)
--        end

        if matches[1] == 'setowner' or matches[1] == 'gov' then
          if msg.reply_id then
            get_message(msg.reply_id, action_by_reply, msg)
          elseif matches[2] == '@' then
            resolve_username(matches[3], resolve_username_cb, {msg=msg, matches=matches})
          elseif matches[3]:match('^%d+$') then
            group_info_by_id({msg=msg, matches=matches}, chat_id, matches[3])
          end
        end

        if matches[1] == 'remowner' or matches[1] == 'degov' then
          if msg.reply_id then
            get_message(msg.reply_id, action_by_reply, msg)
          elseif matches[2] == '@' then
            resolve_username(matches[3], resolve_username_cb, {msg=msg, matches=matches})
          elseif matches[3]:match('^%d+$') then
            group_info_by_id({msg=msg, matches=matches}, chat_id, matches[3])
          end
        end

        if matches[1] == 'adminlist' then
          get_adminlist(msg, chat_id)
        end

        if matches[1] == 'ownerlist' then
          get_ownerlist(msg, chat_id)
        end

        if matches[1] == 'channel' then
          if matches[2] == 'enable' then
            if not _config.disabled_channels then
              _config.disabled_channels = {}
            end
            if _config.disabled_channels[receiver] == nil then
              reply_msg(msg.id, 'Channel is not disabled', ok_cb, true)
            end
            _config.disabled_channels[receiver] = false
            save_config()
            reply_msg(msg.id, 'Channel re-enabled', ok_cb, true)
          end

          -- Disable a channel
          if matches[2] == 'disable' then
            if not _config.disabled_channels then
              _config.disabled_channels = {}
            end
            _config.disabled_channels[receiver] = true
            save_config()
            reply_msg(msg.id, 'Channel disabled.', ok_cb, true)
          end
        end

        if matches[1] == 'superban' or matches[1] == 'gban' or matches[1] == 'hammer' then
          if msg.reply_id then
            get_message(msg.reply_id, action_by_reply, msg)
          elseif matches[2] == '@' then
            resolve_username(matches[3], resolve_username_cb, {msg=msg, matches=matches})
          elseif matches[3]:match('^%d+$') then
            group_info_by_id({msg=msg, matches=matches}, chat_id, matches[3])
          end
        end

        if matches[1] == 'superunban' or matches[1] == 'gunban' or matches[1] == 'unhammer' then
          if msg.reply_id then
            get_message(msg.reply_id, action_by_reply, msg)
          elseif matches[2] == '@' then
            resolve_username(matches[3], resolve_username_cb, {msg=msg, matches=matches})
          elseif matches[3]:match('^%d+$') then
            group_info_by_id({msg=msg, matches=matches}, chat_id, matches[3])
          end
        end

        if matches[1] == 'whitelist' then
          if msg.reply_id then
            get_message(msg.reply_id, action_by_reply, msg)
          elseif matches[2] == 'enable' then
            redis:set('whitelist:enabled', true)
            reply_msg(msg.id, 'Enabled whitelist', ok_cb, true)
          elseif matches[2] == 'disable' then
            redis:del('whitelist:enabled')
            reply_msg(msg.id, 'Disabled whitelist', ok_cb, true)
          elseif matches[2] == 'clear' then
            local hash =  'whitelist'
            redis:del(hash)
            return "Whitelist cleared."
          elseif matches[2] == 'chat' then
            redis:sadd('whitelist', chat_id)
            reply_msg(msg.id, 'Chat '..chat_id..' whitelisted', ok_cb, true)
          end
        end

        if matches[1] == 'unwhitelist' then
          if msg.reply_id then
            get_message(msg.reply_id, action_by_reply, msg)
          elseif matches[2] == 'chat' then
            redis:srem('whitelist', chat_id)
            reply_msg(msg.id, 'Chat '..chat_id..' removed from whitelist', ok_cb, true)
          end
        end
      end

      if not _config.administration[chat_id] then return end

      local data = load_data(_config.administration[chat_id])

      if is_owner(msg, chat_id, user_id) then
        if matches[1] == 'antispam' then
          if matches[2] == 'kick' then
            if data.antispam ~= 'kick' then
              data.antispam = 'kick'
              save_data(data, chat_db)
            end
              reply_msg(msg.id, 'Anti spam protection already enabled.\nOffender will be kicked.', ok_cb, true)
            end
          if matches[2] == 'ban' then
            if data.antispam ~= 'ban' then
              data.antispam = 'ban'
              save_data(data, chat_db)
            end
              reply_msg(msg.id, 'Anti spam protection already enabled.\nOffender will be banned.', ok_cb, true)
            end
          if matches[2] == 'disable' then
            if data.antispam == 'no' then
              reply_msg(msg.id, 'Anti spam protection is not enabled.', ok_cb, true)
            else
              data.antispam = 'no'
              save_data(data, chat_db)
              reply_msg(msg.id, 'Anti spam protection has been disabled.', ok_cb, true)
            end
          end
        end

        if matches[1] == 'whitelist' then
          if msg.reply_id then
            get_message(msg.reply_id, action_by_reply, msg)
          elseif matches[2] == '@' then
            resolve_username(matches[3], resolve_username_cb, {msg=msg, matches=matches})
          elseif matches[3] and matches[3]:match('^%d+$') then
            group_info_by_id({msg=msg, matches=matches}, chat_id, matches[3])
          end
        end

        if matches[1] == 'unwhitelist' then
          if msg.reply_id then
            get_message(msg.reply_id, action_by_reply, msg)
          elseif matches[2] == '@' then
            resolve_username(matches[3], resolve_username_cb, {msg=msg, matches=matches})
          elseif matches[3]:match('^%d+$') then
            group_info_by_id({msg=msg, matches=matches}, chat_id, matches[3])
          end
        end

        if matches[1] == 'setlink' or matches[1] == 'link set' then
          set_group_link({msg=msg, gid=chat_id}, chat_db)
        end

        if matches[1] == 'link revoke' then
          if data.link == '' then
            reply_msg(msg.id, 'This group don\'t have invite link', ok_cb, true)
          else
            set_group_link({msg=msg, gid=chat_id}, chat_db, 'revoke')
            reply_msg(msg.id, 'Invite link has been revoked', ok_cb, true)
          end
        end

        if matches[1] == 'setname' then
          data.name = matches[2]
          save_data(data, chat_db)
          if msg.to.peer_type == 'channel' then
            rename_channel(receiver, data.name, ok_cb, true)
          else
            rename_chat(receiver, data.name, ok_cb, true)
          end
        end

        if matches[1] == 'setphoto' then
          data.set.photo = 'waiting'
          save_data(data, chat_db)
          reply_msg(msg.id, 'Please send me new group photo now', ok_cb, true)
        end

        if matches[1] == 'sticker' then
          if matches[2] == 'warn' then
            if data.sticker ~= 'warn' then
              data.sticker = 'warn'
              save_data(data, chat_db)
            end
            reply_msg(msg.id, 'Stickers already prohibited.\nSender will be warned first, then kicked for second violation.', ok_cb, true)
          end
          if matches[2] == 'kick' then
            if data.sticker ~= 'kick' then
              data.sticker = 'kick'
              save_data(data, chat_db)
            end
            reply_msg(msg.id, 'Stickers already prohibited.\nSender will be kicked!', ok_cb, true)
          end
          if matches[2] == 'ok' then
            if data.sticker == 'ok' then
              reply_msg(msg.id, 'Sticker restriction is not enabled.', ok_cb, true)
            else
              data.sticker = 'ok'
              save_data(data, chat_db)
              for k,sticker_hash in pairs(redis:keys('mer_sticker:'..chat_id..':*')) do
                redis:del(sticker_hash)
              end
              reply_msg(msg.id, 'Sticker restriction has been disabled.\nPrevious infringements record has been cleared.', ok_cb, true)
            end
          end
        end

        if matches[1] == 'setwelcome' and matches[2] then
          data.welcome.msg = matches[2]
          save_data(data, chat_db)
          reply_msg(msg.id, 'Set group welcome message to:\n'..matches[2], ok_cb, true)
        end

        if matches[1] == 'welcome' then
          if matches[2] == 'group' and data.welcome.to ~= 'group' then
            data.welcome.to = 'group'
            save_data(data, chat_db)
            reply_msg(msg.id, 'Welcome service already enabled.\nWelcome message will shown in group.', ok_cb, true)
          end
          if matches[2] == 'pm' and data.welcome.to ~= 'private' then
            data.welcome.to = 'private'
            save_data(data, chat_db)
            reply_msg(msg.id, 'Welcome service already enabled.\nWelcome message will send as private message to new member.', ok_cb, true)
          end
          if matches[2] == 'disable' then
            if data.welcome.to == 'no' then
              reply_msg(msg.id, 'Welcome service is not enabled.', ok_cb, true)
            else
              data.welcome.to = 'no'
              save_data(data, chat_db)
              reply_msg(msg.id, 'Welcome service has been disabled.', ok_cb, true)
            end
          end
        end

        if matches[1] == 'setabout' and matches[2] then
          data.description = matches[2]
          save_data(data, chat_db)
          reply_msg(msg.id, 'Set group description to:\n'..matches[2], ok_cb, true)
        end

        if matches[1] == 'setrules' and matches[2] then
          data.rules = matches[2]
          save_data(data, chat_db)
          reply_msg(msg.id, 'Set group rules to:\n'..matches[2], ok_cb, true)
        end

        if matches[1] == 'group' or matches[1] == 'gp' then
          -- lock {bot|name|member|photo|sticker}
          if matches[2] == 'lock' then
            if matches[3] == 'bot' then
              if data.lock.bot == 'yes' then
                reply_msg(msg.id, 'Group is already locked from bots.', ok_cb, true)
              else
                data.lock.bot = 'yes'
                save_data(data, chat_db)
                reply_msg(msg.id, 'Group is locked from bots.', ok_cb, true)
              end
            end
            if matches[3] == 'name' then
              if data.lock.name == 'yes' then
                reply_msg(msg.id, 'Group name is already locked', ok_cb, true)
              else
                data.lock.name = 'yes'
                save_data(data, chat_db)
                data.set.name = msg.to.title
                save_data(data, chat_db)
                reply_msg(msg.id, 'Group name has been locked', ok_cb, true)
              end
            end
            if matches[3] == 'member' then
              if data.lock.member == 'yes' then
                reply_msg(msg.id, 'Group members are already locked', ok_cb, true)
              else
                data.lock.member = 'yes'
                save_data(data, chat_db)
              end
              reply_msg(msg.id, 'Group members has been locked', ok_cb, true)
            end
            if matches[3] == 'photo' then
              if data.lock.photo == 'yes' then
                reply_msg(msg.id, 'Group photo is already locked', ok_cb, true)
              else
                data.set.photo = 'waiting'
                save_data(data, chat_db)
              end
              reply_msg(msg.id, 'Please send me the group photo now', ok_cb, true)
            end
          end
          -- unlock {bot|name|member|photo|sticker}
          if matches[2] == 'unlock' then
            if matches[3] == 'bot' then
              if data.lock.bot == 'no' then
                reply_msg(msg.id, 'Bots are allowed to enter group.', ok_cb, true)
              else
                data.lock.bot = 'no'
                save_data(data, chat_db)
                reply_msg(msg.id, 'Group is open for bots.', ok_cb, true)
              end
            end
            if matches[3] == 'name' then
              if data.lock.name == 'no' then
                reply_msg(msg.id, 'Group name is already unlocked', ok_cb, true)
              else
                data.lock.name = 'no'
                save_data(data, chat_db)
                reply_msg(msg.id, 'Group name has been unlocked', ok_cb, true)
              end
            end
            if matches[3] == 'member' then
              if data.lock.member == 'no' then
                reply_msg(msg.id, 'Group members are not locked', ok_cb, true)
              else
                data.lock.member = 'no'
                save_data(data, chat_db)
                reply_msg(msg.id, 'Group members has been unlocked', ok_cb, true)
              end
            end
            if matches[3] == 'photo' then
              if data.lock.photo == 'no' then
                reply_msg(msg.id, 'Group photo is not locked', ok_cb, true)
              else
                data.lock.photo = 'no'
                save_data(data, chat_db)
                reply_msg(msg.id, 'Group photo has been unlocked', ok_cb, true)
              end
            end
          end
        end
      end

      if is_mod(msg, chat_id, user_id) then
        -- view group settings
        if matches[1] == 'group' and matches[2] == 'settings' then
          local text = 'Settings for *'..msg.to.title..'*\n'
                ..'*-* Lock group from bot = `'..data.lock.bot..'`\n'
                ..'*-* Lock group name = `'..data.lock.name..'`\n'
                ..'*-* Lock group photo = `'..data.lock.photo..'`\n'
                ..'*-* Lock group member = `'..data.lock.member..'`\n'
                ..'*-* Spam protection = `'..data.antispam..'`\n'
                ..'*-* Sticker policy = `'..data.sticker..'`\n'
                ..'*-* Welcome message = `'..data.welcome.to..'`\n'
          send_api_msg(msg, msg, get_receiver_api(msg), text, true, 'md')
        end

        if matches[1] == 'invite' then
          if msg.reply_id then
            get_message(msg.reply_id, action_by_reply, msg)
          elseif matches[2] == '@' then
            resolve_username(matches[3], resolve_username_cb, {msg=msg, matches=matches})
          elseif matches[3]:match('%d+$') then
            invite_user(msg, chat_id, matches[3])
          else
            -- Invite user by their print name. Unreliable.
            if msg.to.peer_type == 'channel' then
              channel_invite_user(receiver, matches[3]:gsub(' ', '_'), ok_cb, false)
            else
              chat_add_user(receiver, matches[3]:gsub(' ', '_'), ok_cb, false)
            end
          end
        end

        if matches[1] == 'kick' then
          if msg.reply_id then
            get_message(msg.reply_id, action_by_reply, msg)
          elseif matches[2] == '@' then
            resolve_username(matches[3], resolve_username_cb, {msg=msg, matches=matches})
          elseif matches[3]:match('^%d+$') then
            group_info_by_id({msg=msg, matches=matches}, chat_id, matches[3])
          end
        end
        if matches[1] == 'ban' then
          if msg.reply_id then
            get_message(msg.reply_id, action_by_reply, msg)
          elseif matches[2] == '@' then
            resolve_username(matches[3], resolve_username_cb, {msg=msg, matches=matches})
          elseif matches[3] and matches[3]:match('^%d+$') then
            group_info_by_id({msg=msg, matches=matches}, chat_id, matches[3])
          end
        end

        if matches[1] == 'banlist' then
          local hash =  'banned:'..chat_id
          local list = redis:smembers(hash)
          local text = "Ban list!\n\n"
          for k,v in pairs(list) do
            text = text..k.." - "..v.."\n"
          end
          return text
        end

        -- Returns globally ban list
        if matches[1] == 'superbanlist' or matches[1] == 'gbanlist' or matches[1] == 'hammerlist' then
          local hash =  'globanned'
          local list = redis:smembers(hash)
          local text = "Global bans!\n\n"
          for k,v in pairs(list) do
            text = text..k.." - "..v.."\n"
          end
          return text
        end

        if matches[1] == 'unban' then
          if msg.reply_id then
            get_message(msg.reply_id, action_by_reply, msg)
          elseif matches[2] == '@' then
            resolve_username(matches[3], resolve_username_cb, {msg=msg, matches=matches})
          elseif matches[3]:match('^%d+$') then
            group_info_by_id({msg=msg, matches=matches}, chat_id, matches[3])
          end
        end

        if matches[1] == 'promote' or matches[1] == 'mod' then
          if msg.reply_id then
            get_message(msg.reply_id, action_by_reply, msg)
          elseif matches[2] == '@' then
            resolve_username(matches[3], resolve_username_cb, {msg=msg, matches=matches})
          elseif matches[3]:match('^%d+$') then
            group_info_by_id({msg=msg, matches=matches}, chat_id, matches[3])
          end
        end
        if matches[1] == 'demote' or matches[1] == 'demod' then
          if msg.reply_id then
            get_message(msg.reply_id, action_by_reply, msg)
          elseif matches[2] == '@' then
            resolve_username(matches[3], resolve_username_cb, {msg=msg, matches=matches})
          elseif matches[3]:match('^%d+$') then
            group_info_by_id({msg=msg, matches=matches}, chat_id, matches[3])
          end
        end
        if matches[1] == 'modlist' then
          if not _config.administration[chat_id] then
            reply_msg(msg.id, 'I do not administrate this group.', ok_cb, true)
            return
          end
          -- determine if table is empty
          if next(data.moderators) == nil then
            reply_msg(msg.id, 'There are currently no listed moderators.', ok_cb, true)
          else
            local message = 'Moderators for '..msg.to.title..':\n\n'
            local mod = data.moderators
            for k,v in pairs(data.moderators) do
              message = message..'- '..v..' ['..k..'] \n'
            end
            reply_msg(msg.id, message, ok_cb, true)
          end
        end
      end

      if matches[1] == 'kickme' or matches[1] == 'leave' then
        if msg.to.peer_type == 'channel' then
          reply_msg(msg.id, 'Leave this group manually or you will be unable to rejoin.', ok_cb, true)
        else
          kick_user(msg, chat_id, user_id)
        end
      end

      if matches[1] == 'link' or matches[1] == 'getlink' or matches[1] == 'link get' then
        if data.link == '' then
          send_api_msg(msg, get_receiver_api(msg), 'No link has been set for this group.\nTry <code>!link set</code> to generate.', true, 'html')
        elseif data.link == 'revoked' then
          reply_msg(msg.id, 'Invite link for this group has been revoked', ok_cb, true)
        else
          local about = data.description or ''
          local link = data.link
          send_api_msg(msg, get_receiver_api(msg), '<b>'..msg.to.title..'</b>\n\n'..about..link, true, 'html')
        end
      end

      if matches[1] == 'about' then
        if not data.description then
          reply_msg(msg.id, 'No description available', ok_cb, true)
        else
          send_api_msg(msg, get_receiver_api(msg), '<b>'..msg.to.title..'</b>\n\n'..data.description, true, 'html')
        end
      end

      if matches[1] == 'rules' then
        if not data.rules then
          reply_msg(msg.id, 'No rules have been set for '..msg.to.title..'.', ok_cb, true)
        else
          local rules = data.rules
          local rules = msg.to.print_name..' rules:\n\n'..rules
          reply_msg(msg.id, rules, ok_cb, true)
        end
      end

      if matches[1] == 'grouplist' or matches[1] == 'groups' or matches[1] == 'glist' then
        local gplist = ''
        for k,v in pairs(_config.administration) do
          local gpdata = load_data(v)
          if gpdata.link then
            gplist = gplist..'• ['..gpdata.name..']('..gpdata.link..')'
          else
            gplist = gplist..'• '..gpdata.name..'\n'
          end
        end
        if gplist == '' then
          gplist = 'There are currently no listed groups.'
        else
          gplist = '*Groups:*\n' .. gplist
        end
        send_api_msg(msg, get_receiver_api(msg), gplist, true, 'md')
      end

    else -- if private message

      local usr = '@'..msg.from.username or msg.from.first_name

      if is_sudo(user_id) then
        --TODO get_members_list an set_group_link not working in private message
--        if matches[1] == 'addgroup' or matches[1] == 'gadd' then
--          add_group(msg, matches[2], user_id)
--        end

        if matches[1] == 'remgroup' or matches[1] == 'grem' or matches[1] == 'gremove' then
          remove_group(msg, matches[2])
        end

        if matches[1] == 'adminprom' or matches[1] == 'admin' then
          if matches[2] == '@' then
            resolve_username(matches[3], resolve_username_cb, {msg=msg, matches=matches})
          elseif matches[3]:match('^%d+$') then
            promote_admin({msg=msg, usr=usr}, matches[4])
          end
        end

        if matches[1] == 'admindem' or matches[1] == 'deadmin' then
          if matches[2] == '@' then
            resolve_username(matches[3], resolve_username_cb, {msg=msg, matches=matches})
          elseif matches[3]:match('^%d+$') then
            demote_admin({msg=msg, usr=usr}, matches[4])
          end
        end
      end

      if is_admin(user_id) then
        if matches[1] == 'setowner' or matches[1] == 'gov' then
          if matches[2] == '@' then
            resolve_username(matches[3], resolve_username_cb, {msg=msg, matches=matches})
          elseif matches[3]:match('^%d+$') then
            promote_owner({msg=msg, usr=usr}, matches[4], matches[3])
          end
        end

        if matches[1] == 'remowner' or matches[1] == 'degov' then
          if matches[2] == '@' then
            resolve_username(matches[3], resolve_username_cb, {msg=msg, matches=matches})
          elseif matches[3]:match('^%d+$') then
            demote_owner({msg=msg, usr=usr}, matches[4], matches[3])
          end
        end

        if matches[1] == 'promote' or matches[1] == 'mod' then
          if matches[2] == '@' then
            resolve_username(matches[3], resolve_username_cb, {msg=msg, matches=matches})
          elseif matches[3]:match('^%d+$') then
            promote_owner({msg=msg, usr=usr}, matches[4], matches[3])
          end
        end

        if matches[1] == 'demote' or matches[1] == 'demod' then
          if matches[2] == '@' then
            resolve_username(matches[3], resolve_username_cb, {msg=msg, matches=matches})
          elseif matches[3]:match('^%d+$') then
            demote_owner({msg=msg, usr=usr}, matches[4], matches[3])
          end
        end

        if matches[1] == 'adminlist' then
          get_adminlist(msg, matches[2])
        end

        if matches[1] == 'ownerlist' then
          get_ownerlist(msg, matches[2])
        end

        if matches[1] == 'superban' or matches[1] == 'gban' or matches[1] == 'hammer' then
          if matches[2] == '@' then
            resolve_username(matches[3], resolve_username_cb, {msg=msg, matches=matches})
          elseif matches[3]:match('^%d+$') then
            global_ban_user({msg=msg, usr=usr}, matches[3])
          end
        end

        if matches[1] == 'superunban' or matches[1] == 'gunban' or matches[1] == 'unhammer' then
          if matches[2] == '@' then
            resolve_username(matches[3], resolve_username_cb, {msg=msg, matches=matches})
          elseif matches[3]:match('^%d+$') then
            global_unban_user({msg=msg, usr=usr}, matches[3])
          end
        end

        if matches[1] == 'whitelist' then
          if matches[2] == 'chat' then
            redis:sadd('whitelist', matches[3])
            reply_msg(msg.id, 'Chat '..matches[3]..' whitelisted', ok_cb, true)
          end
        end

        if matches[1] == 'unwhitelist' then
          if matches[2] == 'chat' then
            redis:srem('whitelist', matches[3])
            reply_msg(msg.id, 'Chat '..matches[3]..' removed from whitelist', ok_cb, true)
          end
        end

        if matches[1] == 'kick' then
          if matches[2] == '@' then
            resolve_username(matches[3], resolve_username_cb, {msg=msg, matches=matches})
          elseif matches[3]:match('^%d+$') then
            kick_user(msg, matches[4], matches[3])
          end
        end
      end
    end

  end -- main function end here



  return {
    run = run,
    pre_process = pre_process,
    description = 'Administration plugin.',
    patterns = {
      '^!(about)$',
      '^!(sudolist)$',
      '^!(adminlist)$', '^!(adminlist) (%d+)$',
      '^!(antispam) (%a+)$',
      '^!(autoleave) (%a+)$',
      '^!(banlist)$',
      '^!(channel) (%a+)$',
      '^!(kickme)$',
      '^!(leave)$',
      '^!(leaveall)$',
      '^!(link revoke)$',
      '^!(mkgroup) (.*)$',
      '^!(mksupergroup) (.*)$',
      '^!(grouplist)$', '^!(gplist)$', '^!(glist)$',
      '^!(modlist)$',
      '^!(ownerlist)$', '^!(ownerlist) (%d+)$',
      '^!(rules)$',
      '^!(setabout) (.*)$',
      '^!(setname) (.*)$',
      '^!(setphoto)$',
      '^!(setrules) (.*)$',
      '^!(sticker) (%a+)$',
      '^!(welcome) (%a+)$',
      '^!(setwelcome) (.*)$',
      '^!(whitelist) (%a+)$',
      '^!(whitelist) (chat) (%d+)$',
      '^!(unwhitelist) (chat) (%d+)$',
      '^!(superbanlist)$', '^!(gbanlist)$', '^!(hammerlist)$',
      '^!(whitelist)$', '^!(whitelist) (@)(%a+)$', '^!(whitelist)(%s)(%d+)$',
      '^!(unwhitelist)$', '^!(unwhitelist) (%a+)$', '^!(unwhitelist) (@)(%a+)$', '^!(unwhitelist)(%s)(%d+)$',
      '^!(addgroup)$', '^!(gadd)$', '^!(addgroup) (%d+)$', '^!(gadd) (%d+)$',
      '^!(visudo)$', '^!(visudo) (@)(%a+)$', '^!(visudo)(%s)(%d+)$', '^!(visudo) (@)(%a+) (%d+)$', '^!(visudo)(%s)(%d+) (%d+)$',
      '^!(sudo)$', '^!(sudo) (@)(%a+)$', '^!(sudo)(%s)(%d+)$', '^!(sudo) (@)(%a+) (%d+)$', '^!(sudo)(%s)(%d+) (%d+)$',
      '^!(desudo)$', '^!(desudo) (@)(%a+)$', '^!(desudo)(%s)(%d+)$', '^!(desudo) (@)(%a+) (%d+)$', '^!(desudo)(%s)(%d+) (%d+)$',
      '^!(admin)$', '^!(admin) (@)(%a+)$', '^!(admin)(%s)(%d+)$', '^!(admin) (@)(%a+) (%d+)$', '^!(admin)(%s)(%d+) (%d+)$',
      '^!(adminprom)$', '^!(adminprom) (@)(%a+)$', '^!(adminprom)(%s)(%d+)$', '^!(adminprom) (@)(%a+) (%d+)$', '^!(adminprom)(%s)(%d+) (%d+)$',
      '^!(ban)$', '^!(ban) (@)(%a+)$', '^!(ban)(%s)(%d+)$', '^!(ban) (%w+)(%s)(%d+)$',
      '^!(deadmin)$', '^!(deadmin) (@)(%a+)$', '^!(deadmin)(%s)(%d+)$', '^!(deadmin) (@)(%a+) (%d+)$', '^!(deadmin)(%s)(%d+) (%d+)$',
      '^!(admindem)$', '^!(admindem) (@)(%a+)$', '^!(admindem)(%s)(%d+)$', '^!(admindem) (@)(%a+) (%d+)$', '^!(admindem)(%s)(%d+) (%d+)$',
      '^!(demote)$', '^!(demote) (@)(%a+)$', '^!(demote)(%s)(%d+)$',
      '^!(demod)$', '^!(demod) (@)(%a+)$', '^!(demod)(%s)(%d+)$',
      '^!(grem)$', '^!(grem) (%d+)$', '^!(gremove)$', '^!(gremove) (%d+)$', '^!(remgroup)$', '^!(remgroup) (%d+)$',
      '^!(group) (lock) (%a+)$', '^!(gp) (lock) (%a+)$',
      '^!(group) (settings)$', '^!(gp) (settings)$',
      '^!(group) (unlock) (%a+)$', '^!(gp) (unlock) (%a+)$',
      '^!(invite)$', '^!(invite) (@)(%a+)$', '^!(invite)(%s)(%g+)$',
      '^!(kick)$', '^!(kick) (@)(%a+)$', '^!(kick)(%s)(%d+)$', '^!(kick) (%d+) (%d+)$', '^!(kick) (@)(%a+) (%d+)$', '^!(kick)(%s)(%d+) (%d+)$',
      '^!(link)$', '^!(link get)$', '^!(getlink)$',
      '^!(link set)$', '^!(setlink)$',
      '^!(setowner)$', '^!(setowner) (@)(%a+)$', '^!(setowner)(%s)(%d+)$', '^!(setowner) (@)(%a+) (%d+)$', '^!(setowner)(%s)(%d+) (%d+)$',
      '^!(gov)$', '^!(gov) (@)(%a+)$', '^!(gov)(%s)(%d+)$', '^!(gov) (@)(%a+) (%d+)$', '^!(gov)(%s)(%d+) (%d+)$',
      '^!(degov)$', '^!(degov) (@)(%a+)$', '^!(degov)(%s)(%d+)$', '^!(degov) (@)(%a+) (%d+)$', '^!(degov)(%s)(%d+) (%d+)$',
      '^!(remowner)$', '^!(remowner) (@)(%a+)$', '^!(remowner)(%s)(%d+)$', '^!(remowner) (@)(%a+) (%d+)$', '^!(remowner)(%s)(%d+) (%d+)$',
      '^!(mod)$', '^!(mod) (@)(%a+)$', '^!(mod)(%s)(%d+)$', '^!(mod) (@)(%a+) (%d+)$', '^!(mod)(%s)(%d+) (%d+)$',
      '^!(promote)$', '^!(promote) (@)(%a+)$', '^!(promote)(%s)(%d+)$', '^!(promote) (@)(%a+) (%d+)$', '^!(promote)(%s)(%d+) (%d+)$',
      '^!(superban)$', '^!(superban) (@)(%a+)$', '^!(superban)(%s)(%d+)$', '^!(superban) (@)(%a+) (%d+)$', '^!(superban)(%s)(%d+) (%d+)$',
      '^!(hammer)$', '^!(hammer) (@)(%a+)$', '^!(hammer)(%s)(%d+)$', '^!(hammer) (@)(%a+) (%d+)$', '^!(hammer)(%s)(%d+) (%d+)$',
      '^!(gban)$', '^!(gban) (@)(%a+)$', '^!(gban)(%s)(%d+)$', '^!(gban)(%s)(%d+) (%d+)$', '^!(gban) (@)(%a+) (%d+)$',
      '^!(superunban)$', '^!(superunban) (@)(%a+)$', '^!(superunban)(%s)(%d+)$', '^!(superunban) (@)(%a+) (%d+)$', '^!(superunban)(%s)(%d+) (%d+)$',
      '^!(unhammer)$', '^!(unhammer) (@)(%a+)$', '^!(unhammer)(%s)(%d+)$', '^!(unhammer) (@)(%a+) (%d+)$', '^!(unhammer)(%s)(%d+) (%d+)$',
      '^!(gunban)$', '^!(gunban) (@)(%a+)$', '^!(gunban)(%s)(%d+)$', '^!(gunban) (@)(%a+) (%d+)$', '^!(gunban)(%s)(%d+) (%d+)$',
      '^!(unban)$', '^!(unban) (@)(%a+)$', '^!(unban)(%s)(%d+)$', '^!(unban) (%w+) (%d+)$',
      '%[(audio)%]',
      '%[(document)%]',
      '%[(photo)%]',
      '%[(video)%]',
      '^!!tgservice (.+)$',
    },
    usage = {
      sudo = {
        '<code>!autoleave enable</code>',
        'Enable autoleave. Bot will exit from unmanaged groups.',
        '<code>!autoleave disable</code>',
        'Disable autoleave.',
        '<code>!leave</code>',
        'Exit from this group.',
        '<code>!leaveall</code>',
        'Exit from all unmanaged groups.',
        '<code>!visudo</code>',
        '<code>!sudo</code>',
        'If typed when replying, promote replied user as sudoer.',
        '<code>!visudo [user_id]</code>',
        '<code>!sudo [user_id]</code>',
        'Promote user_id as sudoer.',
        '<code>!visudo @[username]</code>',
        '<code>!sudo @[username]</code>',
        'Promote username as sudoer.',
        '<code>!desudo</code>',
        'If typed when replying, demote replied user from sudoer.',
        '<code>!desudo [user_id]</code>',
        'Demote user_id from sudoer.',
        '<code>!desudo @[username]</code>',
        'Demote username from sudoer.',
        '<code>!adminprom</code>',
        '<code>!admin</code>',
        'If typed when replying, promote replied user as admin.',
        '<code>!adminprom [user_id]</code>',
        '<code>!admin [user_id]</code>',
        'Promote user_id as admin.',
        '<code>!adminprom @[username]</code>',
        '<code>!admin @[username]</code>',
        'Promote username as admin.',
        '<code>!admindem</code>',
        '<code>!deadmin</code>',
        'If typed when replying, demote replied user from admin.',
        '<code>!admindem [user_id]</code>',
        '<code>!deadmin [user_id]</code>',
        'Demote user_id from admin.',
        '<code>!admindem @[username]</code>',
        '<code>!deadmin @[username]</code>',
        'Demote username from admin.',
        '<code>!sudolist</code>',
        'List of sudoers',
      },
      admin = {
        '<code>!mkgroup [group_name]</code>',
        'Make/create a new group.',
        '<code>!mksupergroup [group_name]</code>',
        'Make/create a new supergroup.',
        '<code>!invite [user_id] [chat_id]</code>',
        'Invite <code>user_id</code> to <code>chat_id</code>.',
        '<code>!invite [@username] [chat_id]</code>',
        'Invite <code>username</code> to <code>chat_id</code>.',
        '<code>!invite [print_name] [chat_id]</code>',
        'Invite <code>print_name</code> to <code>chat_id</code>.',
        '<code>!superban</code>',
        '<code>!hammer</code>',
        '<code>!gban</code>',
        'If type in reply, will ban user globally.',
        '<code>!superban [user_id]/@[username]</code>',
        '<code>!hammer [user_id]/@[username]</code>',
        '<code>!gban [user_id]/@[username]</code>',
        'Kick user_id/username from all chat and kicks it if joins again',
        '<code>!superunban</code>',
        '<code>!unhammer</code>',
        '<code>!gunban</code>',
        'If type in reply, will unban user globally.',
        '<code>!superunban [user_id]/@[username]</code>',
        '<code>!unhammer [user_id]/@[username]</code>',
        '<code>!gunban [user_id]/@[username]</code>',
        'Unban user_id/username globally.',
        '<code>!addgroup</code>',
        '<code>!gadd</code>',
        'Add group to administration list.',
        '<code>!channel enable</code>',
        'enable current channel',
        '<code>!channel disable</code>',
        'disable current channel',
        '<code>!remgroup</code>',
        '<code>!grem</code>',
        '<code>!gremove</code>',
        'Remove group from administration list.',
        '<code>!whitelist [enable]/[disable]</code>',
        'Enable or disable whitelist mode',
        '<code>!whitelist</code>',
        'If type in reply, allow user to use the bot when whitelist mode is enabled',
        '<code>!unwhitelist</code>',
        'If type in reply, remove user from whitelist',
        '<code>!whitelist chat</code>',
        'Allow everybody on current chat to use the bot when whitelist mode is enabled',
        '<code>!unwhitelist chat</code>',
        'Remove chat from whitelist',
        '<code>!whitelist [user_id]/@[username]</code>',
        'Allow user to use the bot when whitelist mode is enabled',
        '<code>!unwhitelist [user_id]/@[username]</code>',
        'Remove user from whitelist',
        '<code>!adminlist</code>',
        'List of administrators',
        '<code>!ownerlist</code>',
        'List of owners',
      },
      owner = {
        '<code>!group lock bot</code>',
        'Disallow API bots.',
        '<code>!group unlock bot</code>',
        'Allow API bots.',
        '<code>!group lock member</code>',
        'Lock group member.',
        '<code>!group unlock member</code>',
        'Unlock group member.',
        '<code>!group lock name</code>',
        'Lock group name.',
        '<code>!group unlock name</code>',
        'Unlock group name.',
        '<code>!group lock photo</code>',
        'Lock group photo.',
        '<code>!group unlock photo</code>',
        'Unlock group photo.',
        '<code>!group settings</code>',
        'Show group settings.',
        '<code>!link set</code>',
        'Generate/revoke invite link.',
        '<code>!setabout [description]</code>',
        'Set group description.',
        '<code>!setname [new_name]</code>',
        'Set group name.',
        '<code>!setphoto</code>',
        'Set group photo.',
        '<code>!setrules [rules]</code>',
        'Set group rules.',
        '<code>!sticker warn</code>',
        'Sticker restriction, sender will be warned for the first violation.',
        '<code>!sticker kick</code>',
        'Sticker restriction, sender will be kick.',
        '<code>!sticker ok</code>',
        'Disable sticker restriction.',
        '<code>!setwelcome [rules]</code>',
        'Set group welcome message.',
        '<code>!welcome group</code>',
        'Welcome message will shows in group.',
        '<code>!welcome pm</code>',
        'Welcome message will send to new member via PM.',
        '<code>!welcome disable</code>',
        'Disable welcome message.',
        '<code>!promote</code>',
        'If typed when replying, promote replied user as moderator',
        '<code>!promote [user_id]</code>',
        'Promote user_id as moderator',
        '<code>!promote @[username]</code>',
        'Promote username as moderator',
        '<code>!demote</code>',
        'If typed when replying, demote replied user from moderator',
        '<code>!demote [user_id]</code>',
        'Demote user_id from moderator',
        '<code>!demote @[username]</code>',
        'Demote username from moderator',
        '<code>!antispam kick</code>',
        'Enable flood and spam protection. Offender will be kicked.',
        '<code>!antispam ban</code>',
        'Enable flood and spam protection. Offender will be banned.',
        '<code>!antispam disable</code>',
        'Disable flood and spam protection',
        '<code>!whitelist</code>',
        'If type in reply, allow user to use the bot when whitelist mode is enabled',
        '<code>!unwhitelist</code>',
        'If type in reply, remove user from whitelist',
        '<code>!whitelist [user_id]/@[username]</code>',
        'Allow user to use the bot when whitelist mode is enabled',
        '<code>!unwhitelist [user_id]/@[username]</code>',
        'Remove user from whitelist',
      },
      moderator = {
        '<code>!invite</code>',
        'If type by replying, bot will then inviting the replied user.',
        '<code>!invite [user_id]</code>',
        'Invite by their <code>user_id</code>.',
        '<code>!invite [@username]</code>',
        'Invite by their <code>@username</code>.',
        '<code>!invite [print_name]</code>',
        'Invite by their <code>print_name</code>.',
        '<code>!ban </code>',
        'If type in reply, will ban user from chat group.',
        '<code>!ban [user_id]/@[username] </code>',
        'Kick user from chat and kicks it if joins chat again',
        '<code>!banlist </code>',
        'List users banned from chat group.',
        '<code>!unban</code>',
        'If type in reply, will unban user from chat group.',
        '<code>!unban [user_id]/@[username]</code>',
        'Unban user',
        '<code>!kick</code>',
        'If type in reply, will kick user from chat group.',
        '<code>!kick [user_id]/@[username]</code>',
        'Kick user from chat group',
        '<code>!modlist</code>',
        'List of moderators',
      },
      user = {
        '<code>!about</code>',
        'Read group description',
        '<code>!rules</code>',
        'Read group rules',
        '<code>!link get</code>',
        'Print invite link',
        '<code>!kickme</code>',
        'Kick yourself out of this group.'
      },
    },
  }

end
