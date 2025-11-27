require("prototypes.item-group")
require("prototypes.item")
require("prototypes.recipe")
require("prototypes.quality")
require("prototypes.technology")
require("prototypes.module")

-- required to load SA for whatever reason
if not data.raw.tile["empty-space"] then
  local empty_space = table.deepcopy(data.raw.tile["out-of-map"])
  empty_space.name = "empty-space"
  data:extend{empty_space}
end