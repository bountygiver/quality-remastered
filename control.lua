local item_placeholders_raw = require("__quality-remastered__.data.item_placeholders")
local helpers = require("__quality-remastered__.utilities.helpers")

local can_print_debug = false
local can_print_error = true

function update_settings()
  can_print_debug = not not settings.global["quality-remastered-show-debug"].value
  can_print_error = not not settings.global["quality-remastered-show-error"].value
end

update_settings()

--- use remote.call("quality-remastered", "add_callback", item-name, remote-name, remote-function) to add special handling for when a placeholder item gets spoiled into its base item
--- params: item-name: name of the base item
--- params: remote-name: The name of the remote interface registered
--- params: remote-function: the name of the remote interface function that takes in just a ItemStackDefinition table and returns the modified result you want
remote.add_interface("quality-remastered",
{
  add_callback = function (name, remote_name, remote_function)
    if (type(name) ~= "string") then
      error("A mod has called add_callback to quality remastered with the wrong parameters.")
    end
    if not (remote.interfaces[remote_name] and remote.interfaces[remote_name][remote_function]) then
      error("A mod attempts to register a callback before adding the remote interface " .. remote_name .. ":" .. remote_function)
    end
    item_placeholders_raw[name] = {
      callback = function (item_stack_identification)
        return remote.call(remote_name, remote_function, item_stack_identification)
      end
    }
  end
})

script.on_event(defines.events.on_runtime_mod_setting_changed, update_settings)

local print_debug = function(message)
  if (can_print_debug) then
    game.print(message)
  end
end

local print_error = function(message)
  if (can_print_error) then
    game.print(message)
  end
end

local get_replacement = function(item_stack, force)
  if (item_stack.valid_for_read == false) then
    return nil
  end
  replacement_name = helpers.item_from_placeholder(item_stack.name)
  if (replacement_name == nil) then
    return nil
  end
  local quality = item_stack.quality
  if (quality.next ~= nil) then
    if not force or force.is_quality_unlocked(quality.next) then
      quality = quality.next
    end
  end
  local item_stack_identification = {name=replacement_name, count=item_stack.count, quality=quality}

  local placeholder_definition = item_placeholders_raw[replacement_name]
  if placeholder_definition ~= nil and placeholder_definition["callback"] ~= nil then
    return placeholder_definition.callback(item_stack_identification)
  end
  return item_stack_identification
end

local belts_and_loaders = {
  ["transport-belt"] = true,
  ["underground-belt"] = true,
  ["splitter"] = true,
  ["loader"] = true,
  ["loader-1x1"] = true,
}

local replace_prod_stats = function(entity, source_stack, replacement_definition, count)
  if (entity.force and entity.force.valid) then
    entity.force
      .get_item_production_statistics(entity.surface)
      .on_flow(
        {
          name = replacement_definition.name,
          quality = replacement_definition.quality and replacement_definition.quality.name or "normal",
        }, 
        count or replacement_definition.count)
    entity.force
      .get_item_production_statistics(entity.surface)
      .on_flow(
        {
          name = source_stack.name,
          quality = source_stack.quality and source_stack.quality.name or "normal",
        }, 
        -(count or source_stack.count))
  end
end

function insert_replacement_to_inventory(entity, target_inventory, source_stack, replacement)
  if (target_inventory) then
    local inserted = target_inventory.insert(replacement)
    if inserted > 0 then
      replace_prod_stats(entity, source_stack, replacement, inserted)
    else
      return 0
    end
    if inserted == source_stack.count then
      source_stack.clear()
    else
      source_stack.count = source_stack.count - inserted
    end
    return inserted
  end
  return 0
end

function replace_placeholder_on_inventory_slot(entity, target_inventory, slot_index, trash_inventory)
  local replacement = get_replacement(target_inventory[slot_index], entity.force)
  if (replacement == nil) then
    return nil
  end

  print_debug("Replacing "..target_inventory[slot_index].name.." with "..replacement.name)

  local inserted = insert_replacement_to_inventory(entity, target_inventory, target_inventory[slot_index], replacement)
  replacement.count = replacement.count - inserted
  if replacement.count <= 0 then
    return inserted
  end

  print_debug("Check if trash inventory is available")
  inserted = insert_replacement_to_inventory(entity, trash_inventory, target_inventory[slot_index], replacement)
  replacement.count = replacement.count - inserted
  if replacement.count <= 0 then
    return inserted
  end

  print_debug("Unable to insert, attempting to swap")
  if (target_inventory[slot_index].can_set_stack(replacement))
  then
    target_inventory[slot_index].set_stack(replacement)
    replace_prod_stats(entity, target_inventory[slot_index], replacement)
    return replacement.count
  end

  print_error("Unable to replace all stack of " .. replacement.name .. " with reamining: " .. replacement.count .. " on " .. tostring(entity))
  return inserted
end

function replace_placeholders_on_inventory(entity, target_inventory, trash_inventory)
  if not target_inventory then
    return nil
  end
  for j = 1, #target_inventory do
    replace_placeholder_on_inventory_slot(entity, target_inventory, j, trash_inventory)
  end -- for items in inventory
end

script.on_event(defines.events.on_script_trigger_effect, function (event)
  if (event.effect_id == "quality-placeholder-spoiled")
  then
    print_debug("A quality placeholder spoiled on tick "..event.tick.." at "..tostring(event.source_entity))

    local entity = event.source_entity
    --print_debug(helpers.printtable(event, 5))

    if entity == nil then
      print_debug("No source entity found, unable to replace item")
      return
    end

    local trash_inventory = entity.type == "assembling-machine" and entity.get_inventory(defines.inventory.crafter_trash)
    for i = 1, entity.get_max_inventory_index() do
---@diagnostic disable-next-line: param-type-mismatch --This is how the docs want us to use this
      replace_placeholders_on_inventory(entity, entity.get_inventory(i), trash_inventory)
    end -- for inventories in entity

    -- TODO: find a more general case that catches undergrounds and splitters rather than hardcoding names
    -- TODO: add and test loaders
    if belts_and_loaders[entity.type] then
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
          local replacement = get_replacement(item.stack, entity.force)
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
      local replacement = get_replacement(itemStack, entity.force)
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
      local replacement = get_replacement(itemStack, entity.force)
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

