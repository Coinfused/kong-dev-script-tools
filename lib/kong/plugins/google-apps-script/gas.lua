local json_decode   = require("cjson").decode
local json_encode   = require("cjson").encode
local table_insert  = table.insert
local lower         = string.lower
local ngx_print     = ngx.print
local ngx_exit      = ngx.exit
local ngx_log       = ngx.log



local _M = {}


-- Get the plugin setting by the downstram request method.
-- If setting for this method are not set, then use general settings.
-- If there isn't a general setting then return "method not allowed".
function get_setting_by_method(config)

  local specific = config[lower(config.req["method"])]

  local specific_name,
        generic_name,
        name,
        specific_arguments,
        generic_arguments,
        default_arguments,
        arguments

  if specific then
    specific_name, specific_arguments = specific.function_name, specific.function_arguments
  end

  generic_name, generic_arguments = config.function_name, config.function_arguments

  name = specific_name or generic_name or nil
  if not name then
    do return false end
  end

  default_arguments =  {"method", "path", "headers", "querystring", "body"}
  arguments = specific_arguments or generic_arguments or default_arguments

  return true, name, arguments
end


-- Return arraylike table with gas arguments values.
function get_gas_arguments(req, settings)

  local arguments = {}
  for _, setting in pairs(settings) do
    req.querystring.devMode = nil
    local argument = get_gas_value(req, setting)
    table_insert(arguments, argument)
  end

  return arguments
end


function get_gas_value(req, constructors)

  -- If the first string in the argument constructor is "fix"
  -- then return the second argument has a static value.
  if constructors:match("[^%.]+") == "fix" then
    return constructors:match("[^.]+$")
  end

  -- parse the request with argument constructor.
  for constructor in constructors:gmatch("[^%.]+") do
    req = req[constructor]
  end

  -- if value is null, replace with empty string.
  -- Because Lua does not allow empty value in a arraylike table.
  return req or " "
end


function is_dev_mode(req)
  return req.headers.devMode or req.querystring.devMode or false
end


function _M.get_gas_body(config)

  local ok, name, arguments = get_setting_by_method(config)
  if not ok then
    do return false end
  end

  -- don't change the order, after is_dev_mode()
  -- the devMode querystring is removed
  local body = json_encode({
    ["devMode"]     = is_dev_mode(config.req),
    ["function"]    = get_gas_value(config.req, name),
    ["parameters"]  = get_gas_arguments(config.req, arguments)
  })

  ngx_log(ngx.ERR, body)
  return true, body

end


return _M
