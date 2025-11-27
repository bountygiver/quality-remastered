local helpers = require("__quality-remastered__.utilities.helpers")

local qr_recipes = data.raw["mod-data"]["qr-recipes"]

if not qr_recipes then
  error("QR Recipes not initialized. Something wrong has happened, maybe another mod removed this data?")
end

local k_tech = {}

---@diagnostic disable-next-line: param-type-mismatch --Language server don't recognize the mod data here, we have to assume the type is valid
for origRecipeName, recipeData in pairs(qr_recipes.data.recipes) do
  if recipeData.unlock_by_technology then
    if not k_tech[recipeData.unlock_by_technology] then
      k_tech[recipeData.unlock_by_technology] = {}
    end
    k_tech[recipeData.unlock_by_technology][#k_tech[recipeData.unlock_by_technology] + 1] = origRecipeName
  end
end

quality_technology = data.raw["technology"]["quality-module"]
quality_technology.prerequisites = { "automation-2" }
quality_technology.effects = {
  {
    type = "unlock-quality",
    quality = "uncommon"
  },
  {
    type = "unlock-quality",
    quality = "rare"
  },
}
data:extend({quality_technology})

module_2_technology = data.raw["technology"]["quality-module-2"]
module_2_technology["enabled"] = false
module_2_technology["effects"] = {}
data:extend({module_2_technology})

module_3_technology = data.raw["technology"]["quality-module-3"]
module_3_technology["enabled"] = false
module_3_technology["effects"] = {}
data:extend({module_3_technology})

function addRecipe(technology, recipe_name)
  table.insert(technology.effects, {
    type = "unlock-recipe",
    recipe = recipe_name
  })
end

for tech, unlocks in pairs(k_tech) do
  local affected_tech = data.raw["technology"][tech]
  for _, unlock in ipairs(unlocks) do
    addRecipe(affected_tech, helpers.recipe_name(unlock))
  end
  data:extend({affected_tech})
end