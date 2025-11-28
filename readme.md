# Quality Remastered

Quality Remastered is a mod for Factorio 2.0 (Original Quality mod required). It is available on the [Factorio Mod Portal](https://mods.factorio.com/mod/quality-remastered).

# External API

This mod will automatically generate a placeholder of all items in the `data-updates` stage. The placeholder will become the item it is generated based on with quality level increased by 1. These placeholder will use the same name as the item it is based on prefixed with `qr-placeholder-`

Mods may generate additional recipe by either making the recipes manually after this mod is loaded (by adding this mod as a dependency) in or after the `data-updates` stage (in which you will need want to include both the placeholder item and the based item with amount of 0 as its result so the base item with quality may be placed in said slot). Optionally, mods may let this mod automatically generate the recipes with the required modifications by adding recipe entries to `data.raw["mod-data"]["qr-recipes"].data.recipes` before the `data-updates` stage of this mod using the following data structure:
```lua
[recipe_name: string] = { -- The generated recipe will have this name prefixed with "qr-upquality-". If recipe_name is a name of an existing recipe, it will inherit most properties of that recipe.
  ingredients: array[IngredientPrototype]
  energy_required: double? -- This field is optional if there is an existing recipe of recipe_name, it will use twice the amount of that recipe's energy_required
  resultAmount: uint16? -- Amount of products, defaults to 1
  category: RecipeCategoryID? -- Inherits the existing recipe and attempts to disable handcrafting. Defaults to "advanced-crafting"
  subgroup: ItemSubGroupID? -- Defaults to "qr-unknown"
  unlock_by_technology: TechnologyID? -- Technology that unlocks this recipe, if not provided recipe will be enabled since the game start
  output_override: ItemID? -- Required if there's no existing recipe of recipe_name
  byproducts: array[ProductPrototype]? -- Additional items this recipe produces. Note that you must handle the placeholder items manually here
}
```

If you want your placeholder item to have any custom behaviour (such as resetting to a specfic quality rather than incrementing its quality level), you may register a callback by using remote procedures.

1. Register a remote interface with all the callback functions you want which takes in an `ItemStackDefinition` as its parameter, and returns it after desired modification is made
2. Within your `script.on_init()` and `script.on_load`, call the remote interface to register the callback using `remote.call("quality-remastered", "add_callback", item_name, registered_interface_name, registered_interface_function)` 
