local item_placeholders = require("__quality-remastered__.data.item_placeholders")
local helpers = require("__quality-remastered__.utilities.helpers")

local keyed_placeholders = {}
local ignored_placeholder_keys = {
  name = true,
  type = true,
  callback = true,
}

for _, v in ipairs(item_placeholders) do
  keyed_placeholders[v[1]] = v[2]
end

local limit = 9999

function addQualityItemPlaceholder(srcName, srcItem)
  if srcItem == nil or not srcItem.name then
    error("Invalid base item "..srcName.." when generating placeholders. Obj:" .. helpers.printtable(srcItem, 1))
  end
  if srcItem.name:sub(1, 15) == "qr-placeholder-" or srcItem.parameter then
    log("Skipping " .. srcName .." because it's a placeholder" .. srcItem.name)
    return
  end
  limit = limit - 1
  if limit <= 0 then
    error("Prototype limit reached. Exiting...")
  end
  log("Patching prototype " .. srcName ..": " .. srcItem.type .. ":" .. srcItem.name)
  local placeholder_internal_name = helpers.placeholder_name(srcName)
  resultItem = {
    type = "item",
    factoriopedia_alternative = srcName,
    hidden = true,
    hidden_in_factoriopedia = true,
    subgroup = "qr-placeholders",
    stack_size = srcItem.stack_size,
    spoil_ticks = 1,
    name = placeholder_internal_name,
    spoil_result = placeholder_internal_name,
    icon_size = srcItem.icon_size,
    localised_name = { "item-name.qr-placeholder-generic", srcItem.localised_name or {"?", {"item-name." .. srcName}, {"entity-name." .. srcName}}},
    localised_description = { "item-description.qr-placeholder-generic", srcItem.localised_name or {"?", {"item-name." .. srcName}, {"entity-name." .. srcName}}},
    spoil_to_trigger_result =
    {
      items_per_trigger = 1,
      trigger =
      {
        type = "direct",
        action_delivery =
        {
          type = "instant",
          source_effects =
          {
            {
              type = "script",
              effect_id = "quality-placeholder-spoiled",
            }
          }
        }
      }
    }
  }
  helpers.icon_patch(srcItem, resultItem)
  local placeholderData = keyed_placeholders[itemName]
  if placeholderData then
    for k, v in pairs(placeholderData) do
      if not ignored_placeholder_keys[k] then
        resultItem[k] = v
      end
    end
  end

  return resultItem
end

if settings.startup["quality-remastered-plastic-bateria"].value then
  data:extend{
  {
    type = "item",
    name = "qr-plastic-bacteria",
    hidden_from_player_crafting = true,
    icon = "__quality-remastered__/graphics/icons/plastic-bacteria.png",
    pictures =
    {
      {size = 64, filename = "__quality-remastered__/graphics/icons/plastic-bacteria.png", scale = 0.5},
      {size = 64, filename = "__quality-remastered__/graphics/icons/plastic-bacteria-2.png", scale = 0.5},
      {size = 64, filename = "__quality-remastered__/graphics/icons/plastic-bacteria-3.png", scale = 0.5},
    },
    subgroup = "qr-gleba",
    stack_size = 50,
    spoil_ticks = 600,
    spoil_result = "plastic-bar",
  }}
end

local idx = 1
local itemsToAdd = {}

for _, prototypes in pairs{data.raw.item, data.raw.capsule} do
  for srcName, origItem in pairs(prototypes) do
    local result = addQualityItemPlaceholder(srcName, origItem)
    if result then
      itemsToAdd[idx] = result
      idx = idx + 1
    end
  end
end

data:extend(itemsToAdd)
