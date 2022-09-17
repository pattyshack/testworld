base = {
  registered = {},
}

function base.deep_copy(value)
  if type(value) ~= "table" then
    return value
  end

  local ret = {}
  for k, v in pairs(value) do
    ret[k] = base.deep_copy(v)
  end

  return ret
end

function base.list_all_registered(predicate)
  local result = {}
  for id, params in pairs(base.registered) do
    if predicate(params) then
      result[id] = params
    end
  end

  return result
end

Module = {}

function Module:new(module_name)
  module_name = module_name or minetest.get_current_modname()

  local module = {}
  setmetatable(module, self)
  self.__index = self

  self.module_name = module_name or minetest.get_current_modname()
  self.logger = Logger:new(self.module_name)

  return module
end

function Module:name_to_id(name)
  return self.module_name .. ":" .. string.gsub(string.lower(name), " ", "_")
end

function Module:id_to_default_tile(id)
  return string.gsub(id, ":", "_") .. ".png"
end

function Module:name_to_default_tile(name)
  self:id_to_default_tile(self:name_to_id(name))
end

function Module:_populate_missing_params(name, params, item_type)
  local id = self:name_to_id(name)

  params = base.deep_copy(params)

  params["id"] = id

  if params["description"] == nil then
    params["description"] = name
  end

  if params["groups"] == nil then
    params["groups"] = {}
  end

  params["groups"][self.module_name] = 1
  params["groups"][item_type] = 1

  if item_type == "node" and params["tiles"] == nil then
    params["tiles"] = { self:id_to_default_tile(id) }
  end

  if item_type == "craftitem" and params["inventory_image"] == nil then
    params["inventory_image"] = self:id_to_default_tile(id)
  end

  return params
end

function Module:_register(name, params, item_type, register_func)
  params = Module:_populate_missing_params(name, params, item_type)

  local id = params["id"]

  self.logger:debug("register_" .. item_type .. ": " .. id)
  self.logger:v(1):pretty_log_value(params)

  if base.registered[id] ~= nil then
    self.logger:err("Registering duplicate node: " .. id)
  end
  base.registered[id] = params

  register_func(id, params)
  return id
end

function Module:register_node(name, params)
  return self:_register(name, params, "node", minetest.register_node)
end

function Module:register_craftitem(name, params)
  return self:_register(name, params, "craftitem", minetest.register_craftitem)
end
