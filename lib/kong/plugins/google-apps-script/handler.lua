local BasePlugin = require "kong.plugins.base_plugin"
local access = require "kong.plugins.google-apps-script.access"
local body_filter = require "kong.plugins.google-apps-script.body_filter"


local CustomHandler = BasePlugin:extend()


function CustomHandler:new()
  CustomHandler.super.new(self, "Kong Google Apps Script")
end


function CustomHandler:access(config)
  CustomHandler.super.access(self)
  access.execute(config)
end


function CustomHandler:header_filter(config)
  CustomHandler.super.header_filter(self)
  ngx.header["content_length"] = nil
end

function CustomHandler:body_filter(config)
  CustomHandler.super.body_filter(self)

  local chunk, eof = ngx.arg[1], ngx.arg[2]
  ngx.ctx.response_body = (ngx.ctx.response_body or "")..chunk

  if eof then
    local response_body = ngx.ctx.response_body
    local response_json = body_filter.transform_json_body(response_body)
    ngx.arg[1] = response_json
  else
    ngx.arg[1] = nil
  end

end

CustomHandler.PRIORITY = 850
CustomHandler.VERSION = "0.1.0"


return CustomHandler
