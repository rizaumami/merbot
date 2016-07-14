--[[
 As for now, telegram-cli have unresolved bug that it's unable to read messages
 in supergroup with 200+ members.

 I cannot C, hence this shitty workaround.
 This is an api bot script that relaying all command messages to telegram-cli
 bot account.

 Run this script in separate tmux/multiplexer window.
--]]

package.path = package.path .. ';.luarocks/share/lua/5.2/?.lua'
  .. ';.luarocks/share/lua/5.2/?/init.lua'
package.cpath = package.cpath .. ';.luarocks/lib/lua/5.2/?.so'

local https = require "ssl.https"
local serpent = require "serpent"
local json = (loadfile "./libs/JSON.lua")()

local config = (loadfile './data/config.lua')()
local url = 'https://api.telegram.org/bot' .. config.bot_api.key
local offset = 0

local function getUpdates()
  local response = {}
  local success, code, headers, status  = https.request{
    url = url .. '/getUpdates?timeout=20&limit=1&offset=' .. offset,
    method = "POST",
    sink = ltn12.sink.table(response),
  }

  local body = table.concat(response or {"no response"})
  if (success == 1) then
    return json:decode(body)
  else
    return nil, "Request Error"
  end
end

function vardump(value)
  print(serpent.block(value, {comment=false}))
end

local function run()
  while true do
    local updates = getUpdates()
    vardump(updates)
    if(updates) then
      if (updates.result) then
        for i=1, #updates.result do
          local msg = updates.result[i]
          offset = msg.update_id + 1
          print '=================================================='
          vardump(msg)
          if msg.message and msg.message.date > (os.time() - 5) then
            if msg.message.text and msg.message.text:match('^[!/]') then
              https.request{
                url = url .. '/sendMessage?chat_id=' .. config.bot_api.master .. '&text=' .. serpent.dump(msg),
                method = "POST",
              }
            end
          end
        end
      end
    end
  end
end

return run()