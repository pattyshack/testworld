function import(filename, from_module) -- without .lua
  dofile(
    minetest.get_modpath(from_module or minetest.get_current_modname()) ..
      "/" .. filename .. ".lua")
end
