local schema_def = require("kong.plugins.upstream-by-header.schema")
local v = require("spec.helpers").validate_plugin_config_schema

describe("Plugin: upstream-by-header (schema)", function()
  it("validates header name", function()
    local config = {
      rules = {
        {
          headers = {
            ["X-Region!"] = "Italy",
          },
          upstream_name = "italy_cluster",
        },
      },
    }
    local ok, err = v(config, schema_def)
    assert.falsy(ok)
    assert.equal("bad header name 'X-Region!', allowed characters are A-Z, a-z, 0-9, '_', and '-'", err.config.rules[1].headers)
  end)

  it("validates upstream", function()
    local config = {
      rules = {
        {
          headers = {
            ["X-Country"] = "Italy",
          },
          upstream_name = "123",
        },
      },
    }
    local ok, err = v(config, schema_def)
    assert.falsy(ok)
    assert.equal("invalid value: 123", err.config.rules[1].upstream_name)
    --print(require("spec.helpers").intercept(err.config.rules[1].upstream_name))
  end)

  it("validates schema structure", function()
    local config = {
      rules = {
        {
          headers = {
            ["X-Country"] = "Italy"
          },
          upstream_name = "italy_cluster"
        }
      }
    }

    local ok, err = v(config, schema_def)
    assert.truthy(ok)
    assert.is_nil(err)
  end)

  it("validates required config object", function()
    local config = nil
    local ok, err = v(config, schema_def)
    assert.falsy(ok)
    assert.equal("required field missing", err.config.rules)
  end)

  it("validates required `rules` field", function()
    local config = {}
    local ok, err = v(config, schema_def)
    assert.falsy(ok)
    assert.equal("required field missing", err.config.rules)
  end)

  it("`rules` field must have at least one record", function()
    local config = {
      rules = {
      }
    }
    local ok, err = v(config, schema_def)
    assert.falsy(ok)
    assert.equal("length must be at least 1", err.config.rules)
  end)

  it("rule record (headers and upstream_name) field missing", function()
    local config = {
      rules = {
        {

        }
      }
    }
    local ok, err = v(config, schema_def)
    assert.falsy(ok)
    assert.equal("required field missing", err.config.rules[1].headers)
    assert.equal("required field missing", err.config.rules[1].upstream_name)
  end)
end)
