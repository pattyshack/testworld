RandomSelector = Class()

function RandomSelector:_init(odds_list, seed)
  local sum = 0
  for idx, tuple in ipairs(odds_list) do
    sum = sum + tuple[1]
  end

  self.random = PcgRandom(seed)
  self.sum = sum
  self.odds_list = odds_list
end

function RandomSelector:next()
  local rand = self.random:next(1, self.sum)
  local acc = 0
  for idx, tuple in ipairs(self.odds_list) do
    acc = acc + tuple[1]
    if rand <= acc then
      return tuple[2]
    end
  end

  assert(
    false,
    string.format("PROGRAMMING ERROR %s > %s (== %s)", rand, self.sum, acc))
end

RandomContentIdSelector = Class(RandomSelector)

function RandomContentIdSelector:_init(odds_list, seed)
  local odds_content_id_list = {}
  for idx, tuple in ipairs(odds_list) do
    table.insert(
      odds_content_id_list,
      {tuple[1], minetest.get_content_id(tuple[2])})
  end

  RandomSelector._init(self, odds_content_id_list, seed)
end
