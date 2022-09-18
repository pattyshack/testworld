-- Based on http://lua-users.org/wiki/ObjectOrientationTutorial "Class creation
-- function", except this does not support multiple inheritance (the tutorial
-- does not correctly handle conflicting method signatures), and does not
-- support is_a.
function Class(BaseClass)
  local class = {}

  -- copy all contents from base class
  for k, v in pairs(BaseClass or {}) do
    if k ~= "__index" then
      class[k] = v
    end
  end

  class.__index = class

  setmetatable(
    class,
    {
      __call = function(cls, ...)
        local instance = setmetatable({}, cls)

        local init = instance._init
        if init then
          init(instance, ...)
        end

        return instance
      end,
    })

  return class
end
