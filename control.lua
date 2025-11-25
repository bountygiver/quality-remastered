local item_placeholders_raw = require("__quality-remastered__.data.item_placeholders")
local helpers = require("__quality-remastered__.utilities.helpers")

local print_debug = function(message)
  if (false) then
    game.print(message)
  end
end

local print_error = function(message)
  if (true) then
    game.print(message)
  end
end


local get_replacement = function(item_stack)
  if (item_stack.valid_for_read == false) then
    return nil
  end
  replacement_name = helpers.item_from_placeholder(item_stack.name)
  if (replacement_name == nil) then
    return nil
  end
  local quality = item_stack.quality
  if (quality.next ~= nil) then
    quality = quality.next
  end
  
  local item_stack_identification = {name=replacement_name, count=item_stack.count, quality=quality}

  local placeholder_definition = helpers.placeholder_name(replacement_name)
  if placeholder_definition ~= nil and placeholder_definition["callback"] ~= nil then
    return placeholder_definition.callback(item_stack_identification)
  end
  return item_stack_identification
end


local replace_prod_stats = function(entity, source_stack, replacement_definition)
  if (entity.force and entity.force.valid) then
    entity.force
      .get_item_production_statistics(entity.surface)
      .on_flow(replacement_definition.name, replacement_definition.count)
    entity.force
      .get_item_production_statistics(entity.surface)
      .on_flow(source_stack.name, -source_stack.count)
  end
end

script.on_event(defines.events.on_script_trigger_effect, function (event)
  if (event.effect_id == "quality-placeholder-spoiled")
  then
    print_debug("A quality placeholder spoiled on tick "..event.tick.." at "..tostring(event.source_entity))

    local entity = event.source_entity

    for i = 1, entity.get_max_inventory_index() do
      target_inventory = entity.get_inventory(i)
      if (target_inventory ~= nil)
      then
        for j = 1, #target_inventory do
          local replacement = get_replacement(target_inventory[j])
          if (replacement ~= nil)
          then
            print_debug("Replacing "..target_inventory[j].name.." with "..replacement.name)
            if (target_inventory.can_insert(replacement) == false)
            then
              print_debug("Unable to insert, attempting to swap")
              if (target_inventory[j].can_set_stack(replacement) == false)
              then
                print_error("Unable to replace stack at "..tostring(entity))
              else
                replace_prod_stats(entity, target_inventory[j], replacement)
                target_inventory[j].set_stack(replacement)
              end
            else
              target_inventory.insert(replacement)
              replace_prod_stats(entity, target_inventory[j], replacement)
              target_inventory[j].clear()
            end -- if inventory accepts replacement
          end -- if item is replaceable
        end -- for items in inventory
      end -- if inventory ~= nil
    end -- for inventories in entity

    -- TODO: find a more general case that catches undergrounds and splitters rather than hardcoding names
    -- TODO: add and test loaders
    if (entity.type == "transport-belt") or (entity.type == "underground-belt") or (entity.type == "splitter") or (entity.type == "loader") then
      -- I hate hardcoding the line count, but get_transport_line throws a hard error on higher indices
      -- TODO: find a more general case for how many transport lines an entity has
      local line_count = 2
      if (entity.type == "splitter") then
        line_count = 8
      end

      local lines = {}
      for i = 1, line_count do
        lines[i] = entity.get_transport_line(i)
      end

      for _, line in pairs(lines) do
        local contents = line.get_detailed_contents()
        for _, item in pairs(contents) do
          local replacement = get_replacement(item.stack)
          if (replacement ~= nil)
          then
            print_debug("Replacing "..item.stack.name.." with "..replacement.name)
            if (item.stack.can_set_stack(replacement) == false)
            then
              print_error("Unable to replace stack at "..tostring(entity))
            else
              replace_prod_stats(entity, item.stack, replacement)
              item.stack.set_stack(replacement)
            end -- if stack accepts replacement
          end -- if item is replaceable

        end -- for items in line
      end -- for lines in entity
    end -- if entity is transport belt

    if (entity.type == "inserter") then
      local itemStack = entity.held_stack
      local replacement = get_replacement(itemStack)
      if (replacement ~= nil)
      then
        print_debug("Replacing "..itemStack.name.." with "..replacement.name)
        if (itemStack.can_set_stack(replacement) == false)
        then
          print_error("Unable to replace stack at "..tostring(entity))
        else
          replace_prod_stats(entity, itemStack, replacement)
          itemStack.set_stack(replacement)
        end -- if stack accepts replacement
      end -- if item is replaceable
    end -- if entity is inserter

    if (entity.type == "item-entity") then
      local itemStack = entity.stack
      local replacement = get_replacement(itemStack)
      if (replacement ~= nil)
      then
        print_debug("Replacing "..itemStack.name.." with "..replacement.name)
        if (itemStack.can_set_stack(replacement) == false)
        then
          print_error("Unable to replace stack at "..tostring(entity))
        else
          replace_prod_stats(entity, itemStack, replacement)
          itemStack.set_stack(replacement)
        end -- if stack accepts replacement
      end -- if item is replaceable
    end -- if entity is a raw item (such as dropped on ground)

    if (true == false) then
      -- When items spoil, we often recieve multiple events. Some of these events don't find an item to replace.
      -- As a result, "we didn't find an item" does not automatically mean something went wrong.
      -- TODO: find a way to unambiguously determine that something went wrong
      print_error("Error: A quality item replacement failed at "..tostring(entity))
    end -- if no items were found

  end -- if effect id matches
end)

