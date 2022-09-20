-- All tree generation coordinates are relative to the tree's root soil node,
-- (0, 0, 0).  mapgen, etc will perform the necessary affine transformation to
-- convert the tree generation coordinates back to map coordinates.

AbstractTreeGenerator = Class()

function AbstractTreeGenerator:_init(seed)
  self.seed = seed
  self.random = RandomGenerator(seed)
end

AbstractTrunkGenerator = Class(AbstractTreeGenerator)

-- This return a list of coordinates where the tree trunk should be
-- generated, and the tree top centroid coordinate to be used for leaves
-- generation (a trunk node need not be placed at the centroid coordinate).
function AbstractTrunkGenerator:generate_trunk()
  assert(false, "Not implemented")
end

AbstractLeavesGenerator = Class(AbstractTreeGenerator)

-- This return a list of (coordinate, node_id) where the tree leaves and
-- fruits should be generated.
--
-- Note:
--  1. The list may include all types of node_id.
--  2. The coordinates may overlap trunk coordinates.  Trunk placement always
--     have higher priority than leaves/fruits.
function AbstractLeavesGenerator:generate_leaves(
  trunk_coordinates,
  tree_top_centroid_coordinate,
  leaves_node_id,
  fruit_node_id)

  assert(false, "Not implemented")
end

SimpleTrunkGenerator = Class(AbstractTrunkGenerator)

-- SimpleTrunkGenerator generates a straight trunk based on a given
-- weighted height list.
function SimpleTrunkGenerator:_init(weighted_height_list, seed)
  AbstractTrunkGenerator._init(self, seed)
  self.weighted_height_list = Selectable(weighted_height_list)
end

function SimpleTrunkGenerator:generate_trunk()
  local height = self.random:select(self.weighted_height_list)

  local trunk = {}
  for i = 1, height do
    table.insert(
      trunk,
      {0, 0, i})
  end

  return trunk, {0, 0, height}
end

BoxLeavesSpec = Class()

-- Generate leaves/fruits inside a (length x length x height) box, centered
-- at (centroid.x, centroid.y, centroid.z - height_drop).
--
-- length must be a positive odd integer.
-- height must be a positive integer.
-- height_drop should be an integer (could be negative)
-- leaves_density and fruit_density are in percentages [0, 100].
function BoxLeavesSpec:_init(
  length,
  height,
  height_drop,
  leaves_density,
  fruit_density)

  assert(length > 0, "length must be positive")
  assert(math.floor(length / 2) * 2 + 1 == length, "length must be odd")
  assert(height > 0, "height must be positive")

  self.length = length
  self.height = height
  self.height_drop = height_drop

  local density = leaves_density + fruit_density
  assert(0 <= density and density <= 100, "Invalid density")

  local air_density = 100 - density

  self.weighted_node_density_list = Selectable({
      {leaves_density, 1},
      {fruit_density, 2},
      {air_density, 3},
    })
end

BoxLeavesGenerator = Class(AbstractLeavesGenerator)

function BoxLeavesGenerator:_init(
  weighted_box_leaves_spec_list,
  seed)

  AbstractLeavesGenerator._init(self, seed)
  self.weighted_box_leaves_spec_list = Selectable(weighted_box_leaves_spec_list)
end

-- BoxLeavesGenerator generates leaves/fruits inside a box selected from a
-- weighted_box_tree_spec_list.
function BoxLeavesGenerator:generate_leaves(
  trunk_coordinates,
  tree_top_centroid_coordinate,
  leaves_node_id,
  fruit_node_id)

  local box_spec = self.random:select(self.weighted_box_leaves_spec_list)

  local result = {}

  local bottom = tree_top_centroid_coordinate[3] - box_spec.height_drop
  local dl = (box_spec.length - 1) / 2
  for x = -dl, dl do
    for y = -dl, dl do
      for z = bottom, bottom + box_spec.height - 1 do

        local node_type = self.random:select(
          box_spec.weighted_node_density_list)

        if node_type == 1 then
          table.insert(result, {{x, y, z}, leaves_node_id})
        elseif node_type == 2 and fruit_node_id then
          table.insert(result, {{x, y, z}, fruit_node_id})
        end
      end
    end
  end

  return result
end
