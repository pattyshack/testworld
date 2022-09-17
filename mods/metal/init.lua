metal = {
}

local module = Module:new()

local function register_metal(metal_name)
  module:register_craftitem(
    metal_name .. " Ingot",
    {
      groups = {
        metal_ingot = 1,
      },
      metal_name = metal_name,
    })

  module:register_node(
    metal_name .. " Block",
    {
      is_ground_content = false,
      groups = {
        cracky = 1,
        level = 2,
        metal_block = 1,
      },
      metal_name = metal_name,
    })
end

for id, def in pairs(base.list_all_registered(ore.is_metal_lump)) do
  register_metal(def["ore_name"])
end
