water = {
}

local module = Module:new()

local function register_water(water_type)
  local water_source = water_type .. " Source"
  local water_source_id = module:name_to_id(water_source)
  local flowing_water = "Flowing " .. water_type
  local flowing_water_id = module:name_to_id(flowing_water)

  -- River params:
  -- Not renewable to avoid horizontal spread of water sources in sloping
  -- rivers that can cause water to overflow riverbanks and cause floods.
  -- River water source is instead made renewable by the 'force renew'
  -- option used in the 'bucket' mod by the river water bucket.
  local liquid_renewable = false
  local liquid_range = 2
  local post_effect_color = {a = 103, r = 30, g = 76, b = 90}

  if water_type == "Water" then
    liquid_renewable = nil
    liquid_range = nil
    post_effect_color = {a = 103, r = 30, g = 60, b = 90}
  end

  local water_source_tile = module:name_to_default_tile(
    water_source .. " Animated")

  module:register_node(
    water_source,
    {
      drawtype = "liquid",
      waving = 3,
      tiles = {
        {
          name = water_source_tile,
          backface_culling = false,
          animation = {
            type = "vertical_frames",
            aspect_w = 16,
            aspect_h = 16,
            length = 2.0,
          },
        },
        {
          name = water_source_tile,
          backface_culling = true,
          animation = {
            type = "vertical_frames",
            aspect_w = 16,
            aspect_h = 16,
            length = 2.0,
          },
        },
      },
      use_texture_alpha = "blend",
      paramtype = "light",
      walkable = false,
      pointable = false,
      diggable = false,
      buildable_to = true,
      is_ground_content = false,
      drop = "",
      drowning = 1,
      liquidtype = "source",
      liquid_alternative_flowing = flowing_water_id,
      liquid_alternative_source = water_source_id,
      liquid_viscosity = 1,

      liquid_renewable = liquid_renewable,
      liquid_range = liquid_range,
      post_effect_color = post_effect_color,

      groups = {},

      water_type = water_type,
    })


  local flowing_water_tile = module:name_to_default_tile(
    flowing_water .. " Animated")

  module:register_node(
    flowing_water,
    {
      drawtype = "flowingliquid",
      waving = 3,
      tiles = {module:name_to_default_tile(water_type)},
      special_tiles = {
        {
          name = flowing_water_tile,
          backface_culling = false,
          animation = {
            type = "vertical_frames",
            aspect_w = 16,
            aspect_h = 16,
            length = 0.5,
          },
        },
        {
          name = flowing_water_tile,
          backface_culling = true,
          animation = {
            type = "vertical_frames",
            aspect_w = 16,
            aspect_h = 16,
            length = 0.5,
          },
        },
      },
      use_texture_alpha = "blend",
      paramtype = "light",
      paramtype2 = "flowingliquid",
      walkable = false,
      pointable = false,
      diggable = false,
      buildable_to = true,
      is_ground_content = false,
      drop = "",
      drowning = 1,
      liquidtype = "flowing",
      liquid_alternative_flowing = flowing_water_id,
      liquid_alternative_source = water_source_id,
      liquid_viscosity = 1,

      liquid_renewable = liquid_renewable,
      liquid_range = liquid_range,
      post_effect_color = post_effect_color,

      groups = {
        not_in_creative_inventory = 1,
      },

      water_type = water_type,
    })
end

register_water("Water")
register_water("River water")
