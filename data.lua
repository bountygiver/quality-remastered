local qr_recipes = data.raw["mod-data"] and data.raw["mod-data"]["qr-recipes"] or {
  type = "mod-data",
  name = "qr-recipes",
  data = {
    recipes = {},
  },
  hidden_in_factoriopedia = true,
  hidden = true,
}

-- If another mod overrides this, use their settings
if not qr_recipes.data.recipes["iron-plate"] then
  qr_recipes.data.recipes["iron-plate"] = 
  {
    energy_required = 3,
    subgroup = "qr-nauvis",
    unlock_by_technology = "quality-module",
    ingredients = 
    {
      {type = "item", name = "iron-plate", amount = 5},
      {type = "item", name = "solid-fuel", amount = 1},
      {type = "fluid", name = "steam", amount = 20},
    },
    resultAmount = 3,
  }
end
if not qr_recipes.data.recipes["copper-plate"] then
  qr_recipes.data.recipes["copper-plate"] = 
  {
    energy_required = 2.5,
    subgroup = "qr-nauvis",
    unlock_by_technology = "quality-module",
    ingredients = 
    {
      {type = "item", name = "copper-plate", amount = 4},
      {type = "item", name = "solid-fuel", amount = 2},
      {type = "fluid", name = "sulfuric-acid", amount = 15},
    },
    resultAmount = 2,
  }
end
if not qr_recipes.data.recipes["plastic-bar"] then
  qr_recipes.data.recipes["plastic-bar"] = 
  {
    energy_required = 4,
    subgroup = "qr-nauvis",
    unlock_by_technology = "quality-module",
    ingredients = 
    {
      {type = "item", name = "coal", amount = 5},
      {type = "item", name = "copper-ore", amount = 1},
      {type = "fluid", name = "petroleum-gas", amount = 35},
    },
    resultAmount = 4,
  }
end
if not qr_recipes.data.recipes["solid-fuel-from-light-oil"] then
  qr_recipes.data.recipes["solid-fuel-from-light-oil"] = 
  {
    energy_required = 1.5,
    subgroup = "qr-nauvis",
    unlock_by_technology = "quality-module",
    ingredients = 
    {
      {type = "item", name = "copper-ore", amount = 3},
      {type = "fluid", name = "light-oil", amount = 25},
    },
    resultAmount = 1,
  }
end

data:extend{qr_recipes}