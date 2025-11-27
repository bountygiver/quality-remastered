local item_placeholders = require("__quality-remastered__.data.item_placeholders")
local helpers = require("__quality-remastered__.utilities.helpers")

local ignored_placeholder_keys = {
  name = true,
  type = true,
  callback = true,
}

local limit = 9999

function addQualityItemPlaceholder(srcName, srcItem)
  if srcItem == nil or not srcItem.name then
    error("Invalid base item "..srcName.." when generating placeholders. Obj:" .. helpers.printtable(srcItem, 1))
  end
  if srcItem.name:sub(1, 15) == "qr-placeholder-" or srcItem.parameter then
    log("Skipping " .. srcName .." because it's a placeholder")
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
    localised_name = {"?", { "item-name." .. placeholder_internal_name }, { "item-name.qr-placeholder-generic", srcItem.localised_name or {"?", {"item-name." .. srcName}, {"entity-name." .. srcName}}}},
    localised_description = {"?", { "item-description." .. placeholder_internal_name }, { "item-description.qr-placeholder-generic", srcItem.localised_name or {"?", {"item-name." .. srcName}, {"entity-name." .. srcName}}}},
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
  local placeholderData = item_placeholders[srcName]
  if placeholderData then
    for k, v in pairs(placeholderData) do
      if not ignored_placeholder_keys[k] then
        resultItem[k] = v
      end
    end
  end

  return resultItem
end

local idx = 1
local itemsToAdd = {}

for _, prototypes in ipairs(helpers.item_cats) do
  if prototypes then
    for srcName, origItem in pairs(prototypes) do
      local result = addQualityItemPlaceholder(srcName, origItem)
      if result then
        itemsToAdd[idx] = result
        idx = idx + 1
      end
    end
  end
end

data:extend(itemsToAdd)
