logging = {
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

    -- base = -1,
    -- stone = -1,
  }
}

function logging.debug_log_level(module_name)
    local level = logging.debug_log_level_map[module_name]
    if level ~= nil then
        return level
    end

    return logging.debug_log_level_map["default"]
end

function logging.should_log_debug(module_name, verbose_level)
  return logging.debug_log_level(module_name) >= verbose_level
end

function logging.verbose(module_name, verbose_level, template, ...)
  if logging.should_log_debug(module_name, verbose_level) then
    minetest.log(
        "none",
        "DEBUG[" .. module_name .. "]: " ..
            string.format(template, unpack({...})))
  end
end

function logging.debug(module_name, template, ...)
  logging.verbose(module_name, 0, template, ...)
end

function logging.info(module_name, template, ...)
  minetest.log(
      "none", -- "info" doesn't work ...
      "INFO[".. module_name .."]: " .. string.format(template, unpack({...})))
end

function logging.warn(module_name, template, ...)
  minetest.log(
      "warning",
      "[".. module_name .."]: " .. string.format(template, unpack({...})))
end

function logging.err(module_name, template, ...)
  minetest.log(
    "error",
    "[".. module_name .."]: " .. string.format(template, unpack({...})))
end

function logging.log(log_level, module_name, template, ...)
  if log_level == logging.DEBUG then
    logging.debug(module_name, template, unpack({...}))
  elseif log_level == logging.INFO then
    logging.info(module_name, template, unpack({...}))
  elseif log_level == logging.WARN then
    logging.warn(module_name, template, unpack({...}))
  elseif log_level == logging.ERR then
    logging.err(module_name, template, unpack({...}))
  else
    minetest.log(
        "none", -- "info" doesn't work ...
        "UNKNOWN(".. log_level .. ")[".. module_name .."]: " ..
            string.format(template, unpack({...})))
  end
end

local function pretty_log_value(log_level, module_name, value, indent, prefix)
  if type(value) == "table" then
    logging.log(log_level, module_name, "%s%s{", indent, prefix)
    for k, v in pairs(value) do
      pretty_log_value(
          log_level,
          module_name,
          v,
          indent .. "    ",
          k .. " = ")
    end
    logging.log(log_level, module_name, indent .. "},")
  else
    logging.log(log_level, module_name, "%s%s%s,", indent, prefix, value)
  end
end

function logging.pretty_log_value(log_level, module_name, value)
  pretty_log_value(log_level, module_name, value, "    ", "")
end

VerboseDebugLogger = {}

function VerboseDebugLogger:new(module_name, verbose_level)
  local logger = {
    module_name = module_name,
    verbose_level = verbose_level,
  }

  setmetatable(logger, self)
  self.__index = self

  return logger
end

function VerboseDebugLogger:should_log()
  return logging.should_log_debug(self.module_name, self.verbose_level)
end

function VerboseDebugLogger:debug(template, ...)
  logging.verbose(self.module_name, self.verbose_level, template, unpack({...}))
end

function VerboseDebugLogger:pretty_log_value(value)
  if self:should_log() then
    logging.pretty_log_value(logging.DEBUG, self.module_name, value)
  end
end

Logger = {}

function Logger:new(module_name)
  local logger = {
    module_name = module_name or minetest.get_current_modname(),
  }

  setmetatable(logger, self)
  self.__index = self

  return logger
end

function Logger:debug(template, ...)
  logging.debug(self.module_name, template, unpack({...}))
end

function Logger:info(template, ...)
  logging.info(self.module_name, template, unpack({...}))
end

function Logger:warn(template, ...)
  logging.warn(self.module_name, template, unpack({...}))
end

function Logger:err(template, ...)
  logging.err(self.module_name, template, unpack({...}))
end

function Logger:log(log_level, template, ...)
  logging.log(log_level, self.module_name, template, unpack({...}))
end

function Logger:pretty_log_value(log_level, value)
  logging.pretty_log_value(log_level, self.module_name, value)
end

function Logger:v(verbose_level)
  return VerboseDebugLogger:new(self.module_name, verbose_level)
end
