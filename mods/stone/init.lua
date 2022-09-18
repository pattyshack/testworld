stone = {
  -- hardness:
  SOFT = 1,
  HARD = 2,
  OBSIDIAN = 3,

  -- variant:
  RAW = 1,
  BLOCK = 2,
  BRICK = 3,
  COBBLE = 4,
  MOSSY_RAW = 5,
  MOSSY_COBBLE = 6,
}

local module = Module()

function stone.is_raw_hard_stone(def)
  return def["groups"]["stone_hardness"] == stone.HARD and
    def["groups"]["stone_variant"] == stone.RAW
end

local function register_stone(stone_name, hardness, has_mossy_variants)
  local groups = {
    cracky = 3,
    stone_hardness = hardness,
    stone_variant = stone.RAW,
  }
  local cobble_drop = nil
  local mossy_cobble_drop = nil
  if hardness == stone.SOFT then
    groups["crumbly"] = 1
  elseif hardness == stone.HARD then
    cobble_drop = module:name_to_id(stone_name .. " Cobble")
    mossy_cobble_drop = module:name_to_id("Mossy " .. stone_name .. " Cobble")
  elseif hardness == stone.OBSIDIAN then
    groups["cracky"] = 1
    groups["level"] = 2
  else
    module.logger:err(
      "Unknown hardness type: %s (stone: %s)",
      hardness,
      stone_name)
  end

  module:register_node(
    stone_name,
    {
      groups = groups,
      drop = cobble_drop,
      stone_type = stone_name,
    })

  groups["crumbly"] = nil

  local non_ground_params = {
    is_ground_content = false,
    groups = groups,
    stone_type = stone_name,
  }

  if hardness == stone.HARD then
    groups["stone_variant"] = stone.COBBLE
    module:register_node(stone_name .. " Cobble", non_ground_params)

    if has_mossy_variants then
      groups["stone_variant"] = stone.MOSSY_RAW
      module:register_node(
        "Mossy " .. stone_name,
        {
          groups = groups,
          drop = mossy_cobble_drop,
          stone_type = stone_name,
        })

      groups["stone_variant"] = stone.MOSSY_COBBLE
      module:register_node(
        "Mossy " .. stone_name .. " Cobble",
        non_ground_params)
    end
  end

  if hardness ~= stone.OBSIDIAN then
    groups["cracky"] = 2
  end

  groups["stone_variant"] = stone.BLOCK
  module:register_node(stone_name .. " Block", non_ground_params)

  groups["stone_variant"] = stone.BRICK
  module:register_node(stone_name .. " Brick", non_ground_params)
end

for i, v in ipairs({"Sandstone", "Desert Sandstone", "Silver Sandstone"}) do
  register_stone(v, stone.SOFT)
end

register_stone("Stone", stone.HARD, true)
register_stone("Desert Stone", stone.HARD)

register_stone("Obsidian", stone.OBSIDIAN)
