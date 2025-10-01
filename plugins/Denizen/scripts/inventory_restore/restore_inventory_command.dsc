# Task to process item data and return a fully configured item
process_item_data:
    type: task
    definitions: item_data|slot
    script:
    - define slot <[slot].if_null[unknown]>

    # Check for item ID
    - if !<[item_data].contains[id]>:
        - determine <item[air]>

    # Skip player heads
    - if <[item_data.id]> == player_head:
        - determine <item[air]>

    # Start building the item
    - define item_id <[item_data.id]>
    - define item <item[<[item_id]>]>

    # Check if item is valid
    - if <[item].material.name> == air:
        - determine <item[air]>

    # Add quantity
    - if <[item_data].contains[count]>:
        - define item <[item].with[quantity=<[item_data.count]>]>

    # Process components if they exist
    - if <[item_data].contains[components]>:
        - define components <[item_data.components]>

        # Custom name (display name) - handle structured format
        - if <[components].contains[custom_name]>:
            - define name_data <[components.custom_name]>
            # Check if it's a structured format (dict) or plain string
            - if <[name_data].object_type> == Map:
                # Build the display name with formatting
                - define display_text <[name_data.text].if_null[]>
                # Apply color if present
                - if <[name_data].contains[color]>:
                    - define color_code <map[black=<&0>;dark_blue=<&1>;dark_green=<&2>;dark_aqua=<&3>;dark_red=<&4>;dark_purple=<&5>;gold=<&6>;gray=<&7>;dark_gray=<&8>;blue=<&9>;green=<&a>;aqua=<&b>;red=<&c>;light_purple=<&d>;yellow=<&e>;white=<&f>].get[<[name_data.color]>].if_null[<&f>]>
                    - define display_text <[color_code]><[display_text]>
                # Apply bold if present
                - if <[name_data.bold].if_null[false]>:
                    - define display_text <&l><[display_text]>
                # Apply italic if present
                - if <[name_data.italic].if_null[false]>:
                    - define display_text <&o><[display_text]>
                - define item <[item].with[display=<[display_text]>]>
            - else:
                # Handle as plain string (legacy format)
                - define display_name <[name_data]>
                # Clean up any extra quotes if present
                - if <[display_name].starts_with["]> && <[display_name].ends_with["]>:
                    - define display_name <[display_name].substring[2,<[display_name].length.sub[1]>]>
                - define item <[item].with[display=<[display_name]>]>

        # Enchantments (handles both regular items and enchanted books)
        - if <[components].contains[enchantments]> || <[components].contains[stored_enchantments]>:
            - define enchant_list <list>
            # Check for regular enchantments first
            - if <[components].contains[enchantments]>:
                - foreach <[components.enchantments]> key:enchant as:level:
                    - define enchant_list:->:<[enchant]>,<[level]>
            # Check for stored enchantments (enchanted books)
            - if <[components].contains[stored_enchantments]>:
                - foreach <[components.stored_enchantments]> key:enchant as:level:
                    - define enchant_list:->:<[enchant]>,<[level]>
            - if <[enchant_list].size> > 0:
                - define item <[item].with[enchantments=<[enchant_list].separated_by[|]>]>

        # Armor Trim
        - if <[components].contains[trim]>:
            - if <[components.trim].contains[material]> && <[components.trim].contains[pattern]>:
                - define item <[item].with[trim=<[components.trim.material]>,<[components.trim.pattern]>]>

        # Durability/Damage
        - if <[components].contains[damage]>:
            # Damage value maps directly to durability (uses consumed)
            - define item <[item].with[durability=<[components.damage]>]>

        # Repair Cost
        - if <[components].contains[repair_cost]>:
            - define item <[item].with[repair_cost=<[components.repair_cost]>]>

        # Fireworks
        - if <[components].contains[fireworks]>:
            # Parse the NBT string to extract flight_duration
            - if <[components.fireworks].contains[flight_duration]>:
                - define power_string <[components.fireworks].after[flight_duration:].before[b].if_null[1]>
                - define power <[power_string].round_to[0].if_null[1]>
                - define item <[item].with[firework_power=<[power]>]>

        # Custom Data/NBT
        - if <[components].contains[custom_data]>:
            # Try to apply custom data - this uses the custom_data property
            - define item <[item].with[custom_data=<[components.custom_data]>]>

        # Container (for shulker boxes, bundles, etc)
        - if <[components].contains[container]>:
            - narrate "<blue>[DEBUG] Slot <[slot]>: Has CONTAINER component - will process after item creation"

        # Bundle Contents
        - if <[components].contains[bundle_contents]>:
            - narrate "<blue>[DEBUG] Slot <[slot]>: Processing bundle_contents"
            - define bundle_items <list>

            # Process each item in the bundle
            - foreach <[components.bundle_contents]> as:bundle_item_data:
                # Try to process the item
                - if <[bundle_item_data].object_type> == Map:
                    # Recursively process the bundle item
                    - run process_item_data def.item_data:<[bundle_item_data]> def.slot:bundle_item save:processed_bundle_item
                    - define processed_item <entry[processed_bundle_item].created_queue.determination.get[1].if_null[<item[air]>]>

                    # If processing failed, create placeholder
                    - if <[processed_item].material.name> == air:
                        - define placeholder_item <item[paper]>
                        - define placeholder_item <[placeholder_item].with[display=<&c>Unknown Item]>
                        - define lore_line1 "If you'd like to redeem this, please talk to an admin"
                        - define lore_line2 <[bundle_item_data].to_string.substring[1,200]>
                        - define placeholder_item <[placeholder_item].with[lore=<[lore_line1]>|<[lore_line2]>]>
                        - define bundle_items:->:<[placeholder_item]>
                    - else:
                        - define bundle_items:->:<[processed_item]>
                - else:
                    # Item data is not a map, create placeholder
                    - define placeholder_item <item[paper]>
                    - define placeholder_item <[placeholder_item].with[display=<&c>Unknown Item]>
                    - define lore_line1 "If you'd like to redeem this, please talk to an admin"
                    - define lore_line2 <[bundle_item_data].to_string.substring[1,200]>
                    - define placeholder_item <[placeholder_item].with[lore=<[lore_line1]>|<[lore_line2]>]>
                    - define bundle_items:->:<[placeholder_item]>

            # Set the bundle's inventory contents
            - if <[bundle_items].size> > 0:
                - define item <[item].with[inventory_contents=<[bundle_items]>]>
                - narrate "<green>[DEBUG] Added <[bundle_items].size> items to bundle"

    - determine <[item]>

