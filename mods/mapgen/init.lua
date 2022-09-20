mapgen = {
}

minetest.register_alias("mapgen_stone", "stone:stone")
minetest.register_alias("mapgen_water_source", "water:water_source")
minetest.register_alias("mapgen_river_water_source", "water:river_water_source")

local logger = Logger()

-- TODO add biome spec

LayerSpec = Class()

-- min_depth / max_depth: The layer's depth for a given (X, Y) will be in
--  in the range [min_depth, max_depth], randomized by perlin noise.
--
-- weighted_node_list: list of {<positive int>,  <node name>} tuples.
--  The layer's nodes are chosen from this weighted list.
--
-- seed_offset: perlin noise and random generator are seeded with
--  map's seed + seed_offset.
function LayerSpec:_init(min_depth, max_depth, weighted_node_list, seed_offset)
  self.min_depth = min_depth
  self.max_depth = max_depth
  self.weighted_node_list = weighted_node_list
  self.seed_offset = seed_offset
end

LayerGenerator = Class()

function LayerGenerator:_init(layer_spec)
  local weighted_content_id_list = {}
  for idx, tuple in ipairs(layer_spec.weighted_node_list) do
    table.insert(
      weighted_content_id_list,
      {tuple[1], minetest.get_content_id(tuple[2])})
  end

  self.layer_spec = layer_spec

  self.random_generator = RandomGenerator(self.layer_spec.seed_offset)
  self.selectable = Selectable(weighted_content_id_list)

  self.depth_delta = layer_spec.max_depth - layer_spec.min_depth

  self.depth_noise = nil
  self.depth_noise_map = {}  -- perlin noise buffer
end

function LayerGenerator:reset(min_point, max_point, map_seed)
  self.random_generator:seed(
    map_seed,
    self.layer_spec.seed_offset,
    min_point.x,
    min_point.z,
    min_point.y)

  if self.depth_delta ~= 0 then
    self:reset_depth_noise(min_point, max_point, map_seed)
  end
end

function LayerGenerator:reset_depth_noise(min_point, max_point, map_seed)
  local width = max_point.x - min_point.x + 1
  local depth = max_point.z - min_point.z + 1
  local height = max_point.y - min_point.y + 1

  self.min_x = min_point.x
  self.min_y = min_point.z
  self.width = width

  if self.depth_noise == nil then
    local rand = PcgRandom(map_seed + self.layer_spec.seed_offset)
    -- randomize spread to reduce accidential amplitude resonance
    local spread = rand:next(32, 128)
    self.depth_noise = minetest.get_perlin_map(
        {
            offset = 0,
            scale  = 1,
            spread = {x = spread, y = spread, z = spread},
            seed = self.layer_spec.seed_offset,
            octaves = 2,
            persistence = 0.5,
            lacunarity = 2.0,
        },
        -- get_2d_map_flat uses the x, y coordinates, and ignore the z
        -- coordinate.
        { x = self.width, y = depth, z = height })
  end

  self.depth_noise:get_2d_map_flat(min_point, self.depth_noise_map)

  -- Note: it's not kosher to normalize the perlin noise this way, but this
  -- simplifies the depth calculuation and it's unlikely we'll notice the
  -- difference.  Revisit if artifact is jarring.
  local min = 100000
  local max = -100000
  for i = 0, width - 1 do
      for j = 0, depth - 1 do
          local idx = i * width + j + 1
          if self.depth_noise_map[idx] > max then
              max = self.depth_noise_map[idx]
          end

          if self.depth_noise_map[idx] < min then
              min = self.depth_noise_map[idx]
          end
      end
  end

  min = min
  max = max
  local diff = max - min
  for i = 0, width - 1 do
      for j = 0, depth - 1 do
          local idx = i * width + j + 1
          self.depth_noise_map[idx] = (self.depth_noise_map[idx] - min) / diff
      end
  end
end

function LayerGenerator:next_node()
  return self.random_generator:select(self.selectable)
end

function LayerGenerator:depth(x, y)
  if self.depth_delta == 0 then
    return self.layer_spec.min_depth
  end

  local idx = (x - self.min_x) * self.width + (y - self.min_y) + 1
  local rand_depth = math.floor(
    self.depth_delta * self.depth_noise_map[idx] + .5)

  return rand_depth + self.layer_spec.min_depth
end


soil_horizon = {
  -- organic
  LayerSpec(
    1,
    1,
    {
      {2995, "soil:dirt_with_grass"},
      {5, "stone:mossy_stone"},
    },
    12345),
  -- surface
  LayerSpec(
    1,
    3,
    {
      {2995, "soil:dirt"},
      {5, "stone:stone"},
    },
    23456)
  -- subsoil
  -- substratum
  -- bedrock
}

ForestSpec = Class()

-- forest_density in percentage basis points [0, 10000]
--
-- weighted_tree_list: list of {<positive int>,  <tree type name>} tuples.
--  The forest's trees are chosen from this weighted list.
--
function ForestSpec:_init(forest_density, weighted_tree_list, seed_offset)
  self.forest_density = forest_density
  self.weighted_tree_list = Selectable(weighted_tree_list)
  self.seed_offset = seed_offset
end

ForestGenerator = Class()

function ForestGenerator:_init(forest_spec)
  self.random = RandomGenerator(forest_spec.seed_offset)
  self.forest_spec = forest_spec
end

function ForestGenerator:seed(map_seed, x, y, z)
  self.random:seed(map_seed, self.forest_spec.seed_offset, x, y, z)
end

