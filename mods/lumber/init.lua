wood = {
}

local module = Module:new()

local function register_lumber(trunk_def)
  local trunk_groups = trunk_def["groups"]
  local tree_type = trunk_def["tree_type"]
  module:register_node(
    tree_type .. " Wood Planks",
    {
      is_group_content = false,
      groups = {
        choppy = trunk_groups["choppy"],
        oddly_breakable_by_hand = trunk_groups["oddly_breakable_by_hand"],
        -- TODO flammable
        lumber_planks = 1,
      },

      lumber_type = tree_type,
    })
end

for id, params in pairs(base.list_all_registered(tree.is_tree_trunk)) do
  register_lumber(params)
end
