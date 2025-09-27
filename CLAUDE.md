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
- **Player existence check**: Use `!<[player].has_played_before.if_null[false]>` to check if player exists (not `== null`)

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

#### Book Creation and Text Formatting
- Use `type: book` containers with `title`, `author`, `signed`, and `text` fields
- Each page is a list item under `text:`
- Color codes: `<&0>` (black) through `<&f>` (white), `<&l>` (bold), `<&o>` (italic)
- Line breaks: `<n>` for new line, `<p>` for paragraph break
- Clickable elements in books: `<element[text].on_click[command]>`
- Dynamic values in books: Tags like `<player.name>` work in book text
- Books can have custom lore when given as items
- **Dynamic pages**: Book pages can be generated using procedures with `<player.uuid.proc[procedure_name]>`
- **Conditional pages**: Procedures can return empty elements to skip pages entirely

#### World Events
- Use `type: world` for server-wide event handlers
- Common pattern: `on player joins:` with `- wait 2s` for load safety
- Track one-time actions with server flags (e.g., `server.flag[refunds.book_given.<player.uuid>]`)
- World events handle player interactions, entity events, and server events

#### Clickable Commands
- `clickable save:name for:<player> until:duration` creates temporary clickable actions
- Access saved clickables with `<entry[name].command>`
- Inline clickables: `<element[text].on_click[command]>` for immediate use
- Clickables expire after the specified duration (e.g., `until:5m`)

#### Advanced Item Operations
- Add custom lore to items: `.with[lore=Line 1|Line 2|Line 3]`
- Use color codes and formatting in lore text
- Dynamic lore with tags: include player data, timestamps, etc.
- Combine multiple item modifications in one expression
- **Conditional lore lines**: Use `<list[items].if[condition].if_null[fallback_list]>` for dynamic lore
- **Threshold messaging**: Calculate remaining amounts with `.sub[]` for "X more needed" displays
- **State-based messages**: Use `.is_less_than[]` to show different messages based on thresholds

#### Number Formatting
- Use `format_number[#,##0.00]` for decimal formatting (e.g., 1234.5 → 1,234.50)
- Common patterns: `#,##0.00` (2 decimals), `#,##0` (no decimals)
- Refer to Java DecimalFormat for advanced patterns

#### Logging Best Practices
- Use trace IDs for tracking related operations: `<util.random_uuid>`
- Log to dated files: `file:plugins/Denizen/logs/refunds/refunds_<util.time_now.format[yyyy-MM-dd]>.log`
- Log levels: info (default), warning (`type:warning`)
- Include context: Player names, UUIDs, operation results, timestamps
- Batch operations should have unique batch IDs for tracking
- Use `~log` prefix to make logging async and prevent blocking

#### Batch Processing Pattern
- Use existing procedures like `get_refund_players` to get data sets
- Track processed/skipped counts for reporting
- Provide progress updates for long operations (every N items)
- Use one-time flags to prevent duplicate processing
- Example: `server.flag[refunds.balance_processed.<uuid>]`

#### World Event Control
- Use `enabled: <server.has_flag[flag_name]>` in world event definitions for toggleable features
- Alternative: Check flag in event handler with `if !<server.has_flag[flag]>: stop`
- Example: Control book distribution on player join with server flags

#### External Command Integration
- Use `execute as_server "command"` for external commands (LuckPerms, vanilla MC, etc.)
- Use `run` for Denizen-defined tasks and commands
- Common pattern: Integrate with permission plugins via execute

#### Advanced Foreach Patterns
- Use `foreach <map> key:var1 as:var2` to iterate maps with key/value pairs
- Example: `foreach <[refund_players]> key:uuid as:player_name`
- The key variable contains the map key, as variable contains the value

#### Chat-Based Input Pattern
- Use `on player chats flagged:flag_name` for efficient chat monitoring (more performant than checking with if statements inside the event)
- **CRITICAL**: Always place `determine cancelled` as the LAST statement in chat handlers to prevent premature script termination
- Pattern for collecting user input via chat:
  ```denizen
  # Task to initiate input collection
  - flag player awaiting_input expire:30s
  - flag player input_data:<any_needed_data>
  - narrate "Type your response in chat..."
  - wait 30s
  - if <player.has_flag[awaiting_input]>:
      - flag player awaiting_input:!
      - narrate "Input timed out"

  # World event to handle the input
  on player chats flagged:awaiting_input:
      - define input <context.message.strip_color>
      - [validate and process input]
      - flag player awaiting_input:!
      - narrate "[success/error message]"
      - determine cancelled  # MUST be last - cancels the chat message
  ```
- Use `strip_color` to remove formatting from chat messages
- Store any needed data in separate flags for access in the chat handler

#### Flag Behavior Gotchas
- World event `enabled:` field checks if flag EXISTS, not its value
- Setting `enabled: <server.has_flag[flag]>` will enable if flag has ANY value
- To properly disable: Remove flag entirely with `:!` suffix
- Never set toggle flags to false - just remove them

#### Player UUID Lookup
- Use `<server.match_offline_player[PLAYER_NAME].uuid>` to get UUID from name
- Useful in admin commands to avoid manual UUID lookup
- Works for offline players who have joined before

#### Important File Locations
- YAML data files: Place in `plugins/Denizen/` directory (not server root)
- Scripts: `plugins/Denizen/scripts/` subdirectories
- Logs: `plugins/Denizen/logs/` with daily rotation

#### Citizens2 NPC Integration
- Assignments link NPCs to interact scripts: `type: assignment`
- Interact scripts contain triggers: `type: interact`
- Structure: Assignment → interact scripts → steps → triggers
- Common triggers: proximity, click, chat
- Enable triggers: `trigger name:proximity state:true radius:5`
- Assign to NPC: `/npc assignment set assignment_name`

#### NPC Interact Script Structure
- Proximity triggers must be in interact scripts, NOT assignment actions
- Correct structure:
  ```
  assignment:
      interact scripts:
          - my_interact
  my_interact:
      type: interact
      steps:
          1:
              proximity trigger:
                  entry:
                      script:
                      - commands here
  ```

#### Cooldown Patterns
- Use expiring flags: `flag player cooldown_name expire:5m`
- Check cooldown: `<player.has_flag[cooldown_name]>`
- Show remaining time: `<player.flag_expiration[cooldown_name].from_now.formatted>`
- Common for preventing spam or limiting item distribution

#### Pagination in Menus
- Calculate indices: `start_index = (page-1) * items_per_page + 1`
- Use foreach with counter to skip/stop at right items
- Clickable "Show more" that runs same task with next page
- Pass page as definition: `run task def.page:<[next_page]>`

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
- Denizen in general doesn't recommend using the `- execute` command for commands you've made in Denizen. It should be reserved for external commands. For Denizen commands, just use `- run`