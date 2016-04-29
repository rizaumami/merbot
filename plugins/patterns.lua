do

  local function action_by_reply(extra, success, result)
    local output = result.text or ''
    local m1, m2 = extra.text:match('^/?s/(.-)/(.-)/?$')
    if not m2 then
      return
    end
    output = output:gsub(m1, m2)
    output = 'Did you mean:\n"' .. output:sub(1, 4000) .. '"'
    reply_msg(result.id, output, ok_cb, true)
  end

  local function run(msg, matches)
    if msg.reply_id then
      get_message(msg.reply_id, action_by_reply, msg)
    end
  end

  return {
    description = 'Replace patterns in a message.',
    usage = {
      '<code>/s/from/to/</code>',
      'Replace <code>from</code> with <code>to</code>'
    },
    patterns = {
      '^/?s/.-/.-/?$'
    },
    run = run
  }

end
