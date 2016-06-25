--[[
Get Bing search API from from https://datamarket.azure.com/dataset/bing/search
Set the key by: !setapi bing [bing_api_key] or manually inserted into config.lua
--]]

do

  local mime = require('mime')

  local function get_galink(msg, query)
    local burl = "https://api.datamarket.azure.com/Data.ashx/Bing/Search/Web?Query=%s&$format=json&Adult=%%27Strict%%27&$top=1"
    local burl = burl:format(URL.escape("'site:gsmarena.com full phone specification " .. query .. "'"))
    local resbody = {}
    local bang, bing, bung = https.request{
        url = burl,
        headers = { ["Authorization"] = "Basic "..mime.b64(":".._config.api_key.bing) },
        sink = ltn12.sink.table(resbody),
    }

    local dat = json:decode(table.concat(resbody))
    local jresult = dat.d.results

    if next(jresult) ~= nil then
      return jresult[1].Url
    end
  end

  local function run(msg, matches)
    -- comment this line if you want this plugin to works in private message.
    if not is_chat_msg(msg) and not is_admin(msg.from.peer_id) then return nil end

    local phone = get_galink(msg, matches[2])
    local slug = phone:gsub('^.+/', '')
    local slug = slug:gsub('.php', '')
    local ibacor = 'http://ibacor.com/api/gsm-arena?view=product&slug='
    local res, code = http.request(ibacor .. slug)
    local gsm = json:decode(res)

    if gsm == nil or next(gsm.data) == nil then
      reply_msg(msg.id, 'No phones found!', ok_cb, true)
      return
    end
    if not gsm.data.platform then
      gsm.data.platform = {os = '', chipset = '', cpu = '', gpu = ''}
    end
    if not gsm.data.platform.chipset then
      gsm.data.platform.chipset = ''
    end
    if not gsm.data.platform.gpu then
      gsm.data.platform.gpu = ''
    end

    local title = '<b>' .. gsm.title .. '</b><a href="' .. gsm.img .. '">.</a>\n\n'
    local dimensions = gsm.data.body.dimensions:gsub('%(.-%)', '')
    local display = gsm.data.display.size:gsub(' .*$', '"') .. ', '
        .. gsm.data.display.resolution:gsub('%(.-%)', '')
    local camera = gsm.data.camera.primary:gsub(',.*$', '') .. ', '
        .. gsm.data.camera.video
    local output = title .. '<b>Status</b>: ' .. gsm.data.launch.status .. '\n'
        .. '<b>Dimensions</b>: ' .. dimensions .. '\n'
        .. '<b>Weight</b>: ' .. gsm.data.body.weight .. '\n'
        .. '<b>SIM</b>: ' .. gsm.data.body.sim .. '\n'
        .. '<b>Display</b>: ' .. display .. '\n'
        .. '<b>OS</b>: ' .. gsm.data.platform.os .. '\n'
        .. '<b>Chipset</b>: ' .. gsm.data.platform.chipset .. '\n'
        .. '<b>CPU</b>: ' .. gsm.data.platform.cpu .. '\n'
        .. '<b>GPU</b>: ' .. gsm.data.platform.gpu .. '\n'
        .. '<b>MC</b>: ' .. gsm.data.memory.card_slot .. '\n'
        .. '<b>RAM</b>: ' .. gsm.data.memory.internal .. '\n'
        .. '<b>Camera</b>: ' .. camera .. '\n'
        .. '<b>Battery</b>: ' .. gsm.data.battery._empty_:gsub('battery', '') .. '\n'
        .. '<a href="' .. phone .. '">More on gsmarena.com ...</a>'

    send_api_msg(msg, get_receiver_api(msg), output:gsub('<br>', ''), false, 'html')
  end

--------------------------------------------------------------------------------

  return {
    description = 'Returns mobile phone specification.',
    usage = {
      '<code>!phone [phone_name]</code>',
      '<code>!gsm [phone_name]</code>',
      'Returns <code>phone_name</code> specification.',
    },
    patterns = {
      '^!(phone) (.*)$',
      '^!(gsm) (.*)$'
    },
    run = run
  }

end