restore_inventory_command:
    type: command
    name: restoreinventory
    description: Restore a player's inventory from a YAML file
    usage: /restoreinventory <&lt>player<&gt> <&lt>yaml_file<&gt> [inventory|enderchest]
    permission: denizen.restoreinventory
    aliases:
    - restoreinv
    - rinv
    tab completions:
        1: <server.online_players.parse[name]>
        2: <util.list_files[.].filter[ends_with[.yaml]].parse[replace[.yaml]]>
        3: inventory|enderchest
    script:
    - if <context.args.size> < 2 || <context.args.size> > 3:
        - narrate "<red>Usage: /restoreinventory <&lt>player<&gt> <&lt>yaml_file<&gt> [inventory|enderchest]"
        - stop

    - define target_player <server.match_player[<context.args.get[1]>].if_null[null]>
    - if <[target_player]> == null:
        - narrate "<red>Player '<context.args.get[1]>' not found or is not online."
        - stop

    - define yaml_file <context.args.get[2]>
    - if !<[yaml_file].ends_with[.yaml]>:
        - define yaml_file <[yaml_file]>.yaml

    # Determine target inventory (default: inventory)
    - define target_inv_type <context.args.get[3].if_null[inventory]>
    - if <[target_inv_type]> != inventory && <[target_inv_type]> != enderchest:
        - narrate "<red>Invalid target inventory type. Use 'inventory' or 'enderchest'."
        - stop

    # Check if file exists
    - if !<util.has_file[<[yaml_file]>]>:
        - narrate "<red>File '<[yaml_file]>' does not exist."
        - stop

    # Load the YAML data
    - ~yaml load:<[yaml_file]> id:inventory_restore

    # Check for appropriate contents key based on target
    - if <[target_inv_type]> == enderchest:
        - define contents_key enderChestContents
        - define target_inventory <[target_player].enderchest>
    - else:
        - define contents_key inventoryContents
        - define target_inventory <[target_player].inventory>

    - if !<yaml[inventory_restore].contains[<[contents_key]>]>:
        - narrate "<red>No <[contents_key]> found in <[yaml_file]>"
        - yaml unload id:inventory_restore
        - stop

    # Track statistics
    - define restored_items <list>
    - define skipped_items <list>
    - define overflow_items <list>
    - define failed_items <list>

    # Process each item in the inventory
    - foreach <yaml[inventory_restore].read[<[contents_key]>]> key:slot as:item_data:

        # Use the task to process item data
        - run process_item_data def.item_data:<[item_data]> def.slot:<[slot]> save:processed_item
        - define item <entry[processed_item].created_queue.determination.get[1].if_null[<item[air]>]>

        # Skip if item is air (failed or skipped)
        - if <[item].material.name> == air:
            - if <[item_data].contains[id]>:
                - if <[item_data.id]> == player_head:
                    - define skipped_items:->:slot_<[slot]>_player_head
                - else:
                    - define failed_items:->:slot_<[slot]>_<[item_data.id]>_processing_failed
            - foreach next

        # Handle container contents for shulker boxes
        - if <[item_data].contains[components]> && <[item_data.components].contains[container]>:
            - narrate "<blue>[DEBUG] Slot <[slot]>: Processing container contents for <[item].material.name>"

            # The container field now contains a properly structured map of slot->item_data
            - define container_data <[item_data.components.container]>

            # Check if container_data is a map or still a string
            - if <[container_data].object_type> == Map:
                - narrate "<blue>[DEBUG] Container has <[container_data].size> item stacks"

                # Create a list to hold the shulker box contents (27 slots for shulker box)
                - define shulker_contents <list>
                - repeat 27:
                    - define shulker_contents:->:<item[air]>

                # Process each item in the container
                - foreach <[container_data]> key:container_slot as:sub_item_data:
                    - narrate "<blue>[DEBUG] Processing container slot <[container_slot]>: <[sub_item_data.id].if_null[unknown]>"

                    # Process the sub-item using our task
                    - run process_item_data def.item_data:<[sub_item_data]> def.slot:container_<[container_slot]> save:processed_sub_item
                    - define sub_item <entry[processed_sub_item].created_queue.determination.get[1].if_null[<item[air]>]>

                    # If the item is valid, add it to the shulker box contents list
                    - if <[sub_item].material.name> != air:
                        - narrate "<blue>[DEBUG] Adding <[sub_item].material.name> x<[sub_item].quantity> to shulker slot <[container_slot].add[1]>"
                        # Shulker box slots are 1-indexed in Denizen
                        - define slot_index <[container_slot].add[1]>
                        - if <[slot_index]> <= 27:
                            - define shulker_contents[<[slot_index]>]:<[sub_item]>

                # Apply all contents to the shulker box at once
                - define item <[item].with[inventory_contents=<[shulker_contents]>]>
                - narrate "<green>[DEBUG] Finished processing container contents - applied <[container_data].size> items"
            - else:
                # Fallback for JSON string format (complex containers that couldn't be parsed)
                - narrate "<yellow>[DEBUG] Container is in string format - complex nested structure"
                - narrate "<yellow>[DEBUG] Shulker box will be given empty (contents too complex to parse)"

        # Give the item to the player or enderchest
        - if <[target_inv_type]> == enderchest:
            - give <[item]> to:<[target_inventory]> save:give_result
        - else:
            - give <[item]> player:<[target_player]> save:give_result

        # Check for overflow
        - if <entry[give_result].leftover_items.size.if_null[0]> > 0:
            - define overflow_items:->:slot_<[slot]>_<[item.material.name]>_qty_<entry[give_result].leftover_items.get[1].quantity>
        - else:
            - define restored_items:->:slot_<[slot]>_<[item.material.name]>_qty_<[item].quantity>

    # Unload YAML
    - yaml unload id:inventory_restore

    # Report results
    - narrate "<green>===== Inventory Restoration Complete ====="
    - narrate "<green>Target Player: <&e><[target_player].name>"
    - narrate "<green>Target: <&e><[target_inv_type]>"
    - narrate "<green>Items Restored: <&a><[restored_items].size>"

    - if <[skipped_items].size> > 0:
        - narrate "<yellow>Skipped Items (player_heads): <&e><[skipped_items].size>"

    - if <[overflow_items].size> > 0:
        - narrate "<yellow>Overflow Items (inventory full): <&e><[overflow_items].size>"
        - narrate "<yellow>These items were dropped at the player's location."

    - if <[failed_items].size> > 0:
        - narrate "<red>Failed Items: <&c><[failed_items].size>"
        - foreach <[failed_items]> as:failed:
            - narrate "<red>  - <[failed]>"

    - narrate "<green>======================================="

# Test command to verify specific item creation
test_restore_item_command:
    type: command
    name: testrestoreitem
    description: Test creating a single item from YAML data
    usage: /testrestoreitem
    permission: denizen.restoreinventory
    script:
    - define test_item <item[netherite_sword]>
    - define test_item <[test_item].with[display=<&l><&d>Test Sword]>
    - define test_item <[test_item].with[enchantments=sharpness,5;mending,1]>
    - give <[test_item]> to:<player>
    - narrate "<green>Gave test item with display name and enchantments"