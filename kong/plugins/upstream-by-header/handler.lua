-- If you're not sure your plugin is executing, uncomment the line below and restart Kong
-- then it will throw an error which indicates the plugin is being loaded at least.

--assert(ngx.get_phase() == "timer", "The world is coming to an end!")


-- Grab pluginname from module name
local plugin_name = ({...})[1]:match("^kong%.plugins%.([^%.]+)")

-- load the base plugin object and create a subclass
local plugin = require("kong.plugins.base_plugin"):extend()

local kong = kong

-- constructor
function plugin:new()
  plugin.super.new(self, plugin_name)

  -- do initialization here, runs in the 'init_by_lua_block', before worker processes are forked

end

---------------------------------------------------------------------------------------------
-- In the code below, just remove the opening brackets; `[[` to enable a specific handler
--
-- The handlers are based on the OpenResty handlers, see the OpenResty docs for details
-- on when exactly they are invoked and what limitations each handler has.
--
-- The call to `.super.xxx(self)` is a call to the base_plugin, which does nothing, except logging
-- that the specific handler was executed.
---------------------------------------------------------------------------------------------


--[[ handles more initialization, but AFTER the worker process has been forked/created.
-- It runs in the 'init_worker_by_lua_block'
function plugin:init_worker()
  plugin.super.init_worker(self)

  -- your custom code here

end --]]

--[[ runs in the ssl_certificate_by_lua_block handler
function plugin:certificate(plugin_conf)
  plugin.super.certificate(self)

  -- your custom code here

end --]]

--[[ runs in the 'rewrite_by_lua_block' (from version 0.10.2+)
-- IMPORTANT: during the `rewrite` phase neither the `api` nor the `consumer` will have
-- been identified, hence this handler will only be executed if the plugin is
-- configured as a global plugin!
function plugin:rewrite(plugin_conf)
  plugin.super.rewrite(self)

  -- your custom code here

end --]]

---[[ runs in the 'access_by_lua_block'
function plugin:access(plugin_conf)
  plugin.super.access(self)

  local req_headers = kong.request.get_headers()

  local match, upstream
  local match_before, match_now = -1

  for _, rule in ipairs(plugin_conf.rules) do
    match = true
    match_now = 0

    for rule_header_name, rule_header_value in pairs(rule.headers) do
      if req_headers[rule_header_name] ~= rule_header_value then
        match = false
        break
      end
      match_now = match_now + 1
    end

    if match then
      upstream = match_now <= match_before and upstream or rule.upstream_name
      match_before = match_now
    end
  end

  kong.log.inspect(upstream)

  if upstream then
    kong.service.set_upstream(upstream)
    kong.response.set_header("X-Upstream-Name", upstream)
  end
end --]]

---[[ runs in the 'header_filter_by_lua_block'
function plugin:header_filter(plugin_conf)
  plugin.super.header_filter(self)

  -- your custom code here, for example;
end --]]

--[[ runs in the 'body_filter_by_lua_block'
function plugin:body_filter(plugin_conf)
  plugin.super.body_filter(self)

  -- your custom code here

end --]]

--[[ runs in the 'log_by_lua_block'
function plugin:log(plugin_conf)
  plugin.super.log(self)

  -- your custom code here

end --]]


-- set the plugin priority, which determines plugin execution order
plugin.PRIORITY = 1000

-- return our plugin object
return plugin
