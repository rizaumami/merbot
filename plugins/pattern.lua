do

  local kata = {
    'Mungkin',
    'Apa',
    'Pasti',
    'Apakah',
    'Mungkinkah',
    'Ane yakin',
    'Mimin yakin',
  }

  local function action_by_reply(extra, success, result)
    local output = result.text or ''
    output = output:gsub(extra.text:match('^/s/(.-)/(.-)/?$'))
    output = kata[math.random(#kata)]..' maksudnya:\n"' .. output:sub(1, 4000) .. '"'
    reply_msg(result.id, output, ok_cb, true)
  end

  local function run(msg, matches)
    if msg.reply_id then
      get_message(msg.reply_id, action_by_reply, msg)
    end
  end

  return {
    description = '',
    usage = {},
    patterns = {
      '^/s/.-/.-/?$'
    },
    run = run
  }

end
