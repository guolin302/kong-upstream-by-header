local typedefs = require "kong.db.schema.typedefs"

local headers_schema = {
  type = "map",
  keys = typedefs.header_name,
  values = { type = "string" }
}

local rules_schema = {
  type = "array",
  elements = {
    type = "record",
    fields = {
      { headers = headers_schema },
      { upstream_name = typedefs.host }
    }
  }
}

return {
  name = "upstream-by-header",
  fields = {
    { config = {
        type = "record",
        fields = {
          {rules = rules_schema}
        }
      }
    }
  }
}
