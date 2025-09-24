quantity_determination_menu:
    type: inventory
    inventory: chest
    title: How many items?
    gui: true
    definitions:
        empty: <item[gray_stained_glass_pane].with[display=<&7>]>
        back: <item[barrier].with[display=<&c>Back to Main Menu;lore=<&7>Click to go back.;flag=action:back]>
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
    - [] [] [] [] [swap_to_stacks] [] [] [] []

# TODO make return_to attach to the back item
# TODO make it set `max_quantity` to the max quantity of the item being refunded
open_quantity_determination_menu:
    type: task
    definitions: item|max_quantity|return_to
    script:
        - stop

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
                    - narrate "Going back..."
                    - inventory open d:<context.item.flag[return_to]>

                - case increment:
                    - run change_quantity def.inventory:<context.inventory> def.amount:<context.item.flag[amount]> def.direction:increment

                - case decrement:
                    - run change_quantity def.inventory:<context.inventory> def.amount:<context.item.flag[amount]> def.direction:decrement

                - case swap_to_stacks:
                    - narrate "Swapping to stack mode..."
                    # Reopen the menu with adjusted increment/decrement values
                    - run open_quantity_determination_menu def.item:<context.inventory.slot[13]> def.max_quantity:<context.inventory.flag[max_quantity]> def.return_to:<context.inventory.flag[return_to]>

                - case swap_to_items:
                    - narrate "Swapping to item mode..."
                    # Reopen the menu with adjusted increment/decrement values
                    - run open_quantity_determination_menu def.item:<context.inventory.slot[13]> def.max_quantity:<context.inventory.flag[max_quantity]> def.return_to:<context.inventory.flag[return_to]>

change_quantity:
    type: task
    definitions: inventory|amount|direction
    script:
        - define item <[inventory].slot[14]>
        - if <[direction]> == increment:
            - inventory d:<[inventory]> adjust slot:14 quantity:<[item].quantity.add[<[amount]>]>
        - else if <[direction]> == decrement:
            - inventory d:<[inventory]> adjust slot:14 quantity:<[item].quantity.sub[<[amount]>]>
        - define item <[inventory].slot[14]>
        - if <[item].quantity> > <[item].max_stack>:
            - inventory d:<[inventory]> adjust slot:14 quantity:<[item].max_stack>
        - if <[item].quantity> > <[item].flag[max_quantity]>:
            - inventory d:<[inventory]> adjust slot:14 quantity:<[item].flag[max_quantity]>