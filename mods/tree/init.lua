tree = {
  -- wood type
  SOFT = 1,
  HARD = 2,

  -- leaf type
  LEAFY = 1,
  NEEDLE = 2,
}

function tree.is_tree_trunk(def)
  return def["groups"]["tree_trunk"] == 1
end

local module = Module:new()

local function register_tree(tree_type, hardness, leaf_type, has_fruits)
  local choppy = 2
  local oddly_breakable_by_hand = 1
  if hardness == tree.HARD then
    choppy = 3
    oddly_breakable_by_hand = nil
  end

  local tree_name = tree_type .. " Tree"
  local thrunk_name = tree_name .. " Trunk"
  local tree_tile = module:name_to_default_tile(thrunk_name)
  local tree_top_tile = module:name_to_default_tile(thrunk_name .. " top")
  module:register_node(
    thrunk_name,
    {
      tiles = {tree_top_tile, tree_top_tile, tree_tile},
      is_ground_content = false,
      groups = {
        choppy = choppy,
        oddly_breakable_by_hand = oddly_breakable_by_hand,
        tree_hardness = hardness,
        tree_trunk = 1,
      },
      -- TODO: on_place rotate node
      -- TODO add flammable

      tree_type = tree_type,
    })

  local sapling_id = module:register_node(
    tree_name .. " Sapling",
    {
      drawtype = "plantlike",
      paramtype = "light",
      sunlight_propagates = true,
      walkable = false,
      is_ground_content = false,
      selection_box = {
        type = "fixed",
        fixed = {-4 / 16, -0.5, -4 / 16, 4 / 16, 7 / 16, 4 / 16}
      },
      groups = {
        snappy = 2,
        dig_immediate = 3,
        attached_node = 1,
        tree_sapling = 1,

        -- TODO add flammable
      },

      -- TODO add on_construct, on_timer, on_place for growing

      tree_type = tree_type,
    })

  local leaves_name = tree_name .. " Leaves"
  if leaf_type == tree.NEEDLE then
    leaves_name = tree_name .. " Needles"
  end

  local leaves_id = module:name_to_id(leaves_name)

  module:register_node(
    leaves_name,
    {
      drawtype = "allfaces_optional",
      waving = 2,
      paramtype = "light",
      is_ground_content = false,
      groups = {
        snappy = 3,
        tree_leaf_type = leaf_type,
        tree_leaves = 1,

        -- TODO add leave decay
        -- TODO add flammable
      },
      drop = {
        max_item = 1,
        items = {
          {
            items = {sapling_id},
            rarity = 20,
          },
          {
            items = {leaves_id},
          },
        },
      },

      -- TODO add after_plae_node = after_place_leaves

      tree_type = tree_type,
    })

  if has_fruits then
    module:register_node(
      tree_type,
      {
        drawtype = "plantlike",
        paramtype = "light",
        sunlight_propagates = true,
        walkable = false,
        is_ground_content = false,
        selection_box = {
          type = "fixed",
          fixed = {-3 / 16, -7 / 16, -3 / 16, 3 / 16, 4 / 16, 3 / 16}
        },
        groups = {
          fleshy = 3,
          dig_immediate = 3,
          tree_fruit = 1,
          -- TODO flammable
          -- TODO leafdecay
          -- TODO leafdecay_drop
        },

        -- TODO on_use eat
        -- TODO after_dig_node grow apple
        -- TODO after_place_node

        tree_type = tree_type,
      })
  end
end

register_tree("Apple", tree.SOFT, tree.LEAFY, true)
register_tree("Jungle", tree.SOFT, tree.LEAFY, false)
register_tree("Acacia", tree.SOFT, tree.LEAFY, false)
register_tree("Aspen", tree.HARD, tree.LEAFY, false)
register_tree("Pine", tree.HARD, tree.NEEDLE, false)
