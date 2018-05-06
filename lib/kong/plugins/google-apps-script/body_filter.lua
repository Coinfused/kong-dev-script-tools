local json_decode = require("cjson.safe").decode
local json_encode = require("cjson").encode

local _M = {}

function _M.transform_json_body(buffered_data)
  local body = json_decode(buffered_data)

  if body.done == true then

    if body.response then body = {data = body.response.result} end

    -- TODO investiage the strange error for expired auth
    -- in which script @type is not removed.
    if body.error then body = {error = body.error} end

  elseif body.done == false then
    body = {error = "Script exceeded maximum execution time"}

  else
    body = body
  end
  return json_encode(body)
end

return _M
