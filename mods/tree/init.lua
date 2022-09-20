tree = {
  -- wood type
  SOFT = 1,
  HARD = 2,

  -- leaf type
  LEAFY = 1,
  NEEDLE = 2,

  module = Module(),

  -- tree type -> TreeSpec
  species = {},
}

import("nodes")
import("generators")

function tree.is_tree_trunk(def)
  return def["groups"]["tree_trunk"] == 1
end

TreeSpec = Class()

function TreeSpec:_init(
  tree_type,
  trunk_id,
  leaves_id,
  sapling_id,
  fruit_id,
  trunk_generator,
  leaves_generator,
  num_prototypes)

  self.tree_type = tree_type
  self.trunk_id = trunk_id
  self.leaves_id = leaves_id
  self.sapling_id = sapling_id
  self.fruit_id = fruit_id
  self.trunk_generator = trunk_generator
  self.leaves_generator = leaves_generator

  -- Pre-generate tree prototypes for reuse to speed up mapgen
  self.prototypes = {}
  if trunk_generator and leaves_generator then
    local trunk_content_id = minetest.get_content_id(trunk_id)

    for i = 1, num_prototypes do
      local trunks, tree_top = trunk_generator:generate_trunk()
      local leaves = leaves_generator:generate_leaves(
        trunks,
        tree_top,
        leaves_id,
        fruit_id)

      local occupied = {}

      local trunk_prototype = {}
      for idx, coord in ipairs(trunks) do
        table.insert(
          trunk_prototype,
          {coord, trunk_id, trunk_content_id})

        local x, y, z = coord[1], coord[2], coord[3]
        occupied[x] = occupied[x] or {}
        occupied[x][y] = occupied[x][y] or {}
        occupied[x][y][z] = 1
      end

      local leaves_prototype = {}
      for idx, coord_node in ipairs(leaves) do
        local coord = coord_node[1]
        local x, y, z = coord[1], coord[2], coord[3]
        if ((occupied[x] or {})[y] or {})[z] then
          goto continue
        end

        occupied[x] = occupied[x] or {}
        occupied[x][y] = occupied[x][y] or {}
        occupied[x][y][z] = 1

        table.insert(coord_node, minetest.get_content_id(coord_node[2]))
        table.insert(leaves_prototype, coord_node)

        ::continue::
      end

      table.insert(self.prototypes, {trunk_prototype, leaves_prototype})
    end
  end
end

local function register_tree(
  tree_type,
  hardness,
  leaf_type,
  has_fruits,
  trunk_generator,
  leaves_generator,
  num_prototypes)

  local trunk_id, leaves_id, sapling_id, fruit_id = register_tree_nodes(
    tree_type,
    hardness,
    leaf_type,
    has_fruits)

  tree.species[tree_type] = TreeSpec(
    tree_type,
    trunk_id,
    leaves_id,
    sapling_id,
    fruit_id,
    trunk_generator,
    leaves_generator,
    num_prototypes)
end

register_tree(
  "Apple",
  tree.SOFT,
  tree.LEAFY,
  true,
  SimpleTrunkGenerator(
    {
      {85, 5},
      {10, 6},
      {5, 4},
    },
    2),
  BoxLeavesGenerator(
    {
      {18, BoxLeavesSpec(5, 4, 2, 66, 3) },
      {1, BoxLeavesSpec(5, 5, 3, 66, 3) },
      {1, BoxLeavesSpec(5, 5, 2, 66, 3) },
    },
    2),
  200)

register_tree("Jungle", tree.SOFT, tree.LEAFY, false)
register_tree("Acacia", tree.SOFT, tree.LEAFY, false)
register_tree("Aspen", tree.HARD, tree.LEAFY, false)
register_tree("Pine", tree.HARD, tree.NEEDLE, false)
