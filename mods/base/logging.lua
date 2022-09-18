Logger = Class({
  -- log level
  DEBUG = 1,
  INFO = 2,
  WARN = 3,
  ERR = 4,

  -- module name -> debug verbose log level
  --
  -- if the module name is unspecified, default's value is used
  --
  -- levels:
  --  -1  - disable debug logging
  --  0   - standard debug logging
  --  1   - detailed debug logging
  --  2   - even more detailed debug logging
  --  and so on ...
  debug_log_level_map = {
    default = -1,  -- default level

    -- base = 1,
    -- lumber = 1,
    -- metal = 1,
    -- ore = 1,
    -- soil = 1,
    -- stone = 1,
    -- tree = 1,
    -- water = 1,
  }
})

function Logger:_init(module_name)
  self.module_name = module_name or minetest.get_current_modname()
end

function Logger:debug_log_level()
  local level = self.debug_log_level_map[self.module_name]
  if level ~= nil then
    return level
  end

  return self.debug_log_level_map["default"]
end

function Logger:should_log_debug(verbose_level)
  return self:debug_log_level() >= verbose_level
end

function Logger:verbose(verbose_level, template, ...)
  if self:should_log_debug(verbose_level) then
    minetest.log(
      "none",
      "DEBUG[" .. self.module_name .. "]: " ..
        string.format(template, ...))
  end
end

function Logger:debug(template, ...)
  self:verbose(0, template, ...)
end

function Logger:info(template, ...)
  minetest.log(
    "none", -- "info" doesn't work ...
    "INFO[".. self.module_name .."]: " .. string.format(template, ...))
end

function Logger:warn(template, ...)
  minetest.log(
    "warning",
    "[".. self.module_name .."]: " .. string.format(template, ...))
end

function Logger:err(template, ...)
  minetest.log(
    "error",
    "[".. self.module_name .."]: " .. string.format(template, ...))
end

function Logger:log(log_level, template, ...)
  if log_level == Logger.DEBUG then
    self:debug(template, ...)
  elseif log_level == Logger.INFO then
    self:info(template, ...)
  elseif log_level == Logger.WARN then
    self:warn(template, ...)
  elseif log_level == Logger.ERR then
    self:err(template, ...)
  else
    minetest.log(
      "none", -- "info" doesn't work ...
      "UNKNOWN(".. log_level .. ")[".. self.module_name .."]: " ..
        string.format(template, ...))
  end
end

function Logger:_pretty_log_value(log_level, value, indent, prefix)
  if type(value) == "table" then
    self:log(log_level, "%s%s{", indent, prefix)
    for k, v in pairs(value) do
      self:_pretty_log_value(log_level, v, indent .. "    ", k .. " = ")
    end
    self:log(log_level, indent .. "},")
  else
    self:log(log_level, "%s%s%s,", indent, prefix, value)
  end
end

function Logger:pretty_log_value(log_level, value)
  self:_pretty_log_value(log_level, value, "    ", "")
end

function Logger:v(verbose_level)
  return VerboseDebugLogger(self, verbose_level)
end

VerboseDebugLogger = Class()

function VerboseDebugLogger:_init(logger, verbose_level)
  self.logger = logger
  self.verbose_level = verbose_level
end

function VerboseDebugLogger:should_log()
  return self.logger:should_log_debug(self.verbose_level)
end

function VerboseDebugLogger:debug(template, ...)
  self.logger:verbose(self.verbose_level, template, ...)
end

function VerboseDebugLogger:pretty_log_value(value)
  if self:should_log() then
    self.logger:pretty_log_value(Logger.DEBUG, value)
  end
end
