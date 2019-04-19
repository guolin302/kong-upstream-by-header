local helpers = require "spec.helpers"
local version = require("version").version or require("version")


local PLUGIN_NAME = "upstream-by-header"
local KONG_VERSION = version(select(3, assert(helpers.kong_exec("version"))))


for _, strategy in helpers.each_strategy() do
  describe(PLUGIN_NAME .. ": (access) [#" .. strategy .. "]", function()
    local client

    lazy_setup(function()
      local bp
      local upstream1
      local service1

      if KONG_VERSION >= version("0.15.0") then
        --
        -- Kong version 0.15.0/1.0.0, new test helpers
        --
        bp = helpers.get_db_utils(strategy, nil, { PLUGIN_NAME })

        upstream1 = bp.upstreams:insert({
          name = "europe_cluster",
        })

        bp.targets:insert({
          upstream = upstream1,
          target = "mockbin.org:80",
        })

        service1 = bp.services:insert({
          name = "service1",
          host = "europe_cluster",
        })

        bp.routes:insert({
          paths = { "/local", },
          service = service1,
        })

        bp.plugins:insert {
          name = PLUGIN_NAME,
          config = {
            rules = {
              {
                headers = {
                  ["X-Country"] = "Italy",
                },
                upstream_name = "europe_cluster",
              },
            },
          },
        }
      else
        --
        -- Pre Kong version 0.15.0/1.0.0, older test helpers
        --
        bp = helpers.get_db_utils(strategy)

        upstream1 = bp.upstreams:insert({
          name = "europe_cluster",
        })

        bp.targets:insert({
          upstream = upstream1,
          target = "mockbin.org:80",
        })

        service1 = bp.services:insert({
          name = "service1",
          host = "europe_cluster",
        })

        bp.routes:insert({
          paths = { "/local", },
          service = service1,
        })

        bp.plugins:insert {
          name = PLUGIN_NAME,
          config = {
            rules = {
              {
                headers = {
                  ["X-Country"] = "Italy",
                },
                upstream_name = "europe_cluster",
              },
            },
          },
        }
      end

      -- start kong
      assert(helpers.start_kong({
        -- set the strategy
        database   = strategy,
        -- use the custom test template to create a local mock server
        nginx_conf = "spec/fixtures/custom_nginx.template",
        -- set the config item to make sure our plugin gets loaded
        plugins = "bundled," .. PLUGIN_NAME,  -- since Kong CE 0.14
        custom_plugins = PLUGIN_NAME,         -- pre Kong CE 0.14
      }))
    end)

    lazy_teardown(function()
      helpers.stop_kong(nil, true)
    end)

    before_each(function()
      client = helpers.proxy_client()
    end)

    after_each(function()
      if client then client:close() end
    end)



    --describe("request", function()
    --  it("gets a 'X-Upstream-Name' header", function()
    --    local r = assert(client:send {
    --      method = "GET",
    --      path = "/local",
    --      headers = {
    --        ["X-Country"] = "Italy",
    --      }
    --    })
    --    -- validate that the request succeeded, response status 200
    --    assert.response(r).has.status(200)
    --    -- now check the request (as echoed by mockbin) to have the header
    --    local header_value = assert.request(r).has.header("X-Upstream-Name")
    --    -- validate the value of that header
    --    assert.equal("europe_cluster", header_value)
    --  end)
    --end)



    describe("response", function()
      it("gets the correct upstream name in the response header", function()
        local r = assert(client:send {
          method = "GET",
          path = "/local",
          headers = {
            ["X-Country"] = "Italy",
          }
        })
        -- validate that the request succeeded, response status 200
        assert.response(r).has.status(200)
        -- now check the request (as echoed by mockbin) to have the header
        local header_value = assert.response(r).has.header("X-Upstream-Name")
        -- validate the value of that header
        assert.equal("europe_cluster", header_value)
      end)
    end)

  end)
end
