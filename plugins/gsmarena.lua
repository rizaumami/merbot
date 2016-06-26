--[[
Get Bing search API from from https://datamarket.azure.com/dataset/bing/search
Set the key by: !setapi bing [bing_api_key] or manually inserted into config.lua
--]]

do

  local mime = require('mime')

  local function get_galink(msg, query)
    local burl = "https://api.datamarket.azure.com/Data.ashx/Bing/Search/Web?Query=%s&$format=json&$top=1"
    local burl = burl:format(URL.escape("'site:gsmarena.com intitle:" .. query .. "'"))
    local resbody = {}
    local bang, bing, bung = https.request{
        url = burl,
        headers = { ["Authorization"] = "Basic " .. mime.b64(":" .. _config.api_key.bing) },
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
    local phdata = {}

    if gsm == nil or next(gsm.data) == nil then
      reply_msg(msg.id, 'No phones found!', ok_cb, true)
      return
    end
    if not gsm.data.platform then
      gsm.data.platform = {}
    end
    if gsm.data.launch.status == 'Discontinued' then
      launch = gsm.data.launch.status .. '. Was announced in ' .. gsm.data.launch.announced
    else
      launch = gsm.data.launch.status
    end
    if gsm.data.platform.os then
      phdata[1] = '<b>OS</b>: ' .. gsm.data.platform.os .. '\n'
    end
    if gsm.data.platform.chipset then
      phdata[2] = '<b>Chipset</b>: ' .. gsm.data.platform.chipset .. '\n'
    end
    if gsm.data.platform.cpu then
      phdata[3] = '<b>CPU</b>: ' .. gsm.data.platform.cpu .. '\n'
    end
    if gsm.data.platform.gpu then
      phdata[4] = '<b>GPU</b>: ' .. gsm.data.platform.gpu .. '\n'
    end
    if gsm.data.camera.primary then
      phdata[5] = '<b>Camera</b>: ' .. gsm.data.camera.primary:gsub(',.*$', '') .. ', ' .. (gsm.data.camera.video or '') .. '\n'
    end
    if gsm.data.memory.internal then
      phdata[6] = '<b>RAM</b>: ' .. gsm.data.memory.internal .. '\n'
    end

    local gadata = table.concat(phdata)
    local title = '<b>' .. gsm.title .. '</b><a href="' .. gsm.img .. '">.</a>\n\n'
    local dimensions = gsm.data.body.dimensions:gsub('%(.-%)', '')
    local display = gsm.data.display.size:gsub(' .*$', '"') .. ', '
        .. gsm.data.display.resolution:gsub('%(.-%)', '')
    local output = title .. '<b>Status</b>: ' .. launch .. '\n'
        .. '<b>Dimensions</b>: ' .. dimensions .. '\n'
        .. '<b>Weight</b>: ' .. gsm.data.body.weight:gsub('%(.-%)', '') .. '\n'
        .. '<b>SIM</b>: ' .. gsm.data.body.sim .. '\n'
        .. '<b>Display</b>: ' .. display .. '\n'
        .. gadata
        .. '<b>MC</b>: ' .. gsm.data.memory.card_slot .. '\n'
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
