do

  local function get_word(s, i)
    s = s or ''
    i = i or 1

    local t = {}
    for w in s:gmatch('%g+') do
      table.insert(t, w)
    end

    return t[i] or false
  end

  local function run(msg, matches)
    local input = msg.text:upper()
    if not input:match('%a%a%a TO %a%a%a') then
      reply_msg(msg.id, 'Example: !cash 5 USD to IDR', ok_cb, true)
      return
    end

    local from = input:match('(%a%a%a) TO')
    local to = input:match('TO (%a%a%a)')
    local amount = get_word(input, 2)
    local amount = tonumber(amount) or 1
    local result = 1
    local url = 'https://www.google.com/finance/converter'

    if from ~= to then
      local url = url..'?from='..from..'&to='..to..'&a='..amount
      local str, res = https.request(url)
      if res ~= 200 then
        reply_msg(msg.id, 'Connection error.', ok_cb, true)
        return
      end
      str = str:match('<span class=bld>(.*) %u+</span>')
      if not str then
        reply_msg(msg.id, 'Connection error.', ok_cb, true)
        return
      end
      result = string.format('%.2f', str)
    end

    while true do
      result, k = string.gsub(result, "^(-?%d+)(%d%d%d)", '%1,%2')
      if (k==0) then
        break
      end
    end

    local output = amount..' '..from..' = '..result..' '..to..'\n\n'
    local output = output..'Source: Google Finance\n'..os.date('%F %T %Z')

    reply_msg(msg.id, output, ok_cb, true)
  end

--------------------------------------------------------------------------------

  return {
    description = 'Returns (Google Finance) exchange rates for various currencies.',
    usage = {
      '<code> !cash [amount] [from] to [to]</code>',
      'Example: /cash 5 USD to EUR',
    },
    patterns = {
      '^!(cash) (.*)$',
    },
    run = run
  }

end
