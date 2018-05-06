local Errors          = require "kong.dao.errors"
local index_of  = require("array").index_of
local table_insert    = table.insert
local table_concat    = table.concat
local json_encode     = require("cjson").encode


function test_first_constructor(first_constr)

  -- check that there isn't one empty argument
  if not first_constr then
    do return false, [[Empty argument not allowed. ..
                      Remove last comma or duplicate commas]] end
  end

  -- check that the first constructor is a supported value
  local enum = {"fix","method","headers","paths","querystring","body"}
  if index_of(enum, first_constr) == -1 then
    do return false, first_constr .. [[ not recognized.
                    Must be one of: ]] .. table_concat(enum, ", ") end
  end

  return true
end


function test_second_constructor(first_constr, second_constr)

  if first_constr == "method" and second_constr then
    do return false, first_constr .. " is a string not, iterable" end
  end

  if (first_constr == "querystring"
      or first_constr == "headers" )
  and second_constr:match("%d") then
    do return false, first_constr .. " is an object, can't be parsed by index" end
  end

  return true
end


function test_third_constructor(first_constr, third_constr)

  if (first_constr == "paths"
      or first_constr == "headers"
      or first_constr == "querystring")
  and third_constr ~= nil then
    do return false, first_constr .. " can't have a third constructor." end
  end

  return true
end


-- validate the argumens constructors:
function test_argument(argument)

  local constructors = {}
  for constructor in argument:gmatch("[^%.]+") do
    table_insert(constructors, constructor)
  end

  -- Validate the first constructor.
  local ok, msg = test_first_constructor(constructors[1])
  if not ok then
    do return ok, msg end
  end

  -- Validate the second constructor.
  local ok, msg = test_second_constructor(constructors[1], constructors[2])
  if not ok then
    do return ok, msg end
  end

  -- Validate the third constructor.
  local ok, msg = test_third_constructor(constructors[1], constructors[3])
  if not ok then do
    return ok, msg end
  end

end

function test_string(string)
  if string then
    return test_argument(string)
  end
  return true
end

function test_array(array)
  if array then
    for _,argument in ipairs(array) do
      return test_argument(argument)
    end
  end
  return true
end


return {
  fields = {
    google_service_token =  {type = "string",                    },
    script_id =             {type = "string", required = true,   },
    function_name =         {type = "string", func = test_name,  },
    function_arguments =    {type = "array",  func = test_array, },
    get = {
      type = "table",
      schema = {
        fields = {
          function_name =       {type = "string", func = test_string, },
          function_arguments =  {type = "array",  func = test_array   },
        }
      }
    },
    post = {
      type = "table",
      schema = {
        fields = {
          function_name =       {type = "string", func = test_string, },
          function_arguments =  {type = "array",  func = test_array   },
        }
      }
    },
    put = {
      type = "table",
      schema = {
        fields = {
          function_name =       {type = "string", func = test_string, },
          function_arguments =  {type = "array",  func = test_array   },
        }
      }
    },
    patch = {
      type = "table",
      schema = {
        fields = {
          function_name =       {type = "string", func = test_string, },
          function_arguments =  {type = "array",  func = test_array   },
        }
      }
    },
    delete = {
      type = "table",
      schema = {
        fields = {
          function_name =       {type = "string", func = test_string, },
          function_arguments =  {type = "array",  func = test_array   },
        }
      }
    }
  },
  no_consumer = true,
  self_check = function(schema, plugin_t, dao, is_updating)

    -- check that at least one function is defined
    if not plugin_t.function_name
    and not plugin_t.get.function_name
    and not plugin_t.post.function_name
    and not plugin_t.put.function_name
    and not plugin_t.patch.function_name
    and not plugin_t.delete.function_name
    then
      return false, Errors.schema "You must set at least one function"
    end

    return true
  end
}
