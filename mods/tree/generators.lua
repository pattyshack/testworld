-- All tree generation coordinates are relative to the tree's root soil node,
-- (0, 0, 0).  mapgen, etc will perform the necessary affine transformation to
-- convert the tree generation coordinates back to map coordinates.

AbstractTreeGenerator = Class()

function AbstractTreeGenerator:_init(weighted_spec_list, seed)
  self.seed = seed
  self.random = RandomGenerator(seed)
  self.weighted_spec_list = Selectable(weighted_spec_list)
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
function SimpleTrunkGenerator:generate_trunk()
  local height = self.random:select(self.weighted_spec_list)

  local trunk = {}
  for i = 1, height do
    table.insert(
      trunk,
      {0, 0, i})
  end

  return trunk, {0, 0, height}
end

CompositeLeavesGenerator = Class(AbstractLeavesGenerator)

-- CompositeLeavesGenerator randomly select a leaves generator from its
-- weighted_spec_list, and generate leaves/fruits using that generator.
function CompositeLeavesGenerator:generate_leaves(
  trunk_coordinates,
  tree_top_centroid_coordinate,
  leaves_node_id,
  fruit_node_id)

  local generator = self.random:select(self.weighted_spec_list)
  return generator:generate_leaves(
    trunk_coordinates,
    tree_top_centroid_coordinate,
    leaves_node_id,
    fruit_node_id)
end


ColumnLeavesSpec = Class()

-- Generate leaves/fruits inside a column, centered at
-- (centroid.x, centroid.y, centroid.z - height_drop).
--
-- radius (aka half length for box) must be a positive integer.
-- height must be a positive integer.
-- height_drop should be an integer (could be negative)
-- leaves_density and fruit_density are in percentages [0, 100].
--
-- Column types:
-- 1. Box.  The box's corners are
--    (-radius + 1, -radius + 1), (radius - 1, radius -1)
-- 2. Diagonal Box (L1 distance):
--    |x| + |y| < radius
-- 3. Cylinder (L2 distance):
--    x^2 + y^2 < radius^2
function ColumnLeavesSpec:_init(
  radius,
  height,
  height_drop,
  leaves_density,
  fruit_density)

  assert(radius > 0, "radius must be positive")
  assert(height > 0, "height must be positive")

  self.radius = radius
  self.height = height
  self.height_drop = height_drop

  local density = leaves_density + fruit_density
  assert(0 <= density and density <= 100, "Invalid density")

  local air_density = 100 - density

  self.weighted_node_list = Selectable({
      {leaves_density, 1},
      {fruit_density, 2},
      {air_density, 3},
    })
end

BoxLeavesGenerator = Class(AbstractLeavesGenerator)

-- BoxLeavesGenerator generates leaves/fruits inside a box selected from a
-- weighted_column_tree_spec_list.
function BoxLeavesGenerator:generate_leaves(
  trunk_coordinates,
  tree_top_centroid_coordinate,
  leaves_node_id,
  fruit_node_id)

  local spec = self.random:select(self.weighted_spec_list)

  local result = {}

  local bottom = tree_top_centroid_coordinate[3] - spec.height_drop
  local dl = spec.radius - 1
  for x = -dl, dl do
    for y = -dl, dl do
      for z = bottom, bottom + spec.height - 1 do

        local node_type = self.random:select(spec.weighted_node_list)

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

DiagonalBoxLeavesGenerator = Class(AbstractLeavesGenerator)

-- DiagonalBoxLeavesGenerator generates leaves/fruits inside a diagonal box
-- selected from a weighted_column_tree_spec_list.
function DiagonalBoxLeavesGenerator:generate_leaves(
  trunk_coordinates,
  tree_top_centroid_coordinate,
  leaves_node_id,
  fruit_node_id)

  local spec = self.random:select(self.weighted_spec_list)

  local result = {}

  local bottom = tree_top_centroid_coordinate[3] - spec.height_drop
  local dl = spec.radius - 1
  for x = -dl, dl do
    local abs_x = math.abs(x)

    for y = -dl, dl do
      if abs_x + math.abs(y) >= spec.radius then
        goto continue
      end

      for z = bottom, bottom + spec.height - 1 do
        local node_type = self.random:select(spec.weighted_node_list)

        if node_type == 1 then
          table.insert(result, {{x, y, z}, leaves_node_id})
        elseif node_type == 2 and fruit_node_id then
          table.insert(result, {{x, y, z}, fruit_node_id})
        end
      end

      ::continue::
    end
  end

  return result
