quantity_determination_menu:
    type: inventory
    inventory: chest
    title: How many items?
    gui: true
    definitions:
        empty: <item[gray_stained_glass_pane].with[display=<&7>]>
        increment: <item[green_stained_glass_pane].with[display=<&a>Increase Quantity;lore=<&7>Click to increase the quantity by 1.;flag=action:increment;flag=amount:1]>
        increment_16: <item[green_stained_glass_pane].with[display=<&a>Increase Quantity;lore=<&7>Click to increase the quantity by 16.;flag=action:increment;flag=amount:16]>
        increment_32: <item[green_stained_glass_pane].with[display=<&a>Increase Quantity;lore=<&7>Click to increase the quantity by 32.;flag=action:increment;flag=amount:32]>
        decrement: <item[red_stained_glass_pane].with[display=<&a>Decrease Quantity;lore=<&7>Click to decrease the quantity by 1.;flag=action:decrement;flag=amount:1]>
        decrement_16: <item[red_stained_glass_pane].with[display=<&a>Decrease Quantity;lore=<&7>Click to decrease the quantity by 16.;flag=action:decrement;flag=amount:16]>
        decrement_32: <item[red_stained_glass_pane].with[display=<&a>Decrease Quantity;lore=<&7>Click to decrease the quantity by 32.;flag=action:decrement;flag=amount:32]>
        invalid_item: <item[bedrock].with[display=<&c>Invalid Item;lore=<&7>Something went wrong, this item won't work.]>
    slots:
    - [] [] [] [] [] [] [] [] []
    - [decrement_32] [decrement_16] [decrement] [] [invalid_item] [] [increment] [increment_16] [increment_32]
    - [back_button] [] [] [] [swap_to_stacks] [] [] [] [refund_balance]

open_quantity_determination_menu:
    type: task
    definitions: item|unit_price|max_quantity|return_to|action
    script:
        - define inventory <inventory[quantity_determination_menu]>
        - define center_item <[item].proc[add_quantity_item_lore].context[<[unit_price]>|<[max_quantity]>]>
        - if <[action].exists>:
            - define center_item <[center_item].with_flag[action:<[action]>]>
        - inventory d:<[inventory]> set slot:14 o:<[center_item]>
        - inventory set d:<[inventory]> slot:19 o:<item[back_button].with_flag[return_to:<[return_to]>]>
        - inventory open d:<[inventory]>

add_quantity_item_lore:
    type: procedure
    definitions: item|unit_price|max_quantity|stack_mode
    script:
        - define unit_price <[item].flag[unit_price]> if:!<[unit_price].exists>
        - define max_quantity <[item].flag[max_quantity]> if:!<[max_quantity].exists>
        - define price_prefix ""
        - define price <[unit_price].mul[<[item].quantity>]>
        - if <[stack_mode].exists> && <[stack_mode].as_boolean>:
            - define price <[unit_price].mul[<[item].quantity>].mul[64]>
            - if <[price]> > <[unit_price].mul[<[max_quantity]>]>:
                - define price <[unit_price].mul[<[max_quantity]>]>
                - define price_prefix " <red>(capped at price for <[max_quantity]> items)"
        - determine <item[<[item]>].with[display_name=Click to claim this many items!].with[lore=Price (each): <&a>$<[unit_price]>|<bold>Price (total): <green>$<[price]><[price_prefix]>;flag=max_quantity:<[max_quantity]>;flag=unit_price:<[unit_price]>]>

swap_to_stacks:
    type: item
    material: dried_kelp_block
    display name: <&e>Swap to Stacks
    lore:
    - <&7>Click to switch to stack mode.
    - <&7>In stack mode, each click increases or decreases the quantity by 64.

swap_to_items:
    type: item
    material: dried_kelp
    display name: <&e>Swap to Items
    lore:
    - <&7>Click to switch to item mode.
    - <&7>In item mode, each click increases or decreases the quantity by 1.

quantity_determination_menu_handler:
    type: world
    events:
        on player clicks item in quantity_determination_menu:
            - choose <context.item.flag[action]>:
                - case back:
                    - inventory open d:<inventory[<context.item.flag[return_to]>]>

                - case increment:
                    - run change_quantity def.inventory:<context.inventory> def.amount:<context.item.flag[amount]> def.direction:increment

                - case decrement:
                    - run change_quantity def.inventory:<context.inventory> def.amount:<context.item.flag[amount]> def.direction:decrement

                - case reclaim:
                    # Get the center item (slot 14) which has the selected quantity
                    - define center_item <context.inventory.slot[14]>
                    - define selected_quantity <[center_item].quantity>

                    # Check if in stack mode and calculate actual quantity
                    - if <context.inventory.slot[23].script.name> == swap_to_items:
                        - define actual_quantity <[selected_quantity].mul[64]>
                        # Cap at max_quantity if needed
                        - define max_quantity <[center_item].flag[max_quantity]>
                        - if <[actual_quantity]> > <[max_quantity]>:
                            - define actual_quantity <[max_quantity]>
                    - else:
                        - define actual_quantity <[selected_quantity]>

                    # Create clean base item for reclaim_item task
                    - define base_item <item[<[center_item].material.name>]>

                    # Call reclaim_item task
                    - run reclaim_item def.target:<player> def.item:<[base_item]> def.quantity:<[actual_quantity]>

                    # Close the quantity menu
                    - inventory close
        on player clicks swap_to_* in quantity_determination_menu:
            - if <context.item.script.name> == swap_to_stacks:
                - inventory d:<context.inventory> set slot:23 o:<item[swap_to_items]>
                # Ensure quantity does not exceed max when switching to stacks
                - run change_quantity def.inventory:<context.inventory> def.amount:0 def.direction:decrement
            - else if <context.item.script.name> == swap_to_items:
                - inventory d:<context.inventory> set slot:23 o:<item[swap_to_stacks]>

change_quantity:
    type: task
    definitions: inventory|amount|direction
    script:
        - define item <[inventory].slot[14]>
        - if <[direction]> == increment:
            - inventory d:<[inventory]> adjust slot:14 quantity:<[item].quantity.add[<[amount]>]>
        - else if <[direction]> == decrement:
            - if <[item].quantity.sub[<[amount]>]> < 1:
                - inventory d:<[inventory]> adjust slot:14 quantity:1
            - else:
                - inventory d:<[inventory]> adjust slot:14 quantity:<[item].quantity.sub[<[amount]>]>
        - define item <[inventory].slot[14]>
        - if <[item].quantity> > <[item].max_stack>:
            - inventory d:<[inventory]> adjust slot:14 quantity:<[item].max_stack>
        - if <[inventory].slot[23].script.name> == swap_to_stacks:
            - if <[item].quantity> > <[item].flag[max_quantity]>:
                - inventory d:<[inventory]> adjust slot:14 quantity:<[item].flag[max_quantity]>
        - else if <[inventory].slot[23].script.name> == swap_to_items:
            # Add 63 to max_quantity to allow for partial stacks
            - if <[item].quantity.mul[64]> > <[item].flag[max_quantity].add[63]>:
                - define max_quantity_stacks <[item].flag[max_quantity].add[63].div_int[64]>
                - inventory d:<[inventory]> adjust slot:14 quantity:<[max_quantity_stacks]>
        # Reset the middle item's lore
        - define item <[inventory].slot[14]>
        - if <[inventory].slot[23].script.name> == swap_to_items:
            - define stack_mode true
        - inventory d:<[inventory]> set slot:14 o:<item[<[item]>].proc[add_quantity_item_lore].context[<[item].flag[unit_price]>|<[item].flag[max_quantity]>|<[stack_mode]>]>

