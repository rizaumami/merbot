do

   local function run(msg, matches)
      local base = 'http://dogr.io/'
      local path = string.gsub(matches[1], ' ', '%%20')
      local url = base..path..'.png?split=false&.png'
      local urlm = 'https?://[%%%w-_%.%?%.:/%+=&]+'

      if string.match(url, urlm) == url then
         send_photo_from_url(get_receiver(msg), url)
      else
         print("Can't build a good URL with parameter "..matches[1])
      end
   end

   return {
      description = 'Create a doge image with you words',
      usage = {
         '<code>!dogify (your/words/with/slashes)</code>',
         '<code>!doge (your/words/with/slashes)</code>',
         'Create a doge with the image and words.',
         'No special characters!',
      },
      patterns = {
         '^!dogify (.+)$',
         '^!doge (.+)$',
      },
      run = run
   }

end