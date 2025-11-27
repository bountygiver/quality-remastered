local qr_recipes = data.raw["mod-data"]["qr-recipes"]
local helpers = require("__quality-remastered__.utilities.helpers")

if not qr_recipes then
  error("QR Recipes not initialized. Something wrong has happened, maybe another mod removed this data?")
end

local crafting_translation = {
  ["basic-crafting"] = "advanced-crafting",
  ["crafting"] = "advanced-crafting",
  ["smelting"] = "advanced-crafting",
  ["organic-or-hand-crafting"] = "organic",
}

local main_products_to_patch = {}

---@diagnostic disable-next-line: param-type-mismatch --Language server don't recognize the mod data here, we have to assume the type is valid
for baseRecipeName, recipeData in pairs(qr_recipes.data.recipes) do
  local origRecipe = data.raw.recipe[baseRecipeName]
  if not origRecipe then
    if not recipeData.output_override then
      error("Non-existance recipe " .. baseRecipeName .. " requires an output to be specified")
    end
    if not recipeData.category then
      error("Non-existance recipe " .. baseRecipeName .. " requires a category to be specified")
    end
    origRecipe = {
      name = baseRecipeName,
      type = "recipe",
      allow_productivity = true,
      order = "zzz" .. baseRecipeName,
    }
    --error("Recipe not found " .. baseRecipeName)
  end
  local newRecipeName = helpers.recipe_name(baseRecipeName)
  local origProduct = recipeData.output_override or origRecipe.main_product or origRecipe.results[1].name
  local mainProduct = helpers.placeholder_name(origProduct)
  local newRecipe = {
    type = "recipe",
    name = newRecipeName,
    localised_name = {"?", {"recipe-name." .. newRecipeName}, {"recipe-name.qr-generic", {"?", {"item-name." .. origProduct}, {"entity-name." .. origProduct}}}},
    localised_description = {"?", {"recipe-name." .. newRecipeName}, {"recipe-description.qr-generic", {"?", {"item-name." .. origProduct}, {"entity-name." .. origProduct}}}},
    energy_required = recipeData.energy_required or (origRecipe.energy_required * 2),
    category = recipeData.category or crafting_translation[origRecipe.category] or origRecipe.category,
    subgroup = recipeData.subgroup or "qr-unknown",
    enabled = recipeData.unlock_by_technology ~= nil,
    allow_productivity = origRecipe.allow_productivity,
    allow_decomposition = false,
    unlock_results = false,
    auto_recycle = false,
    main_product = mainProduct, --origProduct,
    ingredients = recipeData.ingredients,
    order = origRecipe.order,
    results = {
      { type = "item", name = mainProduct, amount = recipeData.resultAmount or 1, show_details_in_recipe_tooltip = false,},
      {
        type = "item", name = origProduct, amount = recipeData.resultAmount or 1, probability = 0,
      },
    },
  }
  if recipeData.byproducts then
    for i, v in ipairs(recipeData.byproducts) do
      newRecipe.results[i + 2] = v
    end
  end
  if origRecipe.icon or origRecipe.icons then
    helpers.icon_patch(origRecipe, newRecipe)
  else
    local product = helpers.get_item_by_name(mainProduct)
    newRecipe.icons = product and product.icons
  end
  main_products_to_patch[mainProduct] = true
  data:extend{newRecipe}
end

for productName, _ in pairs(main_products_to_patch) do
  local product = helpers.get_item_by_name(productName)
  if product and product.hidden_in_factoriopedia then
    log("Patching " .. productName .. " to be visible in factoriopedia")
    product.hidden_in_factoriopedia = false
    data:extend{product}
  end
end
