do

  local whofile = '/tmp/whois.txt'

  local function get_whois(domain)
    local domain = URL.escape(domain)
    local url = 'http://www.whoisxmlapi.com/whoisserver/WhoisService?domainName='..domain..'&outputFormat=JSON'
    local res, code = http.request(url)
    local data = json:decode(res)
    vardump(data)
    local whois = data.WhoisRecord.registryData.rawText

    local file = io.open(whofile, 'w')
    file:write(whois)
    file:flush()
    file:close()

    return whois
  end

  local function run(msg, matches)
    vardump(matches)
    local whoinfo = get_whois(matches[1])
    if matches[2] then
      if matches[2] == 'txt' then
        reply_file(msg.id, whofile, ok_cb, true)
      end
      if matches[2] == 'pm' then
        send_api_msg(msg, msg.from.peer_id, whoinfo, true, '')
      end
      -- if matches[2] == 'pmtxt' then
      --   send_document('user#id'..msg.from.peer_id, whofile, rmtmp_cb, {file_path=whofile})
      -- end
    else
      reply_msg(msg.id, whoinfo, ok_cb, true)
    end
  end

  return {
    description = 'Whois lookup.',
    usage = {
      '<code>!whois [url]</code>',
      'Returns whois lookup for <code>[url]</code>',
      '',
      '<code>!whois [url] txt</code>',
      'Returns whois lookup for <code>[url]</code> and then send as text file.',
      '',
      '<code>!whois [url] pm</code>',
      'Returns whois lookup for <code>[url]</code> into requester PM.',
      '',
      -- '<code>!whois [url] pmtxt</code>',
      -- 'Returns whois lookup file for <code>[url]</code> and then send into requester PM.',
    },
    patterns = {
      '^!whois (%g+)$',
      '^!whois (%g+) (txt)$',
      '^!whois (%g+) (pm)$',
      -- '^!whois (%g+) (pmtxt)$'
    },
    run = run
  }

end
