Selectable = Class()

function Selectable:_init(weighted_item_list)
  local total = 0
  for idx, tuple in ipairs(weighted_item_list) do
    total = total + tuple[1]
  end

  self.total_weight = total
  self.weighted_item_list = weighted_item_list
end

RandomGenerator = Class()

function RandomGenerator:_init(seed)
  self.random = PcgRandom(seed)
end

function RandomGenerator:seed(map_seed, seed_offset, x, y, z)
  self.random = PcgRandom(
    map_seed +
    (seed_offset or 0) +
    (x or 0) * 1000 +
    (y or 0) * 100 +
    (z or 0) * 10)
end

function RandomGenerator:select(selectable)
  local rand = self.random:next(1, selectable.total_weight)
  local acc = 0
  for idx, tuple in ipairs(selectable.weighted_item_list) do
    acc = acc + tuple[1]
    if rand <= acc then
      return tuple[2]
    end
  end

  assert(
    false,
    string.format(
      "PROGRAMMING ERROR %s > %s (== %s)",
      rand,
      selectable.total_weight,
      acc))
end
