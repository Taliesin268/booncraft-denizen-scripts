# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Minecraft server test environment with Denizen Script (.dsc) files for a refund system plugin. The project runs in Docker using the Paper server with the Denizen plugin. Only .dsc files are tracked in git - all other server files are ignored.

## Project Structure

```
plugins/Denizen/scripts/refunds/
├── commands/
│   └── refund_commands.dsc    # Commands and core business logic
├── menus/
│   ├── refund_main_menu.dsc           # Main refund interface
│   ├── quantity_determination_menu.dsc # Item quantity selection UI
│   ├── paginated_menu.dsc             # Pagination system
│   └── general_menu_components.dsc    # Reusable UI components
```

## Development Commands

### Server Management
- Start server: `docker-compose up -d`
- Stop server: `docker-compose down`
- View logs: `docker logs -f mc-test`
- Access console: `docker exec -i mc-test mc-send-to-console`

### Script Development
- Scripts hot-reload automatically when saved to `plugins/Denizen/scripts/`
- Use `/ex reload` in game console to manually reload scripts
- View script errors: `/ex debug`

## Denizen Script Language (.dsc)

### Key Concepts
- **Script containers**: Top-level objects that define script types (command, task, inventory, world, item, procedure)
- **Commands**: Lines starting with `-` that perform actions
- **Tags**: Dynamic values in `<>` brackets (e.g., `<player.name>`, `<server.flag[refunds]>`)
- **Definitions**: Variables passed to tasks using `def.variable_name`
- **Flags**: Persistent data storage system (`flag server/player key:value`)

### Important Syntax Rules
- Use precise indentation (spaces, not tabs)
- Commands start with `-` and can be nested
- Object references use specific notation (e.g., `<player.uuid>`, `<context.item>`)
- Lists use `<list>` and can be modified with `:->:` (add) or `:-:` (remove)
- Map objects use `<map>` with `.get[key]` and `.set[key:value]`

### Common Patterns in This Codebase

#### Data Structure
- Refund data stored as server flags: `server.flag[refunds.<uuid>.sold.<material>]`
- Each sold item stores: `{unit_price: X, quantity: Y}`
- Balance tracked per player: `server.flag[refunds.<uuid>.balance]`

#### Menu System
- Uses inventory containers with `gui: true`
- Items have action flags: `flag=action:back|reclaim|increment`
- Event handlers match on `player clicks item in menu_name`
- Common components (buttons, empty slots) defined in `general_menu_components.dsc`

#### Error Handling
- Use `if_null[default_value]` for safe flag access
- Check existence with `.exists` before operations
- Use `clickable` command for interactive error messages

#### Advanced List Operations
- `parse[tag]` transforms each list element (like map() in other languages)
- `sum` aggregates numerical lists - useful with parse for calculating totals
- Example: `<[items].parse[quantity].sum>` gets total quantity across all items
- `exclude[key]` on maps removes entries - useful for cleanup
- **Element wrapping**: Standalone strings must be wrapped in `<Element[text]>` tags since everything in Denizen must be a tag object

#### Item Handling
- Use `<item[material_name]>` for clean base items vs decorated UI items
- `give` command with `ignore_leftovers save:name` tracks undelivered items
- `<entry[name].leftover_items>` returns list of items that didn't fit in inventory
- Always use `.material.name` as keys for consistent material identification
- **Item matchers**: Use material name strings, not item objects (e.g., `item:<[material]>` not `item:<item[<[material]>]>`)
- `take` command works on inventories: `take item:<[material]> quantity:<#> from:<[inventory]>`

#### Inventory Operations
- Item extraction: use `exclude_item[ui_elements].list_contents` to get only player-placed items
- Aggregate stacks by material using maps in foreach loops
- Balance overflow pattern: split refunds between balance capacity and direct money payments

### Testing Changes
- Reload scripts: `/ex reload`
- Check for errors: `/ex debug`
- Test commands: `/import_refund_data` then interact with refund menus
- Verify inventory GUIs work correctly in-game

## Architecture Notes

### Refund System Flow
1. `import_refund_data` command loads player transaction history from YAML
2. Players access refund menu via GUI system
3. `reclaim_item` task handles item recovery with balance validation
4. Quantity determination uses dynamic UI with increment/decrement controls
5. Support for both individual item and stack-based quantity selection

### Menu Component System
- `general_menu_components.dsc` provides reusable UI elements
- Dynamic lore generation through procedures (`add_refund_lore`, `add_quantity_item_lore`)
- Pagination system for large item lists
- Consistent navigation with back buttons and balance display

### Data Management
- Server flags store all persistent refund data
- UUID-based player identification for offline player support
- Map structures for complex item data storage
- Procedures for data calculations (`get_total_sell_cost`, `balance_refunds`)
- Looks like to get the return of a task, you need to use <entry[save_name].created_queue.determination>