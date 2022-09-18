soil = {
    -- dirt wetness:
    DAMP = 1,
    DRY = 2,

    -- dirt variant:
    RAW = 1,
    WITH_GRASS = 2,
    WITH_DRY_GRASS = 3,
    WITH_SNOW = 4,
    WITH_RAINFOREST_LITTER = 5,
    WITH_CONIFEROUS_LITTER = 6,
    WITH_GRASS_FOOTSTEPS = 7,
}

-- (suffix, top tile, side tile overlay)
local dirt_variant_params = {
    {}, -- raw
    {" With Grass", "soil_grass.png", "soil_grass_side.png"},
    {" With Dry Grass", "soil_dry_grass.png", "soil_dry_grass_side.png"},
    {" With Snow", "soil_snow.png", "soil_snow_side.png"},
    {" With Rainforest Litter", "soil_rainforest_litter.png", "soil_rainforest_litter_side.png"},
    {" With Coniferous Litter", "soil_coniferous_litter.png", "soil_coniferous_litter_side.png"},
    {" With Grass Footsteps", "soil_grass.png^soil_footsteps.png", "soil_grass_side.png"},
}

local module = Module()

local function register_dirt(dirt_name, wetness, additional_variants)
    local groups = {
        crumbly = 3,
        soil_dirt = 1,
        soil_dirt_wetness = wetness,
        soil_dirt_variant = soil.RAW,
    }

    local raw_dirt_id = module:register_node(
        dirt_name,
        {
            groups = groups,
            soil_dirt_type = dirt_name,
        })

    local dirt_tile = module:id_to_default_tile(raw_dirt_id)
    for i, variant in ipairs(additional_variants) do
        if variant == 1 or dirt_variant_params[variant] == nil then
            minetest.log(
                "error",
                "Unsupported additional variant type: " .. variant ..
                    " (soil: " .. dirt_name .. ")")

            goto continue
        end

        groups["soil_dirt_variant"] = variant

        local params = dirt_variant_params[variant]
        local suffix = params[1]
        local top_tile = params[2]
        local side_tile_overlay = params[3]

        module:register_node(
            dirt_name .. suffix,
            {
                tiles = {
                    top_tile,
                    dirt_tile, -- bottom
                    {
                        name = dirt_tile .. "^" .. side_tile_overlay,
                        tileable_vertical = false
                    },
                },
                groups = groups,
                drop = raw_dirt_id,
                soil_dirt_type = dirt_name,
            })

        ::continue::
    end
end

register_dirt(
    "Dirt",
    soil.DAMP,
    {
        soil.WITH_GRASS,
        soil.WITH_DRY_GRASS,
        soil.WITH_SNOW,
        soil.WITH_RAINFOREST_LITTER,
        soil.WITH_CONIFEROUS_LITTER,
        soil.WITH_GRASS_FOOTSTEPS,
    })
register_dirt("Dry Dirt", soil.DRY, {soil.WITH_DRY_GRASS})

local function register_sand(sand_name)
    module:register_node(
        sand_name,
        {
            groups = {
                crumbly = 3,
                falling_node = 1,
                soil_sand = 1,
            },
            soil_sand_type = sand_name,
        })
end

register_sand("Sand")
register_sand("Desert Sand")
register_sand("Silver Sand")

local clay_lump_id = module:register_craftitem(
    "Clay Lump",
    {
        groups = {
            soil_clay_lump = 1,
        },
    })

module:register_node(
    "Clay",
    {
        groups = {
            crumbly = 3,
        },
        drop = clay_lump_id .. " 4",
    })

local flint_id = module:register_craftitem(
    "Flint",
    {
        groups = {
            soil_flint = 1,
        },
    })

local gravel_id = module:name_to_id("Gravel")

module:register_node(
    "Gravel",
    {
        groups = {
            crumbly = 2,
            falling_node = 1,
            soil_gravel = 1,
        },
        drop = {
            max_items = 1,
            items = {
                {items = {flint_id}, rarity = 16},
                {items = {gravel_id}},
            },
        }
    })