-- This return either nil (don't plant a tree) or a TreeSpec (plant a tree)
function ForestGenerator:next()
  local roll = self.random:next(1, 10000)
  if roll > self.forest_spec.forest_density then
    return nil
  end

  local tree_type = self.random:select(self.forest_spec.weighted_tree_list)
  local tree_spec = tree.species[tree_type]

  local idx = self.random:next(1, table.getn(tree_spec.prototypes))
  return tree_spec.prototypes[idx]
end

forest_spec = ForestSpec(
  50, -- 0.5%
  {
    {1, "Apple"},
  },
  42)

-- Using a singleton instead of a real class to enable (data, noise map, etc)
-- buffer reuse.
local map = {
  data = {},
}

function map:initialize(min_point, max_point, seed)
  local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
  local area = VoxelArea:new{MinEdge = emin, MaxEdge = emax}
  vm:get_data(self.data)

  self.seed = seed
  self.vm = vm
  self.area = area

  self.min_x = min_point.x
  self.min_y = min_point.z
  self.min_z = min_point.y

  self.max_x = max_point.x
  self.max_y = max_point.z
  self.max_z = max_point.y

  self.width = self.max_x - self.min_x + 1
  self.depth = self.max_y - self.min_y + 1
  self.height = self.max_z - self.min_z + 1

  self.water_level = minetest.get_mapgen_setting("water_level")

  if self.soil_horizon_layers == nil then
    self.soil_horizon_layers = {}
    for idx, spec in ipairs(soil_horizon) do
      table.insert(self.soil_horizon_layers, LayerGenerator(spec))
    end
  end

  for idx, layer in ipairs(self.soil_horizon_layers) do
    layer:reset(min_point, max_point, seed)
  end

  self.forest = self.forest or ForestGenerator(forest_spec)
end

function map:get(x, y, z)
    return self.data[self.area:index(x, z, y)]
end

function map:set(x, y, z, id)
    self.data[self.area:index(x, z, y)] = id
end

function map:update()
    self.vm:set_data(self.data)
    self.vm:calc_lighting()
    self.vm:write_to_map()
    self.vm:update_liquids()
end

minetest.register_on_generated(function(min_point, max_point, seed)
  map:initialize(min_point, max_point, seed)
  logger:v(1):debug("Generating (%s, %s, %s)", map.min_x, map.min_y, map.min_z)

  local air = minetest.CONTENT_AIR
  local stone = minetest.get_content_id("stone:stone")
  local water_source = minetest.get_content_id("water:water_source")
  local river_water_source = minetest.get_content_id("water:river_water_source")

  local trees = {}

  for x = map.min_x, map.max_x do
    for y = map.min_y, map.max_y do
      -- define is_underwater / is_surface out here to deal with "goto next_z"
      local is_underwater = false
      local is_surface = false

      local z = map.max_z
      while z >= map.min_z do
        -- TODO deal with under water/ subterranean surface

        if map:get(x, y, z) ~= stone then
          goto next_z
        end

        is_underwater = false
        is_surface = false
        if z + 1 <= map.max_z then
          local one_up_node = map:get(x, y, z + 1)

          is_underwater = one_up_node == water_source or
            one_up_node == river_water_source

          is_surface = one_up_node == air or is_underwater
        end

        if is_surface == false then
          goto next_z
        end

        if is_underwater == false then
          local tree_prototype = map.forest:next()
          if tree_prototype ~= nil then
            table.insert(trees, {{x, y, z}, tree_prototype})
          end
        end

        logger:v(2):debug("Found surface (%s, %s, %s)", x, y, z)
        for idx, layer in ipairs(map.soil_horizon_layers) do
          local depth = layer:depth(x, y)

          logger:v(3):debug(
            "(%s, %s %s) layer %s depth: %s",
            x,
            y,
            z,
            idx,
            depth)

          if depth == 0 then
            goto next_layer
          end

          for i = 1, depth do
            if map:get(x, y, z) ~= stone then
              goto next_z
            end


            local node = layer:next_node()
            logger:v(4):debug(
              "Convert (%s, %s, %s) to layer %s (%s)",
              x,
              y,
              z,
              idx,
              minetest.get_name_from_content_id(node))

            map:set(x, y, z, node)

            z = z - 1
            if z < map.min_z then
              goto next_xy
            end
          end

          ::next_layer::
        end

        ::next_z::
        z = z - 1
      end
      ::next_xy::
    end
  end

  -- generate tree trunks
  for treeIdx, entry in ipairs(trees) do
    local soil_x, soil_y, soil_z = entry[1][1], entry[1][2], entry[1][3]

    for nodeIdx, xyz_node_content in ipairs(entry[2][1]) do
      local coord = xyz_node_content[1]
      local x = coord[1] + soil_x
      local y = coord[2] + soil_y
      local z = coord[3] + soil_z

      if map:get(x, y, z) ~= air then
        goto continue
      end

      map:set(x, y, z, xyz_node_content[3])

      ::continue::
    end
  end

  -- generate leaves
  for treeIdx, entry in ipairs(trees) do
    local soil_x, soil_y, soil_z = entry[1][1], entry[1][2], entry[1][3]

    for nodeIdx, xyz_node_content in ipairs(entry[2][2]) do
      local coord = xyz_node_content[1]
      local x = coord[1] + soil_x
      local y = coord[2] + soil_y
      local z = coord[3] + soil_z

      if map:get(x, y, z) ~= air then
        goto continue
      end

      map:set(x, y, z, xyz_node_content[3])

      ::continue::
    end
  end

  map:update()
end)
