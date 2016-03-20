--[[

Save message as json format to a log file.
Remove phone number, in case if there is phone contact in bots account.
Basically, it's just dumping the message into a file. So, don't be surprised
if the log file size is big.

--]]

do

  local function pre_process(msg)
    if is_chat_msg(msg) then
      local gid = tonumber(msg.to.peer_id)
      local data = load_data(_config.administration[gid])
      local message = serpent.dump(msg, {comment=false})
      local message = message:match('do local _=(.*);return _;end')
      local message = message:gsub('phone="%d+"', '')
      local logfile = io.open('data/'..gid..'/'..gid..'.log', 'a')
      logfile:write(message..'\n')
      logfile:close()
    end
    return msg
  end

--------------------------------------------------------------------------------

  function run(msg, matches)
    if is_mod(msg.from.peer_id, gid) then
      local gid = tonumber(msg.to.peer_id)
      if matches[1] == 'get' then
        send_document('chat#id'..gid, './data/'..gid..'/'..gid..'.log', ok_cb, false)
      elseif matches[1] == 'pm' then
        send_document('user#id'..msg.from.peer_id, './data/'..gid..'/'..gid..'.log', ok_cb, false)
      end
    end
  end

--------------------------------------------------------------------------------

  return {
    description = 'Logging group messages.',
    usage = {
      moderator = {
        '<code>!log get</code>',
        'Send chat log to its chat group',
        '<code>!log pm</code>',
        'Send chat log to private message'
      },
    },
    patterns = {
      '^!log (.+)$'
    },
    run = run,
    pre_process = pre_process
  }

end