end

CylinderLeavesGenerator = Class(AbstractLeavesGenerator)

-- CylinderLeavesGenerator generates leaves/fruits inside a cylinder
-- selected from a weighted_column_tree_spec_list.
function CylinderLeavesGenerator:generate_leaves(
  trunk_coordinates,
  tree_top_centroid_coordinate,
  leaves_node_id,
  fruit_node_id)

  local spec = self.random:select(self.weighted_spec_list)

  local result = {}

  local bottom = tree_top_centroid_coordinate[3] - spec.height_drop
  local dl = spec.radius - 1
  local r2 = spec.radius * spec.radius

  for x = -dl, dl do
    local x2 = x * x

    for y = -dl, dl do
      if x2 + y*y >= r2 then
        goto continue
      end

      for z = bottom, bottom + spec.height - 1 do
        local node_type = self.random:select(spec.weighted_node_list)

        if node_type == 1 then
          table.insert(result, {{x, y, z}, leaves_node_id})
        elseif node_type == 2 and fruit_node_id then
          table.insert(result, {{x, y, z}, fruit_node_id})
        end
      end

      ::continue::
    end
  end

  return result
end

EllipsoidLeavesSpec = Class()

-- Generate leaves/fruits inside a ellipsoid, centered at
-- (centroid.x, centroid.y, centroid.z - height_drop).
--
-- The ellipsoid is defined by
--    x^2 / a^2 + y^2 / b^2 + z^2 / c^2 <= 1
-- with points (a, 0, 0), (0, b, 0), (0, 0, c) lie on the surface
-- (see https://en.wikipedia.org/wiki/Ellipsoid)
--
-- a, b, c must be positive real numbers
-- height_drop should be an integer (could be negative)
-- leaves_density and fruit_density are in percentages [0, 100].
function EllipsoidLeavesSpec:_init(
  a,
  b,
  c,
  height_drop,
  leaves_density,
  fruit_density)

  assert(a > 0, "radius must be positive")
  assert(b > 0, "radius must be positive")
  assert(c > 0, "radius must be positive")

  self.a = a
  self.b = b
  self.c = c
  self.height_drop = height_drop

  local density = leaves_density + fruit_density
  assert(0 <= density and density <= 100, "Invalid density")

  local air_density = 100 - density

  self.weighted_node_list = Selectable({
      {leaves_density, 1},
      {fruit_density, 2},
      {air_density, 3},
    })
end

EllipsoidLeavesGenerator = Class(AbstractLeavesGenerator)

-- EllipsoidLeavesGenerator generates leaves/fruits inside a cylinder
-- selected from a weighted_column_tree_spec_list.
function EllipsoidLeavesGenerator:generate_leaves(
  trunk_coordinates,
  tree_top_centroid_coordinate,
  leaves_node_id,
  fruit_node_id)

  local spec = self.random:select(self.weighted_spec_list)

  local result = {}

  local dx = tree_top_centroid_coordinate[1]
  local dy = tree_top_centroid_coordinate[2]
  local dz = tree_top_centroid_coordinate[3] - spec.height_drop

  local ai = math.floor(spec.a + .5)
  local bi = math.floor(spec.b + .5)
  local ci = math.floor(spec.c + .5)

  local a2 = spec.a * spec.a
  local b2 = spec.b * spec.b
  local c2 = spec.c * spec.c

  for x = -ai, ai do
    local normalized_x2 = (x * x) / a2

    for y = -bi, bi do
      local normalized_y2 = (y * y) / b2

      for z = -ci, ci do
        local normalized_z2 = (z * z) / c2

        if normalized_x2 + normalized_y2 + normalized_z2 > 1 then
          goto continue
        end

        local coord = {x + dx, y + dy, z + dz}
        local node_type = self.random:select(spec.weighted_node_list)

        if node_type == 1 then
          table.insert(result, {coord, leaves_node_id})
        elseif node_type == 2 and fruit_node_id then
          table.insert(result, {coord, fruit_node_id})
        end

        ::continue::
      end
    end
  end

  return result
end

