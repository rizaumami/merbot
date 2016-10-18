do

  function run(msg, matches)
    if matches[1] == 'bin' then
      local input = matches[2]:gsub('—', '--')

      if not input then
        reply_msg(msg.id, 'Please specify a command to run.', ok_cb, false)
        return
      end

      local f = io.popen(input)
      local output = f:read('*all')
      f:close()

      if output:len() == 0 then
        output = 'Done!'
      else
        output = '<b>$</b> <code>' .. input .. '</code>\n'
            .. '<code>' .. output .. '</code>'
      end

      api.sendMessage(get_receiver_api(msg), output, 'html', true, msg.id)
    end
  end

  --------------------------------------------------------------------------------

  return {
    description = 'Various sudo commands.',
    usage = {
      sudo = {
        '<code>!bin [command]</code>',
        'Run a system command.',
      },
    },
    patterns = {
      '^!(bin) (.*)$',
    },
    run = run,
    privileged = true,
  }

end