local function get_qualities_above(quality) 
  if quality.next == nil then
    return 0
  end
  return 1 + get_qualities_above(quality.next)
end

local item_placeholders = {
  ["copper-bacteria"] = {
    icon = "__base__/graphics/icons/quality-normal.png",
    callback = function(item_stack_identification)
      item_stack_identification["quality"] = prototypes.quality["normal"]
      return item_stack_identification
    end
  },
  ["iron-bacteria"] = {
    icon = "__base__/graphics/icons/quality-normal.png",
    callback = function(item_stack_identification)
      item_stack_identification["quality"] = prototypes.quality["normal"]
      return item_stack_identification
    end
  },
  ["qr-plastic-bacteria"] = {
    callback = function(item_stack_identification)
      local qualities_above = get_qualities_above(item_stack_identification.quality)
      local spoil_percent = 0
      --                                                       Common; 10s
      if qualities_above == 3 then spoil_percent = 0.33 end -- Uncommon; 12s * 0.67 = 8s
      if qualities_above == 2 then spoil_percent = 0.60 end -- Rare; 16s * 0.4 = 6.4s
      if qualities_above == 1 then spoil_percent = 0.75 end -- Epic; 18s * 0.25 = 4.5s
      if qualities_above == 0 then spoil_percent = 0.99 end -- Legendary; 25s * 0 = 0s
      item_stack_identification["spoil_percent"] = spoil_percent
      return item_stack_identification
    end
  }
}

return item_placeholders