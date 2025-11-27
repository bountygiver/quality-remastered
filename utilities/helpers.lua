local string_func = {
  ["string"] = function(t) return "\"" .. t .. "\"" end,
  ["number"] = tostring,
  ["function"] = function() return "(function)" end,
  ["boolean"] = function(t) return t and "TRUE" or "FALSE" end,
  ["nil"] = function() return "(NIL)" end,
  ["userdata"] = function(t)
    local s = "(userdata): "
    if (t.name) then
      s = s .. " name: " .. t.name
    end
    if (t.type) then
      s = s .. " type: " .. t.type
    end
    return s
  end
}

function type_string(t)
  return "(" .. type(t) .. ")"
end

function printtable(t, depth)
  if (type(t) == "table") then
    if depth <= 0 then
      return type_string(t)
    end
    local s = "{ "
    for k, v in pairs(t) do
      s = s .. printtable(k, depth - 1) .. " = " .. printtable(v, depth - 1) .. ","
    end
    return s .. " }"
  end

  local str_func = string_func[type(t)] or type_string

  return str_func(t)
end

function recipe_name(inName)
  return "qr-upquality-" .. inName
end

function placeholder_name(inName)
  return "qr-placeholder-" .. inName
end

function item_from_placeholder(placeholderName)
  if placeholderName:sub(1, 15) == "qr-placeholder-" then
    return placeholderName:sub(16)
  end
  return nil
end

function icon_patch(origItem, newItem)
  if (newItem.icon_size or 64) >= 64 then
    if origItem.icon then
      newItem.icons = {
        {icon = origItem.icon,},
        {icon = "__quality-remastered__/graphics/icons/quality-plus-overlay.png",}
      }
    elseif origItem.icons then
      log("icons found " .. printtable(origItem.icons, 5))
      newItem.icons = table.deepcopy(origItem.icons)
      newItem.icons[#newItem.icons + 1] = {icon = "__quality-remastered__/graphics/icons/quality-plus-overlay.png",}
    else
      newItem.icon = "__quality-remastered__/graphics/icons/quality-plus.png"
    end
  else
    newItem.icon = origItem.icon
    newItem.icons = origItem.icons
  end
end

local item_cats = {}

if data then
  item_cats = {
    data.raw.item,
    data.raw.capsule,
    data.raw.ammo,
    data.raw.gun,
    data.raw.module,
    data.raw.tool,
    data.raw.armor,
    data.raw["repair-tool"],
    data.raw["space-platform-starter-pack"],
  }
elseif defines and defines.prototypes and defines.prototypes.item then
  item_cats = {
    defines.prototypes.item.item,
    defines.prototypes.item.capsule,
    defines.prototypes.item.ammo,
    defines.prototypes.item.gun,
    defines.prototypes.item.module,
    defines.prototypes.item.tool,
    defines.prototypes.item.armor,
    defines.prototypes.item["repair-tool"],
    defines.prototypes.item["space-platform-starter-pack"],
  }
end

function get_item_by_name(itemName)
  for _, v in ipairs(item_cats) do
    if v[itemName] then
      return v[itemName]
    end
  end

  return nil
end

return {
  recipe_name = recipe_name,
  placeholder_name = placeholder_name,
  item_from_placeholder = item_from_placeholder,
  printtable = printtable,
  icon_patch = icon_patch,
  get_item_by_name = get_item_by_name,
  item_cats = item_cats,
}