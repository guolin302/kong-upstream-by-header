local typedefs = require "kong.db.schema.typedefs"

local headers_schema = {
  type = "map",
  required = true,
  keys = typedefs.header_name,
  values = { type = "string", }
}

local rules_schema = {
  type = "array",
  required = true,
  len_min = 1,
  elements = {
    type = "record",
    required = true,
    fields = {
      { headers = headers_schema, },
      { upstream_name = typedefs.host({ required = true }), },
    }
  }
}

return {
  name = "upstream-by-header",
  fields = {
    {
      config = {
        type = "record",
        required = true,
        fields = {
          {
            rules = rules_schema,
          },
        },
      },
    },
  },
}
