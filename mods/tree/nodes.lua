function register_trunk(tree_type, hardness)
  local choppy = 2
  local oddly_breakable_by_hand = 1
  if hardness == tree.HARD then
    choppy = 3
    oddly_breakable_by_hand = nil
  end

  local trunk_name = tree_type .. " Tree Trunk"
  local tree_tile = tree.module:name_to_default_tile(trunk_name)
  local tree_top_tile = tree.module:name_to_default_tile(trunk_name .. " top")

  return tree.module:register_node(
    trunk_name,
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
end

function register_sapling(tree_type)
  return tree.module:register_node(
    tree_type .. " Tree Sapling",
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
end

function register_leaves(tree_type, leaf_type, sapling_id)
  local leaves_name = tree_type .. " Tree Leaves"
  if leaf_type == tree.NEEDLE then
    leaves_name = tree_type .. " Tree Needles"
  end

  local leaves_id = tree.module:name_to_id(leaves_name)

  return tree.module:register_node(
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
end

function register_fruit(tree_type)
  return tree.module:register_node(
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

function register_tree_nodes(tree_type, hardness, leaf_type, has_fruits)
  local trunk_id = register_trunk(tree_type, hardness)
  local sapling_id = register_sapling(tree_type)
  local leaves_id = register_leaves(tree_type, leaf_type, sapling_id)

  local fruit_id = nil
  if has_fruits then
    fruit_id = register_fruit(tree_type)
  end

  return trunk_id, leaves_id, sapling_id, fruit_id
end
