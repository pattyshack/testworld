ore = {
    -- ore type
    COAL = 1,
    METAL = 2,
    -- TODO GEM
}

function ore.is_metal_lump(def)
  return def["groups"]["ore_type"] == ore.METAL and
    def["groups"]["ore_lump"] == 1
end

local module = Module()

local function register_ore(stone_id, stone_def, ore_name, ore_type)
  local stone_tile = module:id_to_default_tile(stone_id)
  local ore_tile = module:name_to_default_tile("Mineral " .. ore_name)

  local stone_groups = stone_def["groups"]
  module:register_node(
    stone_def["description"] .. " With " .. ore_name .. " Ore",
    {
      tiles = {stone_tile .. "^" .. ore_tile},
      groups = {
        cracky = stone_groups["cracky"],
        ore_type = ore_type,
        ore_mineral = 1,
      },
      drop = module:name_to_id(ore_name .. " Lump"),
      ore_name = ore_name,
    })
end

local ore_types = {
  Coal = ore.COAL,
  Iron = ore.METAL,
  Copper = ore.METAL,
  Tin = ore.METAL,
  Gold = ore.METAL,
}

for ore_name, ore_type in pairs(ore_types) do
  module:register_craftitem(
    ore_name .. " Lump",
    {
      groups = {
        ore_type = ore_type,
        ore_lump = 1,
      },
      ore_name = ore_name,
    })
end

for id, params in pairs(base.list_all_registered(stone.is_raw_hard_stone)) do
  for ore_name, ore_type in pairs(ore_types) do
    register_ore(id, params, ore_name, ore_type)
  end
end

module:register_node(
  "Coal Block",
  {
    is_ground_content = false,
    groups = {
      cracky = 3,
    },
  })
