modules = data.raw["module"]
for _, entry in pairs(modules) do
  if entry.effect and entry.effect.quality ~= nil and entry.effect.quality > 0 then
    entry["hidden"] = true
    entry["hidden_in_factoriopedia"] = true
    data:extend({entry})

    recipe = data.raw["recipe"][entry.name]
    if recipe ~= nil then
      recipe["hidden"] = true
      recipe["hidden_in_factoriopedia"] = true
      data:extend({recipe})
    end
  end
end
