local gas               = require "kong.plugins.google-apps-script.gas"
local json_decode       = require("cjson").decode
local json_encode       = require("cjson").encode
local responses         = require "kong.tools.responses"
local http              = require "resty.http"
local ngx_print         = ngx.print
local ngx_exit          = ngx.exit
local ngx_log           = ngx.log
local response_headers  = ngx.header
local type              = type


local _M = {}


function json_decode_if_table(v)
  if type(v) == "table" then
    return json_decode(v)
  end
  return v
end


-- Get the downstream request body once it has been read.
function get_request_body()
  local body = {}
  ngx.req.read_body()
  local args, err = ngx.req.get_post_args(25)
    if err == "truncated" then
      return responses.send(403,
                            json_encode({
                              done = true,
                              error = {
                                message = "Too many arguments",
                                code = 403
                              }}),
                            {["Content-Type"] = "application/json"})
    end
  for k,v in pairs(args) do
    body[k] = json_decode_if_table(k)
  end
  return body
end


function _M.execute(config)

  config.host       = "script.googleapis.com"
  config.port       = 443
  config.timeout    = config.timeout  or 300000
  config.keepalive  = config.keepalive or 300000
  config.req        = {
        paths       = ngx.ctx.router_matches.uri_captures,
        method      = ngx.req.get_method(),
        headers     = ngx.req.get_headers(),
        querystring = ngx.req.get_uri_args() or {},
        body        = get_request_body() or {},
  }

  --
  local ok, gas_body = gas.get_gas_body(config)

  -- method not allowed if there isn't any function name at method or general setting.
  if not ok then
    return responses.send(405,
                          json_encode({
                            done = true,
                            error = {
                              message = "method not allowed",
                              code = 405
                            }}),
                          {["Content-Type"] = "application/json"})
  end

  local client = http.new()

  client:set_timeout(config.timeout)

  local ok, err = client:connect(config.host, config.port)
  if not ok then
    ngx_log(ngx.ERR, "[google-apps-script] could not connect to Google Apps Script service: ", err)
    return responses.send_HTTP_INTERNAL_SERVER_ERROR(err)
  end

  local ok, err = client:ssl_handshake(false, config.host, false)
  if not ok then
    ngx_log(ngx.ERR, "[google-apps-script] could not perform SSL handshake : ", err)
    return responses.send_HTTP_INTERNAL_SERVER_ERROR(err)
  end

  local auth
  if config.req.headers["X-Google-Token"] then
    auth = config.req.headers["X-Google-Token"]
  elseif config.google_service_token then
    auth = config.google_service_token
  else
    auth = nil
  end

  local res
  res, err = client:request {
    method  = "POST",
    path    = "/v1/scripts/" .. config.script_id .. ":run",
    body    = gas_body,
    headers = {
      ["Content-Type"]    = "application/json",
      ["Accept-Encoding"] = "identity",
      ["Authorization"]   = auth
    }
  }

  if not res then
    return responses.send_HTTP_INTERNAL_SERVER_ERROR(err)
  end

  for k, v in pairs(res.headers) do
    response_headers[k] = v
  end

  ngx.status = res.status
  local response_body = res:read_body()
  ngx_print(response_body)

  ok, err = client:set_keepalive(config.keepalive)
  if not ok then
    ngx_log(ngx.ERR, "[google-apps-script] could not keepalive connection: ", err)
  end

  return ngx_exit(res.status)
end


return _M
