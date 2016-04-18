do

  local function run(msg, matches)
    local domain = URL.escape(matches[1])
    local url = 'http://www.whoisxmlapi.com/whoisserver/WhoisService?domainName='..domain..'&outputFormat=JSON'
    local res, code = http.request(url)
    local data = json:decode(res)
    local whois = data.WhoisRecord.registryData.rawText
    reply_msg(msg.id, whois, ok_cb, true)
  end

  return {
    description = 'Whois lookup.',
    usage = {
      '<code> !whois [url]</code>',
    },
    patterns = {
      '^!whois (.*)$'
    },
    run = run
  }

end
