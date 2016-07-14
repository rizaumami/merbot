do

  local function yandex_translate(msg, source_lang, target_lang, text)
    if source_lang and target_lang then
      lang = source_lang .. '-' .. target_lang
    elseif target_lang then
      lang = target_lang
    elseif not source_lang and not target_lang then
      lang = _config.lang or 'en'
    end

    local url = 'https://translate.yandex.net/api/v1.5/tr.json/translate?key=' .. _config.api_key.yandex .. '&lang=' .. lang .. '&text=' .. URL.escape(text)
    local str, res= https.request(url)
    local jstr = json:decode(str)

    if jstr.code == 200 then
      send_message(msg, jstr.text[1], 'html')
    else
      send_message(msg, jstr.message, 'html')
    end
  end

  local function trans_by_reply(extra, success, result)
    yandex_translate(extra.msg, extra.srclang, extra.tolang, result.text)
  end

  local function run(msg, matches)
    if not _config.api_key or not _config.api_key.yandex or _config.api_key.yandex == '' then
      local text = '<b>Missing</b> Yandex Translate API key in config.lua.\n\n'
           .. 'Get it from https://tech.yandex.com/translate/ \n\n'
           .. 'Set the key using <code>setapi yandex [api_key]</code>'

      bot_sendMessage(get_receiver_api(msg), text, true, msg.id, 'html')
      return nil
    end

    -- comment this line if you want this plugin to works in private message.
    --if not is_chat_msg(msg) and not is_admin(msg.from.peer_id) then return nil end

    if msg.reply_id then
      if matches[1] == 'translate' then
        -- Third pattern
        if #matches == 1 then
          print("First")
          get_message(msg.reply_id, trans_by_reply, {msg=msg, srclang=nil, tolang=nil})
        end

        -- Second pattern
        if #matches == 2 then
          print("Second")
          get_message(msg.reply_id, trans_by_reply, {msg=msg, srclang=nil, tolang=matches[2]})
        end

        -- First pattern
        if #matches == 3 then
          print("Third")
          get_message(msg.reply_id, trans_by_reply, {msg=msg, srclang=matches[2], tolang=matches[3]})
        end
      end
    else
      if msg.reply_to_message then
        local text = msg.reply_to_message.text
        if matches[1] == 'translate' then
          if #matches == 1 then
            print("First")
            yandex_translate(msg, nil, nil, text)
          end

          if #matches == 2 then
            print("Second")
            yandex_translate(msg, nil, matches[2], text)
          end

          if #matches == 3 then
            print("Third")
            yandex_translate(msg, matches[2], matches[3], text)
          end
        end
      else
        if matches[1] == 'trans' then
          -- Third pattern
          if #matches == 2 then
            print("Fourth")
            local text = matches[2]
            yandex_translate(msg, nil, nil, text)
          end

          -- Second pattern
          if #matches == 3 then
            print("Fifth")
            local target = matches[2]
            local text = matches[3]
            yandex_translate(msg, nil, target, text)
          end

          -- First pattern
          if #matches == 4 then
            print("Sixth")
            local source = matches[2]
            local target = matches[3]
            local text = matches[4]
            yandex_translate(msg, source, target, text)
          end
        end
      end
    end
  end

  return {
    description = "Translate some text",
    usage = {
      '<code>!trans text</code>',
      'Translate the <code>text</code> to English.',
      '',
      '<code>!trans target_lang text</code>',
      'Translate the <code>text</code> to <code>target_lang</code>.',
      '',
      '<code>!trans source,target text</code>',
      'Translate the <code>source</code> to <code>target</code>.',
      '',
      '<b>Use !translate when reply!</b>',
      '<code>!translate</code>',
      'By reply. Translate the replied text into default language (or english).',
      '',
      '<code>!translate target_lang</code>',
      'By reply. Translate the replied text into <code>target_lang</code>.',
      '',
      '<code>!translate source,target</code>',
      'By reply. Translate the replied text <code>source</code> to <code>target</code>.',
      '',
      'Languages are two letter <a href="https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes">ISO 639-1 language code</a>',
    },
    patterns = {
      "^!(trans) ([%w]+),([%a]+) (.+)",
      "^!(trans) ([%w]+) (.+)",
      "^!(trans) (.+)",
      "^!(translate) ([%w]+),([%a]+)",
      "^!(translate) ([%w]+)",
      "^!(translate)",
    },
    run = run
  }

end
