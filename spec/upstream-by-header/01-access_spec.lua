local helpers = require "spec.helpers"
local version = require("version").version or require("version")


local PLUGIN_NAME = "upstream-by-header"
local KONG_VERSION = version(select(3, assert(helpers.kong_exec("version"))))


for _, strategy in helpers.each_strategy() do
  describe(PLUGIN_NAME .. ": (access) [#" .. strategy .. "]", function()
    local client

    lazy_setup(function()
      local bp, service1
      local upstream1, upstream2, upstream3, upstream4, upstream5, upstream6

      if KONG_VERSION >= version("0.15.0") then
        --
        -- Kong version 0.15.0/1.0.0, new test helpers
        --
        bp = helpers.get_db_utils(strategy, nil, { PLUGIN_NAME })

        upstream1 = bp.upstreams:insert({
          name = "europe_cluster",
        })

        upstream2 = bp.upstreams:insert({
          name = "italy_cluster",
        })

        upstream3 = bp.upstreams:insert({
          name = "rome_cluster",
        })

        upstream4 = bp.upstreams:insert({
          name = "brazil_cluster",
        })

        upstream5 = bp.upstreams:insert({
          name = "italy_cache_cluster",
        })

        upstream6 = bp.upstreams:insert({
          name = "us_cluster",
        })

        bp.targets:insert({
          upstream = upstream1,
          target = "mockbin.org:80",
        })

        bp.targets:insert({
          upstream = upstream2,
          target = "httpbin.org:80",
        })

        bp.targets:insert({
          upstream = upstream3,
          target = "example.com:80",
        })

        bp.targets:insert({
          upstream = upstream4,
          target = "example.org:80",
        })

        bp.targets:insert({
          upstream = upstream5,
          target = "mockbin.org:80",
        })

        bp.targets:insert({
          upstream = upstream6,
          target = "mockbin.org:80",
        })

        -- default: requests to service1 will be sent to europe_cluster
        service1 = bp.services:insert({
          name = "service1",
          host = "europe_cluster",
          protocol = "http",
        })

        -- requests that match route "/local" will be proxied to europe_cluster
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
              {
                headers = {
                  ["X-Country"] = "Italy",
                  ["X-Regione"] = "Abruzzo",
                },
                upstream_name = "italy_cluster",
              },
              {
                headers = {
                  ["X-Country"] = "Italy",
                  ["X-Regione"] = "Rome",
                },
                upstream_name = "rome_cluster",
              },
              {
                headers = {
                  ["X-Country"] = "Brazil",
                  ["X-Regione"] = "Goiania",
                },
                upstream_name = "brazil_cluster",
              },
              {
                headers = {
                  ["X-Country"] = "Italy",
                  ["Connection"] = "close",
                },
                upstream_name = "italy_cache_cluster",
              },
              {
                headers = {
                  ["Accept-Language"] = "en-us",
                },
                upstream_name = "us_cluster",
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



    describe("Upstream response", function()
      it("checks if request with {X-Country = Italy} only must match rule with {X-Country = Italy} only", function()
        local r = assert(client:send {
          method = "GET",
          path = "/local",
          headers = {
            ["X-Country"] = "Italy",
          },
        })
        -- validate that the request succeeded, response status 200
        assert.response(r).has.status(200)
        -- now check the request (as echoed by mockbin) to have the header
        local header_value = assert.response(r).has.header("X-Upstream-Name")
        -- validate the value of that header
        assert.equal("europe_cluster", header_value)
      end)

      it("checks if request with {X-Country = Italy, X-Regione = Abruzzo} matches rule with {X-Country = Italy, X-Regione = Abruzzo}", function()
        local r = assert(client:send {
          method = "GET",
          path = "/local",
          headers = {
            ["X-Country"] = "Italy",
            ["X-Regione"] = "Abruzzo",
          },
        })
        -- validate that the request succeeded, response status 200
        assert.response(r).has.status(200)
        -- now check the request (as echoed by mockbin) to have the header
        local header_value = assert.response(r).has.header("X-Upstream-Name")
        -- validate the value of that header
        assert.equal("italy_cluster", header_value)
      end)

      it("checks if request with {X-Country = Italy, X-Regione = Rome} matches rule with {X-Country = Italy, X-Regione = Rome}", function()
        local r = assert(client:send {
          method = "GET",
          path = "/local",
          headers = {
            ["X-Country"] = "Italy",
            ["X-Regione"] = "Rome",
          },
        })
        -- validate that the request succeeded, response status 200
        assert.response(r).has.status(200)
        -- now check the request (as echoed by mockbin) to have the header
        local header_value = assert.response(r).has.header("X-Upstream-Name")
        -- validate the value of that header
        assert.equal("rome_cluster", header_value)
      end)
    end)

    it("checks if request with {X-Country = Brazil, X-Regione = Goiania} matches rule with {X-Country = Brazil, X-Regione = Goiania}", function()
      local r = assert(client:send {
        method = "GET",
        path = "/local",
        headers = {
          ["X-Country"] = "Brazil",
          ["X-Regione"] = "Goiania",
        },
      })
      -- validate that the request succeeded, response status 200
      assert.response(r).has.status(200)
      -- now check the request (as echoed by mockbin) to have the header
      local header_value = assert.response(r).has.header("X-Upstream-Name")
      -- validate the value of that header
      assert.equal("brazil_cluster", header_value)
    end)

    it("checks if request with {X-Country = Italy, Connection = close} matches rule with {X-Country = Italy, Connection = close}", function()
      local r = assert(client:send {
        method = "GET",
        path = "/local",
        headers = {
          ["X-Country"] = "Italy",
          ["Connection"] = "close",
        },
      })
      -- validate that the request succeeded, response status 200
      assert.response(r).has.status(200)
      -- now check the request (as echoed by mockbin) to have the header
      local header_value = assert.response(r).has.header("X-Upstream-Name")
      -- validate the value of that header
      assert.equal("italy_cache_cluster", header_value)
    end)

    it("checks if request with {Accept-Language = en-us} matches rule with {Accept-Language = en-us}", function()
      local r = assert(client:send {
        method = "GET",
        path = "/local",
        headers = {
          ["Accept-Language"] = "en-us",
        },
      })
      -- validate that the request succeeded, response status 200
      assert.response(r).has.status(200)
      -- now check the request (as echoed by mockbin) to have the header
      local header_value = assert.response(r).has.header("X-Upstream-Name")
      -- validate the value of that header
      assert.equal("us_cluster", header_value)
    end)

  end)
end
