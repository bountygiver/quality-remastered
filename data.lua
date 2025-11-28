local helpers = require("__quality-remastered__.utilities.helpers")

local qr_recipes = data.raw["mod-data"] and type(data.raw["mod-data"]["qr-recipes"]) == "table" and data.raw["mod-data"]["qr-recipes"] or {
  type = "mod-data",
  name = "qr-recipes",
  hidden_in_factoriopedia = true,
  hidden = true,
}

if not qr_recipes.data or type(qr_recipes.data) ~= "table" then
  qr_recipes.data = {}
end

if not qr_recipes.data.recipes or type(qr_recipes.data.recipes) ~= "table" then
  qr_recipes.data.recipes = {}
end

function add_recipe(origRecipe, ingredients, energy, resultAmt, unlock_by, overrideMainResult)
  if not qr_recipes.data.recipes[origRecipe] then
    qr_recipes.data.recipes[origRecipe] = 
    {
      ingredients = ingredients,
      energy_required = energy,
      resultAmount = resultAmt or 1,
      subgroup = "qr-nauvis",
      unlock_by_technology = unlock_by,
      output_override = overrideMainResult,
    }
    local orig_recipe = data.raw.recipe[origRecipe]

    if not ingredients or #ingredients == 0 then
      if not (orig_recipe and orig_recipe.ingredients) then
        return error("Attempting to patch non-existent recipe " .. origRecipe .. " without providing ingredients.")
      end
      local new_ingredients = table.deepcopy(orig_recipe.ingredients) or {}
      for _, v in ipairs(new_ingredients) do
        v.amount = (v.amount or 1) * 4
      end
      qr_recipes.data.recipes[origRecipe].ingredients = new_ingredients
    end

    if not energy then
      qr_recipes.data.recipes[origRecipe].energy_required = (orig_recipe and orig_recipe.energy_required or 1) * 4
    end

    if not orig_recipe then
      qr_recipes.data.recipes[origRecipe].category = "advanced-crafting"
    end
    return qr_recipes.data.recipes[origRecipe]
  end
  return {}
end

-- If another mod overrides this, use their settings
add_recipe(
  "iron-plate",
  {
    {type = "item", name = "iron-plate", amount = 5},
    {type = "item", name = "solid-fuel", amount = 1},
    {type = "fluid", name = "steam", amount = 20},
  },
  3,
  3,
  "quality-module"
)
add_recipe(
  "copper-plate",
  {
    {type = "item", name = "copper-plate", amount = 4},
    {type = "item", name = "solid-fuel", amount = 2},
    {type = "fluid", name = "sulfuric-acid", amount = 15},
  },
  2.5,
  2,
  "quality-module"
)
add_recipe(
  "plastic-bar",
  {
    {type = "item", name = "coal", amount = 5},
    {type = "item", name = "copper-ore", amount = 1},
    {type = "fluid", name = "petroleum-gas", amount = 35},
  },
  4,
  4,
  "quality-module"
)
add_recipe(
  "solid-fuel-from-light-oil",
  {
    {type = "item", name = "copper-ore", amount = 3},
    {type = "fluid", name = "light-oil", amount = 25},
  },
  1.5,
  1,
  "quality-module"
)

-- Nauvis recipes to enable higher quality pathways without space age
if not mods["quality-remastered-sa"] then
  -- Upcycle Wood
  add_recipe(
    "wooden-chest",
    {
      {type = "item", name = "wooden-chest", amount = 2},
      {type = "item", name = "steel-plate", amount = 4},
    },
    3,
    1,
    "quality-module"
  )
  -- Upcycle Uranium
  add_recipe(
    "uranium-ore",
    {
      {type = "item", name = "stone", amount = 199},
      {type = "item", name = "uranium-ore", amount = 99},
      {type = "item", name = "uranium-235", amount = 1},
    },
    60,
    50,
    "quality-module",
    "uranium-ore"
  )
  -- Upcycle stone
  add_recipe(
    "stone",
    {
      {type = "item", name = "stone", amount = 50},
      {type = "item", name = "iron-ore", amount = 5},
      {type = "fluid", name = "lubricant", amount = 100},
    },
    30,
    30,
    "quality-module",
    "stone"
  )
  -- Epic LDS
  local r = add_recipe(
    "low-density-structure",
    {
      {type = "item", name = "low-density-structure", amount = 6},
      {type = "item", name = "uranium-238", amount = 1},
    },
    5,
    3,
    "epic-quality"
  )
  r.subgroup = "qr-nauvis-epic"
end

data:extend{qr_recipes}