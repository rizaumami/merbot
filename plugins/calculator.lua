-- Function reference: http://mathjs.org/docs/reference/functions/categorical.html

do

  local function mathjs(msg, exp)
    local url = 'http://api.mathjs.org/v1/'
    url = url..'?expr='..URL.escape(exp)
    local b,c = http.request(url)
    local text = nil
    if c == 200 or c == 400 then
      while true do
        b, k = string.gsub(b, '^(-?%d+)(%d%d%d)', '%1 %2')
        if (k==0) then
          break
        end
      end
      text = b
    else
      text = 'Unexpected error\n'
        ..'Is api.mathjs.org up?'
    end
    reply_msg(msg.id, text, ok_cb, true)
  end

  local function run(msg, matches)
    mathjs(msg, matches[1])
  end

  return {
    description = "Calculate math expressions with mathjs API",
    usage = {
      '<code> !calc [expression]</code>',
      'evaluates the expression and sends the result.',
    },
    patterns = {
      "^!calc (.*)$"
    },
    run = run
  }

end
