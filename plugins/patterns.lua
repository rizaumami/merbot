do

  local function strikethrough(text)
    local striked = {}
    for i = 1, #text do
      local output = text:sub(i, i)
      striked[i] = output..'̶'
    end
    return table.concat(striked)
  end

  local function action_by_reply(extra, success, result)
    local output = result.text or ''
    local m1, m2 = extra.text:match('^/?s/(.-)/(.-)/?$')
    if not m2 then
      return
    end
    local word1 = strikethrough(m1)
    output = output:gsub(m1, word1..m2)
    output = output:sub(1, 4000)
    reply_msg(result.id, output, ok_cb, true)
  end

  local function run(msg, matches)
    if msg.reply_id and matches[1]:match('^/?s/(.-)/(.-)/?$') then
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
