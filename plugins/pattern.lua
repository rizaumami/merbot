do

  local words = { -- perhaps, maybe, do you, etc...
    'Mungkin', 'Pasti', 'Apakah', 'Mungkinkah', 'Ane yakin', 'Mimin yakin',
    'Saya rasa', 'Gue yakin', 'Mbah rasa', 
  }
  
  local target = { -- you 
    'kamu', 'ente', 'Anda', 'sampeyan', 'akang', 'lu', 'Bapak', 'Ibu', 'kakak',
    'nyai', 'mbah', 'juragan', 'pah erte', 'pak lurah', 'komandan', 'pak guru',
    'bos', 'pas ustadz',
    
  }
  
  local verba = { -- description 
    'mau ngomong', 'hendak bicara', 'akan khotbah', 'bakal mangap', 'mau pidato',
    'bermaksud', 'akan menyampaikan', 'hendak bersabda',
  }

  local function action_by_reply(extra, success, result)
    local output = result.text or ''
    output = output:gsub(extra.text:match('/s/(.-)/(.-)/$'))
    -- words+target+verba+replaced message
    output = words[math.random(#words)]..' '..target[math.random(#target)]
        ..' '..verba[math.random(#verba)]..':\n"'..output:sub(1, 4000)..'"'
    reply_msg(result.id, output, ok_cb, true)
  end

  local function run(msg, matches)
    if msg.reply_id and matches[1]:match('/s/.-/.-/') then
      get_message(msg.reply_id, action_by_reply, msg)
    end
  end

  return {
    description = 'Replace words in a message.',
    usage = {
      '<code>/s/from/to/</code>',
      'Replace <code>from</code> with <code>to</code>'
    },
    patterns = {
      '^(/s/.-/.-/)$'
    },
    run = run
  }

end
