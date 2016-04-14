do

  local function run(msg, matches)
    local tgexec = "./tg/bin/telegram-cli -c ./data/tg-cli.config -p default -De "
    local url = 'http://api.hackertarget.com/whois/?q='..URL.escape(matches[1])
    local whois_file = matches[1]:gsub('%.', '-')
    local whois_file = '/tmp/'..whois_file
    local w_file = ltn12.sink.file(io.open(whois_file, 'w'))
    http.request {
        url = url,
        sink = w_file,
      }

    local file = io.open(whois_file, 'r')
    local file = file:read('*all')
    if file:match('DOMAIN NOT FOUND') or file:match('No match') then
      reply_msg(msg.id, 'Domain not found.', ok_cb, true)
    else
      os.execute(tgexec.."\'reply_file "..msg.id.." "..whois_file.."\'")
      --send_document(get_receiver(msg), whois_file, rmtmp_cb, {file_path=whois_file})
    end
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
