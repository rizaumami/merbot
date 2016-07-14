do

  local function run(msg, matches)
    if matches[1] == 'kirim' then
      send_api_msg(msg, get_receiver_api(msg), matches[2], true, 'html')
    end
    if matches[1] == 'manual' then
      send_api_msg(msg, '@thefinemanual', matches[2], true, 'html')
    end
  end

--------------------------------------------------------------------------------

  return {
    description = 'Returns the five (if group) or eight (if private message) top posts for the given subreddit or query, or from the frontpage.',
    usage = {},
    patterns = {
      '^!(kirim) (.*)$',
      '^!(manual) (.*)$'
    },
    run = run
  }

end
